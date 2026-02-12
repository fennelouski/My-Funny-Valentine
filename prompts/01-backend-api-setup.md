# Prompt 01: Backend API Setup

## Objective
Set up the Vercel backend API with serverless functions for AI generation, subscription validation, and usage tracking.

## Context
This is the backend for the My Funny Valentine iOS app. The backend will be deployed on Vercel and handle AI requests, caching, and subscription validation.

## Reference Documentation
- `docs/08-BACKEND-ARCHITECTURE.md` - Complete backend architecture
- `docs/03-AI-GENERATION.md` - AI generation requirements
- `docs/05-MONETIZATION.md` - Subscription and usage tracking

## Tasks

### 1. Initialize Vercel Project
- Create `api/` directory structure
- Set up `package.json` with dependencies:
  - `@vercel/kv` for caching
  - `openai` for AI generation
  - TypeScript support
- Create `vercel.json` configuration file
- Set up environment variables structure

### 2. Implement `/api/generate-sayings` Endpoint
- Accept POST requests with `inspiration` (max 50 chars) and `userId`
- Validate input (length, format)
- Check rate limits using Vercel KV
- Check cache using hash of inspiration text
- If not cached, call OpenAI API (GPT-OSS-20b model)
- Cache response for 7 days
- Return 10 sayings array with metadata
- Handle errors gracefully (400, 429, 500)

### 3. Implement `/api/generate-image` Endpoint
- Accept POST requests with `description`, `userId`, and `style`
- Validate subscription status (premium only)
- Check usage limits (10 per month)
- Generate image using OpenAI DALL-E or similar
- Cache image URL
- Return image URL and remaining generations
- Handle errors (403 for non-premium, 429 for limit)

### 4. Implement `/api/validate-subscription` Endpoint
- Accept POST requests with `userId` and optional `receipt`
- Validate subscription status
- Return subscription info, expiration, and usage limits
- Handle App Store receipt validation (if implementing server-side)

### 5. Implement Rate Limiting Logic
- Track usage per user in Vercel KV
- Free tier: 3 requests per day
- Paid tier: 20 requests per month
- Reset logic based on subscription tier
- Return remaining requests in responses

### 6. Implement Caching Layer
- Use Vercel KV for caching
- Cache key format: `sayings:${hash(inspiration)}`
- TTL: 7 days for sayings, 30 days for images
- Implement cache hit/miss tracking

### 7. Error Handling
- Consistent error response format
- Proper HTTP status codes
- User-friendly error messages
- Logging for debugging

### 8. Environment Variables
- Document required env vars
- Set up example `.env.example` file
- Include: OPENAI_API_KEY, KV credentials, etc.

## Deliverables
- Complete Vercel API with all endpoints
- Proper error handling
- Rate limiting implementation
- Caching implementation
- Environment variable documentation
- README with setup instructions

## Notes
- Use cost-optimized OpenAI models (GPT-OSS-20b)
- Implement aggressive caching to minimize costs
- All endpoints should validate input
- Consider security (input sanitization, rate limiting)
