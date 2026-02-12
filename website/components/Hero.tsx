'use client'

export default function Hero() {
  const appStoreUrl = 'https://apps.apple.com/app/id[APP_ID]' // Replace with actual App Store ID

  return (
    <section className="hero">
      <div className="container">
        <div className="hero-content">
          <div className="hero-text">
            <h1>Create Personalized Valentine&apos;s Cards with AI</h1>
            <p className="hero-subtitle">
              Make heartfelt cards using your photos, AI-generated sayings, and creative tools
            </p>
            <div className="hero-cta">
              <a
                href={appStoreUrl}
                className="btn btn-primary"
                aria-label="Download on the App Store"
              >
                <svg
                  width="20"
                  height="20"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                  style={{ marginRight: '8px', verticalAlign: 'middle' }}
                >
                  <path d="M10 0C4.48 0 0 4.48 0 10s4.48 10 10 10 10-4.48 10-10S15.52 0 10 0zm4.64 6.8c-.15 1.58-.8 5.42-1.13 7.19-.14.75-.42 1-.68 1.03-.58.05-1.02-.38-1.58-.75-.88-.58-1.38-.94-2.23-1.5-.99-.65-.35-1.01.22-1.59.15-.15 2.71-2.48 2.76-2.69a.2.2 0 00-.05-.18c-.06-.05-1.36-1-1.88-1.38-.07-.05-.15-.07-.22-.07-.2 0-.48.15-.48.5 0 .2.07.38.15.52.3.6.85 1.5.85 1.5s.14.28.14.68c0 .4-.14.58-.14.58s-1.5 2.01-2.13 2.7c-.32.35-.56.35-.76.35-.2 0-.48-.1-.48-.4 0-.3.22-.6.48-.9.3-.35.6-.7.6-.7s2.4-2.05 2.4-2.5c0-.1-.02-.2-.05-.3-.1-.2-.3-.3-.5-.3-.2 0-.4.1-.5.2-.3.3-.5.5-.5.5s-.2.1-.3.1c-.1 0-.2-.1-.2-.2 0-.1.1-.2.1-.2s.3-.3.5-.5c.2-.2.4-.4.6-.6.1-.1.2-.2.3-.2.1 0 .2.1.2.2 0 .1-.1.2-.1.2s-.2.2-.3.3c-.1.1-.2.2-.2.3 0 .1.1.2.2.2.1 0 .2-.1.3-.2.1-.1.2-.2.3-.3.1-.1.2-.1.3-.1.1 0 .2.1.2.2 0 .1-.1.2-.1.2z"/>
                </svg>
                Download on the App Store
              </a>
            </div>
          </div>
          <div className="hero-image">
            <div className="app-icon-placeholder">
              <svg width="200" height="200" viewBox="0 0 200 200" fill="none">
                <rect width="200" height="200" rx="45" fill="url(#gradient)"/>
                <defs>
                  <linearGradient id="gradient" x1="0" y1="0" x2="200" y2="200">
                    <stop offset="0%" stopColor="#e91e63"/>
                    <stop offset="100%" stopColor="#ff4081"/>
                  </linearGradient>
                </defs>
                <text x="100" y="120" fontSize="80" fill="white" textAnchor="middle" fontWeight="bold">💝</text>
              </svg>
            </div>
          </div>
        </div>
      </div>
      <style jsx>{`
        .hero {
          background: linear-gradient(135deg, var(--color-bg-light) 0%, #ffffff 100%);
          padding: var(--spacing-xl) 0;
          min-height: 80vh;
          display: flex;
          align-items: center;
        }
        
        .hero-content {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: var(--spacing-xl);
          align-items: center;
        }
        
        .hero-text {
          max-width: 600px;
        }
        
        .hero h1 {
          color: var(--color-primary);
          margin-bottom: var(--spacing-md);
        }
        
        .hero-subtitle {
          font-size: clamp(1.1rem, 2vw, 1.25rem);
          color: var(--color-text-light);
          margin-bottom: var(--spacing-lg);
          line-height: 1.6;
        }
        
        .hero-cta {
          margin-top: var(--spacing-md);
        }
        
        .hero-image {
          display: flex;
          justify-content: center;
          align-items: center;
        }
        
        .app-icon-placeholder {
          animation: float 3s ease-in-out infinite;
        }
        
        @keyframes float {
          0%, 100% {
            transform: translateY(0px);
          }
          50% {
            transform: translateY(-20px);
          }
        }
        
        @media (max-width: 768px) {
          .hero {
            min-height: auto;
            padding: var(--spacing-lg) 0;
          }
          
          .hero-content {
            grid-template-columns: 1fr;
            gap: var(--spacing-md);
            text-align: center;
          }
          
          .hero-text {
            max-width: 100%;
          }
        }
      `}</style>
    </section>
  )
}
