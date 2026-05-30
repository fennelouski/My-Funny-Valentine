import type { Metadata } from 'next'
import { Analytics } from '@vercel/analytics/react'
import './globals.css'

export const metadata: Metadata = {
  title: 'My Funny Valentine - Create Personalized Valentine\'s Cards with AI',
  description: 'Make heartfelt Valentine\'s cards using your photos, AI-generated sayings, and creative tools. Free to start, sync across all your Apple devices.',
  keywords: ['Valentine\'s card app', 'AI Valentine\'s cards', 'personalized cards', 'digital Valentine\'s cards', 'photo card maker'],
  authors: [{ name: 'My Funny Valentine' }],
  openGraph: {
    title: 'My Funny Valentine - AI-Powered Card Creator',
    description: 'Create personalized Valentine\'s cards with AI, your photos, and creative tools',
    type: 'website',
    locale: 'en_US',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'My Funny Valentine - AI-Powered Card Creator',
    description: 'Create personalized Valentine\'s cards with AI',
  },
  robots: {
    index: true,
    follow: true,
  },
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <head>
        <link rel="icon" href="/favicon.ico" sizes="any" />
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{
            __html: JSON.stringify({
              '@context': 'https://schema.org',
              '@type': 'MobileApplication',
              name: 'My Funny Valentine',
              applicationCategory: 'PhotoApplication',
              operatingSystem: 'iOS',
              offers: {
                '@type': 'Offer',
                price: '0',
                priceCurrency: 'USD',
              },
              description: 'Create personalized Valentine\'s cards with AI, your photos, and creative tools',
            }),
          }}
        />
      </head>
      <body>
        {children}
        <Analytics />
      </body>
    </html>
  )
}
