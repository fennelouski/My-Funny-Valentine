import { kv } from '@vercel/kv';

export interface SubscriptionInfo {
  isPremium: boolean;
  expiresAt: number | null;
  remainingAIRequests: number;
  remainingImageGenerations: number;
}

/**
 * Validate subscription status for a user
 * In a real implementation, this would validate App Store receipts
 * For now, we'll use a simple KV-based storage
 */
export async function validateSubscription(
  userId: string,
  receipt?: string
): Promise<SubscriptionInfo> {
  // Check subscription status in KV
  const subscriptionKey = `subscription:${userId}`;
  const subscription = await kv.get<{
    isPremium: boolean;
    expiresAt: number | null;
  }>(subscriptionKey);

  const isPremium = subscription?.isPremium || false;
  const expiresAt = subscription?.expiresAt || null;

  // Check if subscription is still valid
  const isValid = isPremium && (expiresAt === null || expiresAt > Date.now());

  // Get usage for remaining requests
  const { getRemainingRequests } = await import('./rate-limit');
  const remainingAIRequests = isValid
    ? await getRemainingRequests(userId, true)
    : await getRemainingRequests(userId, false);

  // Get remaining image generations
  const imageUsageKey = `image_usage:${userId}:${new Date().getFullYear()}-${String(new Date().getMonth() + 1).padStart(2, '0')}`;
  const imageCount = (await kv.get<number>(imageUsageKey)) || 0;
  const remainingImageGenerations = isValid ? Math.max(0, 10 - imageCount) : 0;

  return {
    isPremium: isValid,
    expiresAt,
    remainingAIRequests,
    remainingImageGenerations,
  };
}

/**
 * Record image generation usage
 */
export async function recordImageGeneration(userId: string): Promise<void> {
  const periodKey = `${new Date().getFullYear()}-${String(new Date().getMonth() + 1).padStart(2, '0')}`;
  const key = `image_usage:${userId}:${periodKey}`;
  const ttl = await import('./utils').then((m) => m.getTTL('month'));

  await kv.incr(key);
  await kv.expire(key, ttl);
}

/**
 * Get remaining image generations
 */
export async function getRemainingImageGenerations(
  userId: string
): Promise<number> {
  const info = await validateSubscription(userId);
  return info.remainingImageGenerations;
}
