import { kv } from '@vercel/kv';
import { getPeriodKey, getTTL } from './utils';

export interface RateLimitResult {
  allowed: boolean;
  remaining: number;
  limit: number;
  resetAt: number;
}

/**
 * Check if user can make a request based on rate limits
 */
export async function checkRateLimit(
  userId: string,
  isPremium: boolean
): Promise<RateLimitResult> {
  const limit = isPremium ? 20 : 3;
  const period: 'day' | 'month' = isPremium ? 'month' : 'day';
  const periodKey = getPeriodKey(period);
  const key = `rate_limit:${userId}:${periodKey}`;

  const count = (await kv.get<number>(key)) || 0;
  const ttl = await kv.ttl(key);
  const resetAt = Date.now() + (ttl > 0 ? ttl * 1000 : getTTL(period) * 1000);

  return {
    allowed: count < limit,
    remaining: Math.max(0, limit - count),
    limit,
    resetAt,
  };
}

/**
 * Record a usage for rate limiting
 */
export async function recordUsage(
  userId: string,
  isPremium: boolean
): Promise<void> {
  const period: 'day' | 'month' = isPremium ? 'month' : 'day';
  const periodKey = getPeriodKey(period);
  const key = `rate_limit:${userId}:${periodKey}`;
  const ttl = getTTL(period);

  await kv.incr(key);
  await kv.expire(key, ttl);
}

/**
 * Get remaining requests for a user
 */
export async function getRemainingRequests(
  userId: string,
  isPremium: boolean
): Promise<number> {
  const result = await checkRateLimit(userId, isPremium);
  return result.remaining;
}
