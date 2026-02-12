# Feature Requirements Overview

## Project Description

My Funny Valentine is a digital Valentine's card creation app for iOS with a companion marketing website. The app allows users to create personalized Valentine's cards using AI-generated sayings, face detection, and various image integration features. The backend is deployed on Vercel with a focus on cost optimization.

## Platform Requirements

### iOS App
- **Deployment Target**: iOS 18.0+ (required for Apple Intelligence features)
- **Supported Devices**: iPhone, iPad, Apple Vision Pro
- **Frameworks**: SwiftUI, SwiftData, CloudKit, Vision, PhotosUI, UniformTypeIdentifiers
- **Language**: Swift 5.0+

### Marketing Website
- **Platform**: Static website
- **Hosting**: Vercel (free tier)
- **Requirements**: Mobile-responsive, SEO-optimized

### Backend API
- **Platform**: Vercel Serverless Functions
- **Runtime**: Node.js
- **Database**: Vercel KV (for caching) or similar low-cost solution
- **External APIs**: OpenAI API

## High-Level Feature List

### Core Features
1. **Face Import & Detection**
   - Import user's face photo
   - Import up to one additional face
   - On-device face detection using Vision framework
   - Automatic card generation with imported faces

2. **Image Integration**
   - Apple Image Playground integration (Apple Intelligence)
   - iPhone sticker support
   - Smart cutout feature (long-press drag from Photos app)
   - Image asset management

3. **AI-Powered Card Generation**
   - Generate batches of 10 Valentine's sayings
   - User inspiration input (50 character limit)
   - Cached responses to minimize API costs
   - Custom card creation with AI assistance

4. **Card Creation & Editing**
   - Pre-made templates with face insertion
   - Text editing and customization
   - Card preview interface
   - Multiple card designs

5. **Monetization**
   - Free tier: 3 AI requests
   - Paid subscription: $0.99/month
   - Paid benefits: 20 additional AI requests + 10 custom image generations

6. **Cloud Sync**
   - iCloud sync via CloudKit
   - Cross-device access
   - Offline support

7. **Export & Sharing**
   - Share to Instagram, Facebook, TikTok
   - macOS GIF export with automated animation
   - Standard iOS share sheet integration

8. **Marketing Website**
   - Landing page with app features
   - App Store download links
   - Feature showcase

## Technology Stack Decisions

### iOS App
- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData + CloudKit
- **Image Processing**: Vision framework (on-device)
- **Apple Intelligence**: Image Playground API
- **Subscriptions**: StoreKit 2

### Backend
- **Hosting**: Vercel Serverless Functions
- **Caching**: Vercel KV (Redis-compatible)
- **AI Provider**: OpenAI API
- **Cost-Optimized Model**: GPT-OSS-20b ($0.03/1M input tokens) or GPT-5 Nano ($0.05/1M input tokens)

### Website
- **Framework**: Static HTML/CSS/JS or Next.js (static export)
- **Hosting**: Vercel (free tier)
- **Analytics**: Vercel Analytics (free tier) or Google Analytics

## Cost Optimization Strategy

### API Costs
- Use cheapest OpenAI models (GPT-OSS-20b or GPT-5 Nano)
- Implement aggressive caching for AI responses
- Batch generation (10 sayings per request)
- Cache based on user input hash to avoid duplicate API calls

### Infrastructure Costs
- Vercel free tier for hosting (100GB bandwidth, unlimited requests)
- Vercel KV free tier for caching (256MB storage)
- CloudKit free tier (1GB storage per user)

### Monetization Strategy
- Free tier limits to control costs
- Paid subscription to offset API costs
- Usage tracking to monitor costs per user

## User Stories

### As a user, I want to:
1. Import my face and a loved one's face to create personalized cards
2. Use images from my iPhone's sticker collection
3. Use smart cutout to extract faces from photos
4. Generate Valentine's sayings with AI based on my inspiration
5. Create custom cards with AI assistance
6. Access my cards across all my Apple devices
7. Share my cards on social media platforms
8. Export animated GIFs on macOS
9. Try the app for free before subscribing

## Dependencies

### iOS App
- iOS 18.0+ SDK
- Xcode 26.2+
- Apple Developer Account
- CloudKit container configured

### Backend
- Node.js 18+
- OpenAI API account and key
- Vercel account
- Vercel KV instance

### Website
- Vercel account
- Domain name (optional)

## Future Considerations

- Web app version for non-iOS users
- Additional social media platforms
- More card templates and designs
- Collaborative card creation
- Print-on-demand integration
- Additional subscription tiers
