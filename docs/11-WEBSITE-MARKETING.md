# Marketing Website

## Overview

The marketing website is a static site that promotes the My Funny Valentine app, provides information about features, and directs users to download the app from the App Store.

## Purpose

- **Marketing**: Promote the app and its features
- **App Store Traffic**: Drive downloads from App Store
- **Information**: Provide details about features and pricing
- **Branding**: Establish brand identity and visual style

## Site Structure

### Pages

1. **Landing Page (Home)**
   - Hero section with app name and tagline
   - Key features showcase
   - App Store download buttons
   - Screenshots gallery
   - Call-to-action sections

2. **Features Page** (optional)
   - Detailed feature descriptions
   - Image galleries
   - Use cases
   - Benefits

3. **Pricing Page** (optional)
   - Free tier information
   - Premium subscription details
   - Value proposition
   - FAQ section

## Content Requirements

### Hero Section
- **Headline**: "Create Personalized Valentine's Cards with AI"
- **Subheadline**: "Make heartfelt cards using your photos, AI-generated sayings, and creative tools"
- **Primary CTA**: "Download on the App Store"
- **Visual**: App icon or hero image

### Key Features Section
- **Feature 1**: AI-Generated Sayings
  - Description: Generate personalized Valentine's sayings with AI
  - Visual: Screenshot or illustration
  
- **Feature 2**: Face Detection
  - Description: Automatically detect and use faces in your cards
  - Visual: Screenshot showing face detection
  
- **Feature 3**: Image Integration
  - Description: Use stickers, smart cutout, and Image Playground
  - Visual: Screenshot showing image features
  
- **Feature 4**: iCloud Sync
  - Description: Access your cards on all your Apple devices
  - Visual: Icon or illustration
  
- **Feature 5**: Social Sharing
  - Description: Share directly to Instagram, Facebook, and TikTok
  - Visual: Social media icons

### Screenshots Section
- **Screenshot 1**: Card creation interface
- **Screenshot 2**: AI sayings generation
- **Screenshot 3**: Face import workflow
- **Screenshot 4**: Card gallery/library
- **Screenshot 5**: Sharing options

### App Store Links
- **Download Button**: App Store badge/link
- **QR Code**: For easy mobile access
- **Direct Link**: App Store URL

### Pricing Information
- **Free Tier**: "Start for free with 3 AI requests"
- **Premium**: "$0.99/month for unlimited creativity"
- **Benefits**: Clear value proposition

## Design Requirements

### Visual Style
- **Color Scheme**: Valentine's theme (reds, pinks, whites)
- **Typography**: Modern, readable fonts
- **Imagery**: High-quality screenshots, illustrations
- **Layout**: Clean, modern, mobile-first

### Branding Elements
- **Logo**: App icon or logo
- **Colors**: Consistent with app design
- **Tone**: Warm, romantic, fun
- **Voice**: Friendly, approachable

### Responsive Design
- **Mobile**: Optimized for phones
- **Tablet**: Optimized for tablets
- **Desktop**: Full-width layout
- **Breakpoints**: Standard responsive breakpoints

## Technical Requirements

### Technology Stack
- **Framework**: Next.js (static export) or plain HTML/CSS/JS
- **Hosting**: Vercel (free tier)
- **Domain**: Custom domain (optional) or Vercel subdomain
- **CDN**: Vercel Edge Network (automatic)

### Performance
- **Page Load**: <2 seconds
- **Lighthouse Score**: >90
- **Image Optimization**: WebP format, lazy loading
- **Code Splitting**: Minimize bundle size

### SEO Optimization
- **Meta Tags**: Title, description, Open Graph
- **Structured Data**: JSON-LD for app information
- **Sitemap**: XML sitemap
- **Robots.txt**: Proper crawling directives

### Analytics
- **Vercel Analytics**: Free tier analytics
- **Google Analytics**: Optional (if needed)
- **Conversion Tracking**: App Store link clicks

## Content Sections

### Hero Section
```html
<!-- Pseudo-structure -->
<section class="hero">
  <h1>Create Personalized Valentine's Cards</h1>
  <p>Make heartfelt cards with AI, your photos, and creative tools</p>
  <a href="[App Store URL]">Download on the App Store</a>
  <img src="app-icon.png" alt="My Funny Valentine">
</section>
```

### Features Grid
```html
<section class="features">
  <div class="feature">
    <img src="ai-sayings.png">
    <h3>AI-Generated Sayings</h3>
    <p>Get personalized Valentine's sayings powered by AI</p>
  </div>
  <!-- More features -->
</section>
```

### Screenshots Gallery
```html
<section class="screenshots">
  <img src="screenshot-1.png" alt="Card creation">
  <img src="screenshot-2.png" alt="AI generation">
  <!-- More screenshots -->
</section>
```

## App Store Integration

### App Store Badges
- **Download Badge**: Official App Store badge
- **Multiple Sizes**: Different sizes for different contexts
- **Localized**: Support multiple languages if needed

### App Store URL
- **Format**: `https://apps.apple.com/app/id[APP_ID]`
- **Deep Linking**: Direct to app if installed
- **Fallback**: App Store web page

### Metadata
- **App Name**: My Funny Valentine
- **Description**: Brief app description
- **Keywords**: Valentine's, cards, AI, photos
- **Category**: Photo & Video or Lifestyle

## Marketing Copy

### Headlines
- "Create the Perfect Valentine's Card"
- "AI-Powered Personalization"
- "Your Photos, Your Story, Your Cards"

### Value Propositions
- "Free to start, premium features available"
- "Sync across all your Apple devices"
- "Share directly to social media"
- "No design skills required"

### Call-to-Actions
- "Download Now"
- "Get Started Free"
- "Try Premium"
- "See Features"

## Deployment

### Vercel Setup
1. Connect repository to Vercel
2. Configure build settings
3. Set environment variables (if needed)
4. Deploy

### Custom Domain (Optional)
1. Configure domain in Vercel
2. Update DNS records
3. SSL certificate (automatic)

### Continuous Deployment
- Automatic deployment on git push
- Preview deployments for pull requests
- Production deployment from main branch

## Analytics & Tracking

### Metrics to Track
- Page views
- App Store link clicks
- Time on page
- Bounce rate
- Conversion rate (downloads)

### Tracking Implementation
- Vercel Analytics (built-in)
- Google Analytics (optional)
- App Store attribution (if available)

## SEO Strategy

### Keywords
- "Valentine's card app"
- "AI Valentine's cards"
- "Personalized cards"
- "Digital Valentine's cards"
- "Photo card maker"

### Meta Tags
```html
<meta name="description" content="Create personalized Valentine's cards with AI, your photos, and creative tools. Free to start, sync across devices.">
<meta property="og:title" content="My Funny Valentine - AI-Powered Card Creator">
<meta property="og:description" content="Create personalized Valentine's cards with AI">
<meta property="og:image" content="[hero-image-url]">
```

### Structured Data
```json
{
  "@context": "https://schema.org",
  "@type": "MobileApplication",
  "name": "My Funny Valentine",
  "applicationCategory": "PhotoApplication",
  "offers": {
    "@type": "Offer",
    "price": "0",
    "priceCurrency": "USD"
  }
}
```

## Future Considerations

- Blog section for SEO
- User testimonials
- Video demos
- Press kit
- Multi-language support
- A/B testing for conversion
- Email capture for updates
- Social media integration

## Cost Considerations

### Hosting
- **Vercel Free Tier**: Unlimited bandwidth, 100GB
- **Custom Domain**: ~$10-15/year (optional)
- **Total**: $0-15/year

### Assets
- **Images**: Use app screenshots (no cost)
- **Design**: Can use free design tools
- **Total**: $0

### Maintenance
- **Updates**: As needed (minimal)
- **Content**: Update for new features
- **Total**: Minimal time investment

## Dependencies

- Vercel account (free)
- App Store Connect (for App Store links)
- Domain registrar (optional)
- Design tools (optional, can use free tools)
