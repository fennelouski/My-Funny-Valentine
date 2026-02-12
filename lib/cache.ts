import { kv } from '@vercel/kv';
import { hashString } from './utils';

/**
 * Cache sayings response
 */
export async function cacheSayings(
  inspiration: string,
  sayings: string[]
): Promise<void> {
  const cacheKey = `sayings:${hashString(inspiration.toLowerCase().trim())}`;
  await kv.set(cacheKey, sayings, { ex: 7 * 24 * 60 * 60 }); // 7 days
}

/**
 * Get cached sayings
 */
export async function getCachedSayings(
  inspiration: string
): Promise<string[] | null> {
  const cacheKey = `sayings:${hashString(inspiration.toLowerCase().trim())}`;
  return await kv.get<string[]>(cacheKey);
}

/**
 * Cache image URL
 */
export async function cacheImage(
  description: string,
  style: string,
  imageUrl: string
): Promise<void> {
  const cacheKey = `images:${hashString(
    `${description.toLowerCase().trim()}:${style}`
  )}`;
  await kv.set(cacheKey, imageUrl, { ex: 30 * 24 * 60 * 60 }); // 30 days
}

/**
 * Get cached image URL
 */
export async function getCachedImage(
  description: string,
  style: string
): Promise<string | null> {
  const cacheKey = `images:${hashString(
    `${description.toLowerCase().trim()}:${style}`
  )}`;
  return await kv.get<string>(cacheKey);
}
