/**
 * Build the public URL for a cached generated image.
 */
export function buildImagePublicUrl(cacheKey: string): string {
  const baseUrl = getApiBaseUrl();
  return `${baseUrl}/api/image/${cacheKey}`;
}

export function getApiBaseUrl(): string {
  if (process.env.VERCEL_URL) {
    return `https://${process.env.VERCEL_URL}`;
  }

  if (process.env.API_BASE_URL) {
    return process.env.API_BASE_URL.replace(/\/$/, '');
  }

  return 'http://localhost:3000';
}

export interface GeneratedImageData {
  b64Json: string;
  contentType: string;
}

export const IMAGE_CONTENT_TYPES = {
  png: 'image/png',
  jpeg: 'image/jpeg',
  webp: 'image/webp',
} as const;

export type ImageOutputFormat = keyof typeof IMAGE_CONTENT_TYPES;

/**
 * Parse the base64 image payload returned by GPT Image models.
 */
export function parseGeneratedImageResponse(
  data: Array<{ b64_json?: string | null; url?: string | null }> | undefined,
  outputFormat: ImageOutputFormat = 'jpeg'
): GeneratedImageData {
  const b64Json = data?.[0]?.b64_json;
  if (!b64Json) {
    throw new Error('No image data returned from OpenAI');
  }

  return {
    b64Json,
    contentType: IMAGE_CONTENT_TYPES[outputFormat],
  };
}
