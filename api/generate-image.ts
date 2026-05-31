import type { VercelRequest, VercelResponse } from '@vercel/node';
import { validateSubscription, recordImageGeneration, getRemainingImageGenerations } from '../lib/subscription';
import { getCachedImage, cacheImage } from '../lib/cache';
import { generateImage } from '../lib/openai';
import { createErrorResponse } from '../lib/utils';

export default async function handler(
  req: VercelRequest,
  res: VercelResponse
) {
  // Only allow POST requests
  if (req.method !== 'POST') {
    return res.status(405).json(
      createErrorResponse('Method not allowed', 'METHOD_NOT_ALLOWED')
    );
  }

  try {
    const { description, userId, style } = req.body;

    // Validate input
    if (!description || typeof description !== 'string') {
      return res.status(400).json(
        createErrorResponse('Description is required', 'INVALID_INPUT')
      );
    }

    if (description.length > 100) {
      return res.status(400).json(
        createErrorResponse(
          'Description must be 100 characters or less',
          'INVALID_INPUT'
        )
      );
    }

    if (!userId || typeof userId !== 'string') {
      return res.status(400).json(
        createErrorResponse('User ID is required', 'INVALID_INPUT')
      );
    }

    const validStyles = ['valentine', 'romantic', 'funny'];
    const imageStyle = validStyles.includes(style) ? style : 'valentine';

    // Validate subscription
    const subscription = await validateSubscription(userId);
    if (!subscription.isPremium) {
      return res.status(403).json(
        createErrorResponse('Premium subscription required', 'SUBSCRIPTION_REQUIRED')
      );
    }

    // Check usage limit
    const remaining = await getRemainingImageGenerations(userId);
    if (remaining <= 0) {
      return res.status(429).json({
        ...createErrorResponse(
          'Image generation limit reached',
          'RATE_LIMIT_EXCEEDED'
        ),
        remainingGenerations: 0,
      });
    }

    // Check cache
    const normalizedDescription = description.toLowerCase().trim();
    const cachedImageUrl = await getCachedImage(normalizedDescription, imageStyle);

    if (cachedImageUrl) {
      // Record usage (cache hit)
      await recordImageGeneration(userId);
      const updatedRemaining = await getRemainingImageGenerations(userId);

      return res.status(200).json({
        imageUrl: cachedImageUrl,
        cached: true,
        remainingGenerations: updatedRemaining,
      });
    }

    // Generate image and cache the base64 payload behind a stable URL
    const generatedImage = await generateImage(description, imageStyle);
    const imageUrl = await cacheImage(normalizedDescription, imageStyle, {
      b64: generatedImage.b64Json,
      contentType: generatedImage.contentType,
    });

    // Record usage (cache miss)
    await recordImageGeneration(userId);
    const updatedRemaining = await getRemainingImageGenerations(userId);

    return res.status(200).json({
      imageUrl,
      cached: false,
      remainingGenerations: updatedRemaining,
    });
  } catch (error) {
    console.error('Error in generate-image:', error);
    return res.status(500).json(
      createErrorResponse(
        'Internal server error',
        'INTERNAL_ERROR'
      )
    );
  }
}
