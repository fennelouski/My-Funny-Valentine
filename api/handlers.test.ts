import { describe, expect, it, beforeEach, vi } from 'vitest';
import type { VercelRequest, VercelResponse } from '@vercel/node';

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
vi.mock('../lib/app-store', () => ({
  verifySignedTransaction: (...args: unknown[]) => verifySignedTransaction(...args),
  PREMIUM_PRODUCT_ID: 'com.nathanfennel.My-Funny-Valentine.premium',
}));

const generateSayings = vi.fn();
const generateImage = vi.fn();
vi.mock('../lib/openai', () => ({
  generateSayings: (...args: unknown[]) => generateSayings(...args),
  generateImage: (...args: unknown[]) => generateImage(...args),
}));

import sayingsHandler from './generate-sayings';
import imageHandler from './generate-image';
import { redeemSignedTransaction } from '../lib/subscription';

interface Captured {
  status: number;
  body: any;
}

function makeReqRes(body: unknown, method = 'POST') {
  const captured: Captured = { status: 0, body: undefined };

  const req = { method, body } as VercelRequest;
  const res = {
    status(code: number) {
      captured.status = code;
      return this;
    },
    json(payload: unknown) {
      captured.body = payload;
      return this;
    },
    send(payload: unknown) {
      captured.body = payload;
      return this;
    },
    setHeader() {
      return this;
    },
  } as unknown as VercelResponse;

  return { req, res, captured };
}

async function grantPremium(userId: string) {
  verifySignedTransaction.mockResolvedValue({
    originalTransactionId: 'txn-1',
    productId: 'com.nathanfennel.My-Funny-Valentine.premium',
    expiresAt: Date.now() + 30 * 24 * 60 * 60 * 1000,
    isActive: true,
    environment: 'Sandbox',
  });
  await redeemSignedTransaction(userId, 'signed-jws');
}

describe('POST /api/generate-sayings', () => {
  beforeEach(() => {
    store.clear();
    generateSayings.mockReset();
    verifySignedTransaction.mockReset();
  });

  it('rejects non-POST', async () => {
    const { req, res, captured } = makeReqRes({}, 'GET');
    await sayingsHandler(req, res);
    expect(captured.status).toBe(405);
  });

  it('rejects a missing inspiration', async () => {
    const { req, res, captured } = makeReqRes({ userId: 'u1' });
    await sayingsHandler(req, res);
    expect(captured.status).toBe(400);
  });

  it('rejects an over-long inspiration', async () => {
    const { req, res, captured } = makeReqRes({
      inspiration: 'a'.repeat(51),
      userId: 'u1',
    });
    await sayingsHandler(req, res);
    expect(captured.status).toBe(400);
  });

  it('returns generated sayings', async () => {
    generateSayings.mockResolvedValue(['one', 'two']);

    const { req, res, captured } = makeReqRes({ inspiration: 'coffee', userId: 'u1' });
    await sayingsHandler(req, res);

    expect(captured.status).toBe(200);
    expect(captured.body.sayings).toEqual(['one', 'two']);
    expect(captured.body.cached).toBe(false);
  });

  it('serves the second identical request from cache', async () => {
    generateSayings.mockResolvedValue(['one', 'two']);

    const first = makeReqRes({ inspiration: 'coffee', userId: 'u1' });
    await sayingsHandler(first.req, first.res);

    const second = makeReqRes({ inspiration: 'coffee', userId: 'u1' });
    await sayingsHandler(second.req, second.res);

    expect(second.captured.body.cached).toBe(true);
    expect(generateSayings).toHaveBeenCalledTimes(1);
  });

  it('enforces the free-tier daily limit', async () => {
    generateSayings.mockResolvedValue(['x']);

    for (let i = 0; i < 3; i++) {
      const r = makeReqRes({ inspiration: `word-${i}`, userId: 'u1' });
      await sayingsHandler(r.req, r.res);
      expect(r.captured.status).toBe(200);
    }

    const blocked = makeReqRes({ inspiration: 'word-4', userId: 'u1' });
    await sayingsHandler(blocked.req, blocked.res);

    expect(blocked.captured.status).toBe(429);
    expect(blocked.captured.body.remainingRequests).toBe(0);
  });
});

describe('POST /api/generate-image', () => {
  beforeEach(() => {
    store.clear();
    generateImage.mockReset();
    verifySignedTransaction.mockReset();
  });

  it('refuses a free user', async () => {
    const { req, res, captured } = makeReqRes({
      description: 'two cats',
      userId: 'free-user',
    });
    await imageHandler(req, res);

    expect(captured.status).toBe(403);
    expect(generateImage).not.toHaveBeenCalled();
  });

  it('serves a verified premium user', async () => {
    await grantPremium('premium-user');
    generateImage.mockResolvedValue({ b64Json: 'AAAA', contentType: 'image/jpeg' });

    const { req, res, captured } = makeReqRes({
      description: 'two cats',
      userId: 'premium-user',
    });
    await imageHandler(req, res);

    expect(captured.status).toBe(200);
    expect(captured.body.imageUrl).toContain('/api/image/');
    expect(generateImage).toHaveBeenCalledTimes(1);
  });

  it('enforces the monthly image limit', async () => {
    await grantPremium('premium-user');
    generateImage.mockResolvedValue({ b64Json: 'AAAA', contentType: 'image/jpeg' });

    for (let i = 0; i < 10; i++) {
      const r = makeReqRes({ description: `scene ${i}`, userId: 'premium-user' });
      await imageHandler(r.req, r.res);
      expect(r.captured.status).toBe(200);
    }

    const blocked = makeReqRes({ description: 'scene 11', userId: 'premium-user' });
    await imageHandler(blocked.req, blocked.res);

    expect(blocked.captured.status).toBe(429);
  });

  it('rejects an over-long description', async () => {
    const { req, res, captured } = makeReqRes({
      description: 'a'.repeat(101),
      userId: 'premium-user',
    });
    await imageHandler(req, res);
    expect(captured.status).toBe(400);
  });
});
