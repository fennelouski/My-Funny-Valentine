import crypto from 'crypto';

/**
 * Hash a string using SHA-256
 */
export function hashString(input: string): string {
  return crypto.createHash('sha256').update(input).digest('hex');
}

/**
 * Get period key for rate limiting
 * Returns 'YYYY-MM-DD' for daily or 'YYYY-MM' for monthly
 */
export function getPeriodKey(period: 'day' | 'month' = 'day'): string {
  const now = new Date();
  if (period === 'month') {
    return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
  }
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
}

/**
 * Get TTL in seconds for rate limiting
 */
export function getTTL(period: 'day' | 'month' = 'day'): number {
  if (period === 'month') {
    // Set TTL to end of current month + 1 day buffer
    const now = new Date();
    const nextMonth = new Date(now.getFullYear(), now.getMonth() + 1, 1);
    return Math.floor((nextMonth.getTime() - now.getTime()) / 1000) + 86400; // +1 day buffer
  }
  // Daily: TTL until end of day + 1 hour buffer
  const now = new Date();
  const tomorrow = new Date(now);
  tomorrow.setDate(tomorrow.getDate() + 1);
  tomorrow.setHours(0, 0, 0, 0);
  return Math.floor((tomorrow.getTime() - now.getTime()) / 1000) + 3600; // +1 hour buffer
}

/**
 * Standard error response format
 */
export interface ErrorResponse {
  error: string;
  code?: string;
  retryAfter?: number;
}

/**
 * Create standardized error response
 */
export function createErrorResponse(
  error: string,
  code?: string,
  retryAfter?: number
): ErrorResponse {
  return {
    error,
    ...(code && { code }),
    ...(retryAfter && { retryAfter }),
  };
}
