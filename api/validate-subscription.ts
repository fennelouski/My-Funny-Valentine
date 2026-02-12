import type { VercelRequest, VercelResponse } from '@vercel/node';
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
    const { userId, receipt } = req.body;

    // Validate input
    if (!userId || typeof userId !== 'string') {
      return res.status(400).json(
        createErrorResponse('User ID is required', 'INVALID_INPUT')
      );
    }

    // Validate subscription status
    const subscriptionInfo = await validateSubscription(userId, receipt);

    return res.status(200).json({
      isPremium: subscriptionInfo.isPremium,
      expiresAt: subscriptionInfo.expiresAt,
      remainingAIRequests: subscriptionInfo.remainingAIRequests,
      remainingImageGenerations: subscriptionInfo.remainingImageGenerations,
    });
  } catch (error) {
    console.error('Error in validate-subscription:', error);
    return res.status(500).json(
      createErrorResponse('Internal server error', 'INTERNAL_ERROR')
    );
  }
}
