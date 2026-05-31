import { kv } from '@vercel/kv';
import { hashString } from './utils';
import { buildImagePublicUrl } from './image-host';

const IMAGE_CACHE_TTL_SECONDS = 30 * 24 * 60 * 60;

export interface CachedImageData {
  b64: string;
  contentType: string;
}

function imageDataKey(cacheKey: string): string {
  return `image-data:${cacheKey}`;
}

export function getImageCacheKey(description: string, style: string): string {
  return hashString(`${description.toLowerCase().trim()}:${style}`);
}

/**
 * Cache sayings response
 */
export async function cacheSayings(
  inspiration: string,
  sayings: string[]
): Promise<void> {
  const cacheKey = `sayings:${hashString(inspiration.toLowerCase().trim())}`;
  await kv.set(cacheKey, sayings, { ex: 7 * 24 * 60 * 60 });
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
 * Cache generated image bytes and return a stable public URL.
 */
export async function cacheImage(
  description: string,
  style: string,
  imageData: CachedImageData
): Promise<string> {
  const cacheKey = getImageCacheKey(description, style);
  await kv.set(imageDataKey(cacheKey), imageData, {
    ex: IMAGE_CACHE_TTL_SECONDS,
  });
  return buildImagePublicUrl(cacheKey);
}

/**
 * Get cached image public URL if image data exists.
 */
export async function getCachedImage(
  description: string,
  style: string
): Promise<string | null> {
  const cacheKey = getImageCacheKey(description, style);
  const cached = await kv.get<CachedImageData>(imageDataKey(cacheKey));
  if (!cached) {
    return null;
  }

  return buildImagePublicUrl(cacheKey);
}

/**
 * Load cached image bytes for serving via the image endpoint.
 */
export async function getCachedImageData(
  cacheKey: string
): Promise<CachedImageData | null> {
  return kv.get<CachedImageData>(imageDataKey(cacheKey));
}
