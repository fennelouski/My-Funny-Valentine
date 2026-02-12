import type { VercelRequest, VercelResponse } from '@vercel/node';
import { checkRateLimit, recordUsage } from '../lib/rate-limit';
import { getCachedSayings, cacheSayings } from '../lib/cache';
import { generateSayings } from '../lib/openai';
import { validateSubscription } from '../lib/subscription';
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
    const { inspiration, userId } = req.body;

    // Validate input
    if (!inspiration || typeof inspiration !== 'string') {
      return res.status(400).json(
        createErrorResponse('Inspiration is required', 'INVALID_INPUT')
      );
    }

    if (inspiration.length > 50) {
      return res.status(400).json(
        createErrorResponse(
          'Inspiration must be 50 characters or less',
          'INVALID_INPUT'
        )
      );
    }

    if (!userId || typeof userId !== 'string') {
      return res.status(400).json(
        createErrorResponse('User ID is required', 'INVALID_INPUT')
      );
    }

    // Validate subscription and check rate limit
    const subscription = await validateSubscription(userId);
    const rateLimit = await checkRateLimit(userId, subscription.isPremium);

    if (!rateLimit.allowed) {
      return res.status(429).json({
        ...createErrorResponse(
          'Rate limit exceeded',
          'RATE_LIMIT_EXCEEDED',
          Math.floor((rateLimit.resetAt - Date.now()) / 1000)
        ),
        remainingRequests: 0,
        resetAt: rateLimit.resetAt,
      });
    }

    // Check cache
    const normalizedInspiration = inspiration.toLowerCase().trim();
    const cachedSayings = await getCachedSayings(normalizedInspiration);

    if (cachedSayings) {
      // Record usage (cache hit)
      await recordUsage(userId, subscription.isPremium);
      const updatedRateLimit = await checkRateLimit(
        userId,
        subscription.isPremium
      );

      return res.status(200).json({
        sayings: cachedSayings,
        cached: true,
        timestamp: Date.now(),
        remainingRequests: updatedRateLimit.remaining,
        resetAt: updatedRateLimit.resetAt,
      });
    }

    // Generate sayings
    const sayings = await generateSayings(inspiration);

    // Cache result
    await cacheSayings(normalizedInspiration, sayings);

    // Record usage (cache miss)
    await recordUsage(userId, subscription.isPremium);
    const updatedRateLimit = await checkRateLimit(
      userId,
      subscription.isPremium
    );

    return res.status(200).json({
      sayings,
      cached: false,
      timestamp: Date.now(),
      remainingRequests: updatedRateLimit.remaining,
      resetAt: updatedRateLimit.resetAt,
    });
  } catch (error) {
    console.error('Error in generate-sayings:', error);
    return res.status(500).json(
      createErrorResponse(
        'Internal server error',
        'INTERNAL_ERROR'
      )
    );
  }
}
