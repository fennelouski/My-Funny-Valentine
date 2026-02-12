# Backend Architecture

## Overview

The backend is deployed on Vercel using serverless functions, providing API endpoints for AI generation, subscription validation, and usage tracking. The architecture is designed for cost optimization and scalability.

## Architecture Overview

### Components
- **Vercel Serverless Functions**: API endpoints
- **Vercel KV**: Caching layer (Redis-compatible)
- **OpenAI API**: AI generation
- **Environment Variables**: Configuration and secrets

### Deployment
- **Platform**: Vercel
- **Runtime**: Node.js 18+
- **Region**: Auto (or specific region for latency)
- **Scaling**: Automatic (serverless)

## API Endpoints

### 1. Generate Sayings Endpoint

**Endpoint**: `POST /api/generate-sayings`

**Purpose**: Generate 10 Valentine's sayings based on user inspiration.

**Request**:
```typescript
{
  "inspiration": string, // max 50 characters
  "userId": string // for rate limiting
}
```

**Response**:
```typescript
{
  "sayings": string[], // 10 sayings
  "cached": boolean,
  "timestamp": number,
  "remainingRequests": number
}
```

**Implementation**:
```typescript
// api/generate-sayings.ts
import { kv } from '@vercel/kv';
import OpenAI from 'openai';

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { inspiration, userId } = req.body;

  // Validate input
  if (!inspiration || inspiration.length > 50) {
    return res.status(400).json({ error: 'Invalid inspiration' });
  }

  // Check rate limit
  const canMakeRequest = await checkRateLimit(userId);
  if (!canMakeRequest) {
    return res.status(429).json({ error: 'Rate limit exceeded' });
  }

  // Check cache
  const cacheKey = `sayings:${hash(inspiration.toLowerCase().trim())}`;
  const cached = await kv.get(cacheKey);
  
  if (cached) {
    await recordUsage(userId, 'ai_request', true);
    return res.json({
      sayings: cached,
      cached: true,
      timestamp: Date.now(),
      remainingRequests: await getRemainingRequests(userId)
    });
  }

  // Generate sayings
  const sayings = await generateSayings(inspiration);
  
  // Cache result
  await kv.set(cacheKey, sayings, { ex: 7 * 24 * 60 * 60 }); // 7 days
  
  // Record usage
  await recordUsage(userId, 'ai_request', false);

  return res.json({
    sayings,
    cached: false,
    timestamp: Date.now(),
    remainingRequests: await getRemainingRequests(userId)
  });
}
```

### 2. Generate Image Endpoint

**Endpoint**: `POST /api/generate-image`

**Purpose**: Generate custom images for paid subscribers.

**Request**:
```typescript
{
  "description": string, // max 100 characters
  "userId": string,
  "style": "valentine" | "romantic" | "funny"
}
```

**Response**:
```typescript
{
  "imageUrl": string,
  "cached": boolean,
  "remainingGenerations": number
}
```

**Implementation**:
```typescript
// api/generate-image.ts
export default async function handler(req, res) {
  // Validate subscription
  const isPremium = await validateSubscription(req.body.userId);
  if (!isPremium) {
    return res.status(403).json({ error: 'Premium subscription required' });
  }

  // Check usage limit
  const remaining = await getRemainingImageGenerations(req.body.userId);
  if (remaining <= 0) {
    return res.status(429).json({ error: 'Image generation limit reached' });
  }

  // Generate image (similar to sayings endpoint)
  // ...
}
```

### 3. Validate Subscription Endpoint

**Endpoint**: `POST /api/validate-subscription`

**Purpose**: Validate user's subscription status.

**Request**:
```typescript
{
  "userId": string,
  "receipt": string // App Store receipt (optional for server-side validation)
}
```

**Response**:
```typescript
{
  "isPremium": boolean,
  "expiresAt": number | null,
  "remainingAIRequests": number,
  "remainingImageGenerations": number
}
```

## Caching Layer

### Vercel KV

**Purpose**: Cache AI responses to reduce API costs and improve performance.

**Configuration**:
- **Storage**: 256MB (free tier)
- **Region**: Same as Vercel deployment
- **TTL**: 7 days for sayings, 30 days for images

**Cache Keys**:
- Sayings: `sayings:${hash(inspiration)}`
- Images: `images:${hash(description)}`
- Usage: `usage:${userId}:${date}`
- Rate limits: `rate_limit:${userId}:${date}`

**Implementation**:
```typescript
import { kv } from '@vercel/kv';

// Get from cache
const cached = await kv.get(`sayings:${hash}`);

// Set cache
await kv.set(`sayings:${hash}`, sayings, { ex: 7 * 24 * 60 * 60 });
```

## Rate Limiting

### Strategy
- **Free tier**: 3 requests per day
- **Paid tier**: 20 requests per month
- Track in Vercel KV with TTL

### Implementation
```typescript
async function checkRateLimit(userId: string): Promise<boolean> {
  const isPremium = await validateSubscription(userId);
  const limit = isPremium ? 20 : 3;
  const period = isPremium ? 'month' : 'day';
  
  const key = `rate_limit:${userId}:${getPeriodKey(period)}`;
  const count = await kv.get(key) || 0;
  
  return count < limit;
}

async function recordUsage(userId: string) {
  const key = `rate_limit:${userId}:${getPeriodKey()}`;
  await kv.incr(key);
  await kv.expire(key, getTTL());
}
```

## Cost Optimization

### Strategies
1. **Aggressive caching**: Cache all AI responses
2. **Cheap models**: Use GPT-OSS-20b ($0.03/1M tokens)
3. **Batch generation**: Generate 10 sayings per request
4. **Prompt optimization**: Minimize token usage
5. **Rate limiting**: Prevent abuse

### Cost Monitoring
- Track API calls per day
- Monitor cache hit rate
- Calculate cost per request
- Set up alerts for high usage

### Estimated Costs
- **API calls**: ~$0.00003 per request (with GPT-OSS-20b)
- **Caching**: Free (Vercel KV free tier)
- **Hosting**: Free (Vercel free tier)
- **Total**: <$10/month for 1000 unique requests

## Environment Variables

### Required Variables
```bash
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-oss-20b
KV_REST_API_URL=https://...
KV_REST_API_TOKEN=...
```

### Optional Variables
```bash
NODE_ENV=production
LOG_LEVEL=info
RATE_LIMIT_ENABLED=true
```

## Error Handling

### Error Types
- **400**: Bad request (invalid input)
- **401**: Unauthorized (missing/invalid auth)
- **403**: Forbidden (subscription required)
- **429**: Rate limit exceeded
- **500**: Server error (OpenAI error, etc.)

### Error Responses
```typescript
{
  "error": string,
  "code": string,
  "retryAfter": number // for rate limits
}
```

### Retry Logic
- Transient errors: Retry with exponential backoff
- Rate limits: Respect retry-after header
- OpenAI errors: Log and return generic error

## Security

### Authentication
- User ID validation (from app)
- Receipt validation (for subscriptions)
- Rate limiting per user
- Input validation and sanitization

### Data Privacy
- No storage of user data (except cache)
- Cache keys don't contain PII
- Logs don't include sensitive data
- HTTPS only

### Best Practices
- Validate all inputs
- Sanitize user-provided data
- Use environment variables for secrets
- Implement CORS if needed
- Rate limit to prevent abuse

## Monitoring & Logging

### Metrics to Track
- API request count
- Cache hit rate
- Average response time
- Error rate
- Cost per request
- Usage by user tier

### Logging
- Log all API requests
- Log errors with context
- Log cost-related events
- Use structured logging

### Alerts
- High error rate (>5%)
- High cost (>$5/day)
- Low cache hit rate (<50%)
- Rate limit violations

## Deployment

### Vercel Configuration

**vercel.json**:
```json
{
  "functions": {
    "api/**/*.ts": {
      "maxDuration": 30
    }
  },
  "env": {
    "OPENAI_API_KEY": "@openai-api-key",
    "KV_REST_API_URL": "@kv-rest-api-url",
    "KV_REST_API_TOKEN": "@kv-rest-api-token"
  }
}
```

### Deployment Process
1. Push code to repository
2. Vercel automatically deploys
3. Environment variables configured in Vercel dashboard
4. Monitor deployment logs
5. Test endpoints

## Dependencies

### npm Packages
```json
{
  "dependencies": {
    "@vercel/kv": "^0.2.0",
    "openai": "^4.0.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "typescript": "^5.0.0"
  }
}
```

## Future Considerations

- Database for user data (if needed)
- Webhook support for subscription events
- Analytics endpoint
- Batch processing
- Multi-region deployment
- CDN for static assets
- GraphQL API (if needed)
