'use client'

import { useState } from 'react'

const screenshots = [
  {
    id: 1,
    title: 'Card Creation Interface',
    description: 'Create beautiful cards with an intuitive interface',
    image: '/screenshots/card-creation.png',
  },
  {
    id: 2,
    title: 'AI Sayings Generation',
    description: 'Generate personalized sayings with AI',
    image: '/screenshots/ai-sayings.png',
  },
  {
    id: 3,
    title: 'Face Import Workflow',
    description: 'Easily import and detect faces',
    image: '/screenshots/face-import.png',
  },
  {
    id: 4,
    title: 'Card Gallery',
    description: 'Browse and manage your card collection',
    image: '/screenshots/card-gallery.png',
  },
  {
    id: 5,
    title: 'Sharing Options',
    description: 'Share to social media platforms',
    image: '/screenshots/sharing.png',
  },
]

export default function Screenshots() {
  const [selectedImage, setSelectedImage] = useState<string | null>(null)

  return (
    <>
      <section id="screenshots" className="screenshots section">
        <div className="container">
          <h2 className="section-title">See It In Action</h2>
          <div className="screenshots-grid">
            {screenshots.map((screenshot) => (
              <div
                key={screenshot.id}
                className="screenshot-card"
                onClick={() => setSelectedImage(screenshot.image)}
              >
                <div className="screenshot-placeholder">
                  <div className="screenshot-content">
                    <div className="screenshot-icon">📱</div>
                    <p className="screenshot-title">{screenshot.title}</p>
                    <p className="screenshot-description">{screenshot.description}</p>
                  </div>
                </div>
                {/* TODO: Replace placeholder with actual screenshot image */}
                {/* <img src={screenshot.image} alt={screenshot.title} loading="lazy" /> */}
              </div>
            ))}
          </div>
        </div>
      </section>
      
      {selectedImage && (
        <div
          className="lightbox"
          onClick={() => setSelectedImage(null)}
        >
          <div className="lightbox-content">
            <button
              className="lightbox-close"
              onClick={() => setSelectedImage(null)}
              aria-label="Close"
            >
              ×
            </button>
            <img src={selectedImage} alt="Screenshot" />
          </div>
        </div>
      )}
      
      <style jsx>{`
        .screenshots {
          background-color: var(--color-bg-light);
        }
        
        .screenshots-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
          gap: var(--spacing-md);
          margin-top: var(--spacing-lg);
        }
        
        .screenshot-card {
          cursor: pointer;
          border-radius: var(--border-radius);
          overflow: hidden;
          transition: transform 0.3s ease;
        }
        
        .screenshot-card:hover {
          transform: scale(1.05);
        }
        
        .screenshot-placeholder {
          background: linear-gradient(135deg, var(--color-secondary) 0%, var(--color-primary) 100%);
          aspect-ratio: 9 / 16;
          display: flex;
          align-items: center;
          justify-content: center;
          padding: var(--spacing-md);
        }
        
        .screenshot-content {
          text-align: center;
          color: white;
        }
        
        .screenshot-icon {
          font-size: 4rem;
          margin-bottom: var(--spacing-sm);
        }
        
        .screenshot-title {
          font-weight: 600;
          font-size: 1.1rem;
          margin-bottom: var(--spacing-xs);
        }
        
        .screenshot-description {
          font-size: 0.9rem;
          opacity: 0.9;
        }
        
        .lightbox {
          position: fixed;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          background: rgba(0, 0, 0, 0.9);
          display: flex;
          align-items: center;
          justify-content: center;
          z-index: 1000;
          padding: var(--spacing-md);
        }
        
        .lightbox-content {
          position: relative;
          max-width: 90vw;
          max-height: 90vh;
        }
        
        .lightbox-content img {
          max-width: 100%;
          max-height: 90vh;
          object-fit: contain;
          border-radius: var(--border-radius);
        }
        
        .lightbox-close {
          position: absolute;
          top: -40px;
          right: 0;
          background: transparent;
          border: none;
          color: white;
          font-size: 2rem;
          cursor: pointer;
          width: 40px;
          height: 40px;
          display: flex;
          align-items: center;
          justify-content: center;
        }
        
        @media (max-width: 768px) {
          .screenshots-grid {
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
          }
        }
      `}</style>
    </>
  )
}
