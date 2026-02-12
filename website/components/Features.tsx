'use client'

const features = [
  {
    id: 1,
    title: 'AI-Generated Sayings',
    description: 'Generate personalized Valentine\'s sayings with AI based on your inspiration. Get creative, romantic, or funny messages tailored to your relationship.',
    icon: '✨',
  },
  {
    id: 2,
    title: 'Face Detection',
    description: 'Automatically detect and use faces in your cards. Import your face and a loved one\'s face to create truly personalized cards.',
    icon: '👤',
  },
  {
    id: 3,
    title: 'Image Integration',
    description: 'Use stickers, smart cutout, and Image Playground to add creative elements to your cards. Drag and drop from your Photos app.',
    icon: '🖼️',
  },
  {
    id: 4,
    title: 'iCloud Sync',
    description: 'Access your cards on all your Apple devices. Your creations sync seamlessly across iPhone, iPad, and Apple Vision Pro.',
    icon: '☁️',
  },
  {
    id: 5,
    title: 'Social Sharing',
    description: 'Share directly to Instagram, Facebook, and TikTok. Export animated GIFs on macOS. Your cards are ready to spread the love.',
    icon: '📱',
  },
]

export default function Features() {
  return (
    <section className="features section">
      <div className="container">
        <h2 className="section-title">Powerful Features</h2>
        <div className="features-grid">
          {features.map((feature) => (
            <div key={feature.id} className="feature-card">
              <div className="feature-icon">{feature.icon}</div>
              <h3>{feature.title}</h3>
              <p>{feature.description}</p>
            </div>
          ))}
        </div>
      </div>
      <style jsx>{`
        .features {
          background-color: var(--color-bg);
        }
        
        .features-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
          gap: var(--spacing-md);
          margin-top: var(--spacing-lg);
        }
        
        .feature-card {
          background: white;
          padding: var(--spacing-md);
          border-radius: var(--border-radius);
          box-shadow: var(--shadow);
          transition: transform 0.3s ease, box-shadow 0.3s ease;
          text-align: center;
        }
        
        .feature-card:hover {
          transform: translateY(-5px);
          box-shadow: var(--shadow-lg);
        }
        
        .feature-icon {
          font-size: 3rem;
          margin-bottom: var(--spacing-sm);
        }
        
        .feature-card h3 {
          color: var(--color-primary);
          margin-bottom: var(--spacing-sm);
          font-size: 1.5rem;
        }
        
        .feature-card p {
          color: var(--color-text-light);
          line-height: 1.6;
        }
        
        @media (max-width: 768px) {
          .features-grid {
            grid-template-columns: 1fr;
          }
        }
      `}</style>
    </section>
  )
}
