# My Funny Valentine - Marketing Website

Marketing website for the My Funny Valentine iOS app, built with Next.js and deployed on Vercel.

## Features

- Modern, responsive design with Valentine's theme
- Hero section with app download CTA
- Features showcase
- Screenshots gallery with lightbox
- Pricing information
- SEO optimized
- Analytics integration (Vercel Analytics)
- Performance optimized

## Getting Started

### Development

```bash
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

### Build

```bash
npm run build
```

This creates a static export in the `out` directory.

### Deploy

The site is configured for Vercel deployment. Simply connect your repository to Vercel and deploy.

## Configuration

### App Store URL

Update the App Store URL in:
- `components/Hero.tsx`
- `components/Footer.tsx`

Replace `[APP_ID]` with your actual App Store ID.

### Domain

Update the domain in:
- `public/robots.txt`
- `app/sitemap.ts`

## Project Structure

```
website/
├── app/
│   ├── layout.tsx      # Root layout with metadata
│   ├── page.tsx        # Home page
│   └── globals.css    # Global styles
├── components/
│   ├── Hero.tsx        # Hero section
│   ├── Features.tsx    # Features grid
│   ├── Screenshots.tsx # Screenshots gallery
│   ├── Pricing.tsx     # Pricing section
│   └── Footer.tsx      # Footer
├── public/             # Static assets
└── package.json        # Dependencies
```

## Customization

### Colors

Edit CSS variables in `app/globals.css`:

```css
:root {
  --color-primary: #e91e63;
  --color-primary-dark: #c2185b;
  --color-secondary: #f8bbd0;
  /* ... */
}
```

### Content

Update content in component files:
- `components/Hero.tsx` - Hero text
- `components/Features.tsx` - Feature descriptions
- `components/Screenshots.tsx` - Screenshot data
- `components/Pricing.tsx` - Pricing information

## Performance

- Images are optimized (WebP format recommended)
- Lazy loading for screenshots
- Code splitting enabled
- Static export for fast loading

## SEO

- Meta tags configured
- Open Graph tags
- Structured data (JSON-LD)
- Sitemap generation
- Robots.txt

## Analytics

Vercel Analytics is integrated. No additional configuration needed for basic analytics.

## License

Copyright © 2025 My Funny Valentine
