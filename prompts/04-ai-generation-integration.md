# Prompt 04: AI Generation Integration

## Objective
Integrate AI generation features into the iOS app, including sayings generation and custom image generation.

## Context
The app needs to call the backend API for AI generation, handle responses, display results, and manage usage limits.

## Reference Documentation
- `docs/03-AI-GENERATION.md` - AI generation requirements
- `docs/08-BACKEND-ARCHITECTURE.md` - API endpoints

## Tasks

### 1. Create API Service for AI Generation
- Implement `generateSayings` function
- Call `/api/generate-sayings` endpoint
- Handle request/response
- Implement error handling
- Support caching on client side

### 2. Create Sayings Generation UI
- Input field for inspiration text (50 char limit)
- Character counter
- Generate button
- Loading state indicator
- Display 10 generated sayings
- Selection interface for sayings
- Error message display

### 3. Implement Usage Tracking
- Track AI requests per user
- Display remaining requests
- Show usage limits based on subscription
- Reset logic (daily for free, monthly for paid)
- Store usage in UserPreferences model

### 4. Create Custom Image Generation UI (Premium)
- Input field for description (100 char limit)
- Style selector (valentine, romantic, funny)
- Generate button (premium only)
- Loading state
- Display generated image
- Add to card functionality
- Usage limit display

### 5. Implement Client-Side Caching
- Cache sayings responses locally
- Check cache before API call
- Display cache indicator
- Manage cache size
- Invalidate cache appropriately

### 6. Create Sayings Selection Flow
- Display sayings in list/grid
- Allow selection of sayings
- Preview selected saying on card
- Add saying to card
- Edit saying text

### 7. Handle Rate Limiting
- Check usage before API call
- Show upgrade prompt when limit reached
- Display remaining requests
- Handle 429 responses gracefully
- Show retry options

### 8. Create Premium Feature Gates
- Check subscription status before image generation
- Show upgrade prompt for non-premium users
- Display premium badge/indicator
- Handle subscription validation

## Deliverables
- Complete API integration for AI generation
- Sayings generation UI
- Custom image generation UI (premium)
- Usage tracking implementation
- Client-side caching
- Rate limiting handling
- Premium feature gates

## Notes
- Validate input on client side
- Show clear loading states
- Handle network errors gracefully
- Cache responses to reduce API calls
- Display usage limits clearly
- Guide users to upgrade when needed
