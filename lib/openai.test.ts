import { describe, expect, it, beforeEach, afterEach } from 'vitest';
import {
  buildImagePublicUrl,
  getApiBaseUrl,
  parseGeneratedImageResponse,
} from '../lib/image-host';
import { buildChatCompletionParams } from '../lib/openai-chat';
import { getImageCacheKey } from '../lib/cache';

describe('image-host', () => {
  const originalEnv = process.env;

  beforeEach(() => {
    process.env = { ...originalEnv };
  });

  afterEach(() => {
    process.env = originalEnv;
  });

  it('builds a public image URL from the API base URL', () => {
    process.env.VERCEL_URL = 'my-app.vercel.app';
    expect(buildImagePublicUrl('abc123')).toBe(
      'https://my-app.vercel.app/api/image/abc123'
    );
  });

  it('falls back to localhost when no deployment URL is configured', () => {
    delete process.env.VERCEL_URL;
    delete process.env.API_BASE_URL;
    expect(getApiBaseUrl()).toBe('http://localhost:3000');
  });

  it('parses base64 image responses from GPT Image models', () => {
    const result = parseGeneratedImageResponse([
      { b64_json: 'aGVsbG8=', url: null },
    ]);

    expect(result).toEqual({
      b64Json: 'aGVsbG8=',
      contentType: 'image/jpeg',
    });
  });

  it('throws when GPT Image models return no image data', () => {
    expect(() => parseGeneratedImageResponse([{ url: 'https://example.com' }])).toThrow(
      'No image data returned from OpenAI'
    );
  });
});

describe('openai chat params', () => {
  it('uses max_completion_tokens for GPT-5 models', () => {
    const params = buildChatCompletionParams(
      'gpt-5-nano',
      [{ role: 'user', content: 'Hello' }],
      500
    );

    expect(params.max_completion_tokens).toBe(500);
    expect(params.max_tokens).toBeUndefined();
    expect(params.temperature).toBeUndefined();
  });

  it('uses max_tokens for legacy models', () => {
    const params = buildChatCompletionParams(
      'gpt-4o-mini',
      [{ role: 'user', content: 'Hello' }],
      500
    );

    expect(params.max_tokens).toBe(500);
    expect(params.max_completion_tokens).toBeUndefined();
    expect(params.temperature).toBe(0.8);
  });
});

describe('image cache keys', () => {
  it('normalizes description casing and whitespace', () => {
    expect(getImageCacheKey('  Roses  ', 'valentine')).toBe(
      getImageCacheKey('roses', 'valentine')
    );
  });

  it('includes style in the cache key', () => {
    expect(getImageCacheKey('roses', 'valentine')).not.toBe(
      getImageCacheKey('roses', 'romantic')
    );
  });
});
