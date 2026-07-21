import { kv } from '@vercel/kv';
import { verifySignedTransaction, VerifiedSubscription } from './app-store';

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
