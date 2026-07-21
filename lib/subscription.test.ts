import { describe, expect, it, beforeEach, vi } from 'vitest';

// In-memory stand-in for Vercel KV
const store = new Map<string, unknown>();

vi.mock('@vercel/kv', () => ({
  kv: {
    get: vi.fn(async (key: string) => (store.has(key) ? store.get(key) : null)),
    set: vi.fn(async (key: string, value: unknown) => {
      store.set(key, value);
      return 'OK';
    }),
    incr: vi.fn(async (key: string) => {
      const next = ((store.get(key) as number) || 0) + 1;
      store.set(key, next);
      return next;
    }),
    expire: vi.fn(async () => 1),
    ttl: vi.fn(async () => -1),
  },
}));

const verifySignedTransaction = vi.fn();
vi.mock('./app-store', () => ({
  verifySignedTransaction: (...args: unknown[]) => verifySignedTransaction(...args),
  PREMIUM_PRODUCT_ID: 'com.nathanfennel.My-Funny-Valentine.premium',
}));

import {
  validateSubscription,
  redeemSignedTransaction,
  DAILY_IMAGE_LIMIT,
} from './subscription';

const USER = 'user-123';

function activeSubscription(overrides: Record<string, unknown> = {}) {
  return {
    originalTransactionId: 'txn-1',
    productId: 'com.nathanfennel.My-Funny-Valentine.premium',
    expiresAt: Date.now() + 30 * 24 * 60 * 60 * 1000,
    isActive: true,
    environment: 'Sandbox' as const,
    ...overrides,
  };
}

describe('subscription entitlement', () => {
  beforeEach(() => {
    store.clear();
    verifySignedTransaction.mockReset();
  });

  it('treats an unknown user as free', async () => {
    const info = await validateSubscription(USER);

    expect(info.isPremium).toBe(false);
  });

  it('offers image generation to users with no subscription', async () => {
    // Artwork is no longer paywalled — everyone gets the same daily cap.
    const info = await validateSubscription(USER);

    expect(info.isPremium).toBe(false);
    expect(info.remainingImageGenerations).toBe(DAILY_IMAGE_LIMIT);
  });

  it('grants premium after a transaction verifies', async () => {
    verifySignedTransaction.mockResolvedValue(activeSubscription());

    const verified = await redeemSignedTransaction(USER, 'signed-jws');
    expect(verified).not.toBeNull();

    const info = await validateSubscription(USER);
    expect(info.isPremium).toBe(true);
    // Premium no longer changes the image cap; it is the same for everyone.
    expect(info.remainingImageGenerations).toBe(DAILY_IMAGE_LIMIT);
  });

  it('does not grant premium when verification fails', async () => {
    verifySignedTransaction.mockResolvedValue(null);

    const verified = await redeemSignedTransaction(USER, 'forged-jws');
    expect(verified).toBeNull();

    const info = await validateSubscription(USER);
    expect(info.isPremium).toBe(false);
  });

  it('does not grant premium for an expired transaction', async () => {
    verifySignedTransaction.mockResolvedValue(
      activeSubscription({ isActive: false, expiresAt: Date.now() - 1000 })
    );

    await redeemSignedTransaction(USER, 'expired-jws');

    const info = await validateSubscription(USER);
    expect(info.isPremium).toBe(false);
  });

  it('expires premium once the stored expiry passes', async () => {
    verifySignedTransaction.mockResolvedValue(
      activeSubscription({ expiresAt: Date.now() + 50 })
    );
    await redeemSignedTransaction(USER, 'soon-to-expire');

    expect((await validateSubscription(USER)).isPremium).toBe(true);

    await new Promise((resolve) => setTimeout(resolve, 60));

    expect((await validateSubscription(USER)).isPremium).toBe(false);
  });

  it('verifies the transaction when passed through validateSubscription', async () => {
    verifySignedTransaction.mockResolvedValue(activeSubscription());

    const info = await validateSubscription(USER, 'signed-jws');

    expect(verifySignedTransaction).toHaveBeenCalledWith('signed-jws');
    expect(info.isPremium).toBe(true);
  });

  it('never grants premium from an unverified userId alone', async () => {
    // The historic bug: nothing wrote the subscription key, and nothing else
    // should be able to. Simulate an attacker calling with only a userId.
    const info = await validateSubscription('attacker-supplied-id');

    expect(info.isPremium).toBe(false);
    expect(verifySignedTransaction).not.toHaveBeenCalled();
  });
});
