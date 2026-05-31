import type { VercelRequest, VercelResponse } from '@vercel/node';
import { getCachedImageData } from '../../lib/cache';
import { createErrorResponse } from '../../lib/utils';

export default async function handler(
  req: VercelRequest,
  res: VercelResponse
) {
  if (req.method !== 'GET') {
    return res.status(405).json(
      createErrorResponse('Method not allowed', 'METHOD_NOT_ALLOWED')
    );
  }

  const cacheKey = req.query.key;
  if (!cacheKey || typeof cacheKey !== 'string' || !/^[a-f0-9]{64}$/.test(cacheKey)) {
    return res.status(400).json(
      createErrorResponse('Invalid image key', 'INVALID_INPUT')
    );
  }

  try {
    const cached = await getCachedImageData(cacheKey);
    if (!cached) {
      return res.status(404).json(
        createErrorResponse('Image not found', 'NOT_FOUND')
      );
    }

    const imageBuffer = Buffer.from(cached.b64, 'base64');
    res.setHeader('Content-Type', cached.contentType);
    res.setHeader('Cache-Control', 'public, max-age=2592000, immutable');
    return res.status(200).send(imageBuffer);
  } catch (error) {
    console.error('Error serving cached image:', error);
    return res.status(500).json(
      createErrorResponse('Internal server error', 'INTERNAL_ERROR')
    );
  }
}
