'use client'

export default function Footer() {
  const currentYear = new Date().getFullYear()
  const appStoreUrl = 'https://apps.apple.com/app/id[APP_ID]' // Replace with actual App Store ID

  return (
    <footer className="footer">
      <div className="container">
        <div className="footer-content">
          <div className="footer-section">
            <h3>My Funny Valentine</h3>
            <p>Create personalized Valentine&apos;s cards with AI</p>
          </div>
          
          <div className="footer-section">
            <h4>Download</h4>
            <a
              href={appStoreUrl}
              className="app-store-link"
              aria-label="Download on the App Store"
            >
              <svg width="120" height="40" viewBox="0 0 120 40" fill="none">
                <rect width="120" height="40" rx="8" fill="#000"/>
                <text x="60" y="25" fontSize="12" fill="white" textAnchor="middle" fontWeight="600">
                  App Store
                </text>
              </svg>
            </a>
          </div>
          
          <div className="footer-section">
            <h4>Links</h4>
            <ul className="footer-links">
              <li><a href="#features">Features</a></li>
              <li><a href="#screenshots">Screenshots</a></li>
              <li><a href="#pricing">Pricing</a></li>
            </ul>
          </div>
        </div>
        
        <div className="footer-bottom">
          <p>&copy; {currentYear} My Funny Valentine. All rights reserved.</p>
        </div>
      </div>
      <style jsx>{`
        .footer {
          background-color: #2c2c2c;
          color: white;
          padding: var(--spacing-xl) 0 var(--spacing-md);
        }
        
        .footer-content {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
          gap: var(--spacing-lg);
          margin-bottom: var(--spacing-lg);
        }
        
        .footer-section h3 {
          color: var(--color-primary);
          margin-bottom: var(--spacing-sm);
        }
        
        .footer-section h4 {
          color: white;
          margin-bottom: var(--spacing-sm);
          font-size: 1.1rem;
        }
        
        .footer-section p {
          color: #cccccc;
          font-size: 0.9rem;
        }
        
        .footer-links {
          list-style: none;
        }
        
        .footer-links li {
          margin-bottom: var(--spacing-xs);
        }
        
        .footer-links a {
          color: #cccccc;
          transition: color 0.2s ease;
        }
        
        .footer-links a:hover {
          color: var(--color-primary);
        }
        
        .app-store-link {
          display: inline-block;
          transition: transform 0.2s ease;
        }
        
        .app-store-link:hover {
          transform: scale(1.05);
        }
        
        .footer-bottom {
          text-align: center;
          padding-top: var(--spacing-md);
          border-top: 1px solid #444;
          color: #999;
          font-size: 0.875rem;
        }
        
        @media (max-width: 768px) {
          .footer-content {
            grid-template-columns: 1fr;
            text-align: center;
          }
        }
      `}</style>
    </footer>
  )
}
