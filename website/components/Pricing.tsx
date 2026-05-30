'use client'

export default function Pricing() {
  return (
    <section id="pricing" className="pricing section">
      <div className="container">
        <h2 className="section-title">Simple Pricing</h2>
        <div className="pricing-grid">
          <div className="pricing-card">
            <div className="pricing-header">
              <h3>Free</h3>
              <div className="pricing-price">$0</div>
            </div>
            <ul className="pricing-features">
              <li>✓ 3 AI requests</li>
              <li>✓ Basic card creation</li>
              <li>✓ Face detection</li>
              <li>✓ iCloud sync</li>
              <li>✓ Social sharing</li>
            </ul>
            <p className="pricing-description">
              Perfect for trying out the app and creating a few special cards.
            </p>
          </div>
          
          <div className="pricing-card featured">
            <div className="pricing-badge">Most Popular</div>
            <div className="pricing-header">
              <h3>Premium</h3>
              <div className="pricing-price">$0.99<span>/month</span></div>
            </div>
            <ul className="pricing-features">
              <li>✓ Everything in Free</li>
              <li>✓ 20 additional AI requests</li>
              <li>✓ 10 custom image generations</li>
              <li>✓ Unlimited creativity</li>
              <li>✓ Priority support</li>
            </ul>
            <p className="pricing-description">
              Unlock unlimited creativity with premium features.
            </p>
          </div>
        </div>
      </div>
      <style jsx>{`
        .pricing {
          background-color: var(--color-bg);
        }
        
        .pricing-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
          gap: var(--spacing-md);
          margin-top: var(--spacing-lg);
          max-width: 800px;
          margin-left: auto;
          margin-right: auto;
        }
        
        .pricing-card {
          background: white;
          border: 2px solid var(--color-border);
          border-radius: var(--border-radius);
          padding: var(--spacing-md);
          position: relative;
          transition: transform 0.3s ease, box-shadow 0.3s ease;
        }
        
        .pricing-card:hover {
          transform: translateY(-5px);
          box-shadow: var(--shadow-lg);
        }
        
        .pricing-card.featured {
          border-color: var(--color-primary);
          box-shadow: var(--shadow);
        }
        
        .pricing-badge {
          position: absolute;
          top: -12px;
          left: 50%;
          transform: translateX(-50%);
          background: var(--color-primary);
          color: white;
          padding: 4px 16px;
          border-radius: 20px;
          font-size: 0.875rem;
          font-weight: 600;
        }
        
        .pricing-header {
          text-align: center;
          margin-bottom: var(--spacing-md);
          padding-top: var(--spacing-sm);
        }
        
        .pricing-header h3 {
          color: var(--color-primary);
          font-size: 1.5rem;
          margin-bottom: var(--spacing-xs);
        }
        
        .pricing-price {
          font-size: 2.5rem;
          font-weight: 700;
          color: var(--color-text);
        }
        
        .pricing-price span {
          font-size: 1rem;
          color: var(--color-text-light);
          font-weight: 400;
        }
        
        .pricing-features {
          list-style: none;
          margin-bottom: var(--spacing-md);
        }
        
        .pricing-features li {
          padding: var(--spacing-xs) 0;
          color: var(--color-text);
        }
        
        .pricing-description {
          color: var(--color-text-light);
          font-size: 0.9rem;
          text-align: center;
          margin-top: var(--spacing-md);
        }
        
        @media (max-width: 768px) {
          .pricing-grid {
            grid-template-columns: 1fr;
          }
        }
      `}</style>
    </section>
  )
}
