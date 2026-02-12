# AI Generation System

## Overview

The app uses OpenAI's API to generate Valentine's sayings in batches of 10, with user-provided inspiration text (up to 50 characters). Responses are aggressively cached to minimize API costs.

## Core Features

### 1. Valentine's Sayings Generation

**Description**: Generate batches of 10 Valentine's sayings based on user inspiration input.

**Requirements**:
- User input: Up to 50 characters of inspiration text
- Output: 10 unique Valentine's sayings
- Caching: Cache responses based on input hash
- Cost optimization: Use cheapest available models

**User Flow**:
1. User enters inspiration text (max 50 characters)
2. User taps "Generate Sayings" button
3. App checks cache first
4. If not cached, makes API request to Vercel endpoint
5. Endpoint checks cache, then calls OpenAI if needed
6. Returns 10 sayings to user
7. User can select sayings to use in cards

**Technical Implementation**:

#### Frontend (iOS)
- Validate input length (50 character limit)
- Hash user input for cache key
- Call Vercel API endpoint: `POST /api/generate-sayings`
- Display loading state
- Show generated sayings in UI
- Handle errors gracefully

#### Backend (Vercel)
- Endpoint: `/api/generate-sayings`
- Check Vercel KV cache using input hash
- If cached, return cached response
- If not cached:
  - Call OpenAI API with optimized prompt
  - Store response in cache (TTL: 7 days)
  - Return response to client
- Rate limiting per user

**API Contract**:
```typescript
// Request
POST /api/generate-sayings
{
  "inspiration": string, // max 50 chars
  "userId": string // for rate limiting
}

// Response
{
  "sayings": string[], // 10 sayings
  "cached": boolean,
  "timestamp": number
}
```

### 2. Response Caching Strategy

**Description**: Aggressive caching to minimize API costs and improve response times.

**Caching Layers**:
1. **Client-side cache** (iOS): In-memory cache for current session
2. **Server-side cache** (Vercel KV): Redis-compatible cache
3. **Cache key**: Hash of user input (case-insensitive, trimmed)

**Cache Strategy**:
- **Key**: `sayings:${hash(inspiration.toLowerCase().trim())}`
- **TTL**: 7 days
- **Storage**: Vercel KV (free tier: 256MB)
- **Invalidation**: Manual (admin) or TTL expiration

**Cache Benefits**:
- Reduces API calls for common inputs
- Faster response times for cached queries
- Lower costs (no API call if cached)
- Better user experience

**Implementation**:
```typescript
// Pseudo-code
async function generateSayings(inspiration: string) {
  const cacheKey = `sayings:${hash(inspiration.toLowerCase().trim())}`;
  
  // Check cache
  const cached = await kv.get(cacheKey);
  if (cached) {
    return { sayings: cached, cached: true };
  }
  
  // Call OpenAI
  const sayings = await callOpenAI(inspiration);
  
  // Store in cache
  await kv.set(cacheKey, sayings, { ex: 7 * 24 * 60 * 60 }); // 7 days
  
  return { sayings, cached: false };
}
```

### 3. Model Selection

**Description**: Use cost-optimized OpenAI models to minimize API costs.

**Selected Models** (as of February 2026):
- **Primary**: GPT-OSS-20b
  - Input: $0.03 per 1M tokens
  - Output: $0.14 per 1M tokens
- **Fallback**: GPT-5 Nano
  - Input: $0.05 per 1M tokens
  - Output: $0.40 per 1M tokens

**Model Selection Logic**:
1. Try GPT-OSS-20b first (cheapest)
2. If unavailable or error, fallback to GPT-5 Nano
3. Log model usage for cost tracking

**Cost Estimation**:
- Average prompt: ~100 tokens (input)
- Average response: ~200 tokens (output)
- Cost per request: ~$0.00003 (GPT-OSS-20b)
- With caching: ~90% reduction in API calls
- Estimated monthly cost: <$10 for 1000 unique requests

### 4. Prompt Engineering

**Description**: Optimize prompts for cost and quality.

**Prompt Structure**:
```
Generate 10 unique Valentine's Day sayings based on this inspiration: "{inspiration}"

Requirements:
- Each saying should be romantic, heartfelt, or funny
- Keep sayings concise (under 100 characters each)
- Make them personal and creative
- Return only the sayings, one per line, no numbering

Sayings:
```

**Prompt Optimization**:
- Keep prompts concise to reduce input tokens
- Use clear instructions to reduce retries
- Request specific format to minimize parsing
- Include examples in system prompt (cached)

**Token Usage**:
- System prompt: ~150 tokens (cached, not counted per request)
- User input: ~50 tokens (inspiration + formatting)
- Response: ~200 tokens (10 sayings)
- Total: ~250 tokens per request

### 5. Custom Image Generation

**Description**: Generate custom images for cards using AI (paid feature).

**Requirements**:
- Available only to paid subscribers
- 10 custom image generations per month
- Use OpenAI DALL-E or similar image generation API
- Cache generated images

**User Flow**:
1. User (with paid subscription) requests custom image
2. User provides description (max 100 characters)
3. App calls `/api/generate-image` endpoint
4. Endpoint checks subscription status
5. Endpoint checks usage limits
6. Generate image via OpenAI
7. Cache image
8. Return image URL to client

**API Contract**:
```typescript
// Request
POST /api/generate-image
{
  "description": string, // max 100 chars
  "userId": string,
  "style": "valentine" | "romantic" | "funny"
}

// Response
{
  "imageUrl": string,
  "cached": boolean,
  "remainingGenerations": number
}
```

## User Stories

### As a user, I want to:
1. Generate Valentine's sayings based on my inspiration
2. Get quick responses without waiting
3. See different sayings each time I generate
4. Use AI to create custom images for my cards (paid feature)
5. Know when I've reached my usage limits

## Technical Requirements

### Backend Endpoints

#### `/api/generate-sayings`
- Method: POST
- Authentication: User ID (from app)
- Rate limiting: Per user, per subscription tier
- Caching: Vercel KV
- Cost tracking: Log each API call

#### `/api/generate-image`
- Method: POST
- Authentication: User ID + subscription validation
- Rate limiting: 10 per month for paid users
- Caching: Vercel KV + image storage
- Cost tracking: Log each generation

### Environment Variables
```
OPENAI_API_KEY=sk-...
OPENAI_MODEL=gpt-oss-20b
KV_REST_API_URL=...
KV_REST_API_TOKEN=...
```

### Error Handling
- API timeout: 30 seconds
- Rate limit exceeded: Return 429 with retry-after
- Invalid input: Return 400 with error message
- OpenAI error: Log and return 500 with generic message
- Cache error: Fallback to direct API call

### Rate Limiting
- Free tier: 3 requests per day
- Paid tier: 20 requests per day
- Track in Vercel KV: `rate_limit:${userId}:${date}`

## Dependencies

- OpenAI API account and key
- Vercel KV instance
- Node.js 18+
- Vercel serverless functions

## Cost Monitoring

### Metrics to Track
- API calls per day
- Cache hit rate
- Average tokens per request
- Cost per request
- Total monthly cost

### Alerts
- Daily cost exceeds $5
- Cache hit rate below 50%
- API error rate above 5%

## Future Considerations

- Support for multiple languages
- User feedback on generated sayings (improve prompts)
- A/B testing different models
- Fine-tuned model for Valentine's sayings
- Batch generation for multiple users
- Custom style preferences
