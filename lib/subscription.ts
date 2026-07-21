import { kv } from '@vercel/kv';
import { verifySignedTransaction, VerifiedSubscription } from './app-store';
import { getPeriodKey, getTTL } from './utils';

/**
 * Daily cap on backend image generations, per install.
 *
 * The app generates artwork on device via Image Playground wherever Apple
 * Intelligence is available; this backend path only serves devices that can't,
 * so the cap exists to bound OpenAI spend rather than to upsell.
 */
export const DAILY_IMAGE_LIMIT = 3;

function imageUsageKey(userId: string): string {
  return `image_usage:${userId}:${getPeriodKey('day')}`;
}

export interface SubscriptionInfo {
  isPremium: boolean;
  expiresAt: number | null;
  remainingAIRequests: number;
  remainingImageGenerations: number;
}

export interface StoredSubscription {
  isPremium: boolean;
  expiresAt: number | null;
  originalTransactionId?: string;
  environment?: string;
  verifiedAt?: number;
}

function subscriptionKey(userId: string): string {
  return `subscription:${userId}`;
}

/**
 * Verify a StoreKit 2 signed transaction and persist the resulting entitlement.
 *
 * This is the only path that grants premium — nothing else writes the
 * subscription key, so an unverified client cannot promote itself.
 */
export async function redeemSignedTransaction(
  userId: string,
  signedTransaction: string
): Promise<VerifiedSubscription | null> {
  const verified = await verifySignedTransaction(signedTransaction);
  if (!verified) {
    return null;
  }

  const stored: StoredSubscription = {
    isPremium: verified.isActive,
    expiresAt: verified.expiresAt,
    originalTransactionId: verified.originalTransactionId,
    environment: verified.environment,
    verifiedAt: Date.now(),
  };

  // Keep the record a little past expiry so renewals and grace periods can be
  // reconciled; a non-expiring entitlement is kept for a year.
  const ttlSeconds = verified.expiresAt
    ? Math.max(60, Math.ceil((verified.expiresAt - Date.now()) / 1000) + 7 * 24 * 60 * 60)
    : 365 * 24 * 60 * 60;

  await kv.set(subscriptionKey(userId), stored, { ex: ttlSeconds });

  return verified;
}

/**
 * Read the stored subscription state for a user.
 *
 * Premium is only ever granted by `redeemSignedTransaction`, which requires a
 * transaction signed by Apple. Passing a `signedTransaction` here refreshes
 * that state first.
 */
export async function validateSubscription(
  userId: string,
  signedTransaction?: string
): Promise<SubscriptionInfo> {
  if (signedTransaction) {
    await redeemSignedTransaction(userId, signedTransaction);
  }

  // Check subscription status in KV
  const subscription = await kv.get<StoredSubscription>(subscriptionKey(userId));

  const isPremium = subscription?.isPremium || false;
  const expiresAt = subscription?.expiresAt ?? null;

  // Check if subscription is still valid
  const isValid = isPremium && (expiresAt === null || expiresAt > Date.now());

  // Get usage for remaining requests
  const { getRemainingRequests } = await import('./rate-limit');
  const remainingAIRequests = isValid
    ? await getRemainingRequests(userId, true)
    : await getRemainingRequests(userId, false);

  // Image generation is available to everyone, capped daily.
  const imageCount = (await kv.get<number>(imageUsageKey(userId))) || 0;
  const remainingImageGenerations = Math.max(0, DAILY_IMAGE_LIMIT - imageCount);

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
  const key = imageUsageKey(userId);
  await kv.incr(key);
  await kv.expire(key, getTTL('day'));
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
