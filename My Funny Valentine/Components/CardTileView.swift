//
//  CardThumbnailView.swift
//  My Funny Valentine
//

import SwiftUI
import SwiftData

struct CardTileView: View {
    let card: Card
    var size: CGSize = CGSize(width: 160, height: 220)
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1, green: 0.4, blue: 0.5),
                            Color(red: 0.9, green: 0.2, blue: 0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size.width, height: size.height)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            
            VStack(spacing: 8) {
                if let thumbnailData = (card.faces ?? []).first?.thumbnailData,
                   let uiImage = UIImage(data: thumbnailData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: size.width * 0.6, maxHeight: size.height * 0.4)
                        .clipShape(Circle())
                }
                
                Text(displayText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 8)
            }
        }
    }
    
    private var displayText: String {
        card.customText ?? card.saying ?? "New Card"
    }
}

#Preview {
    CardTileView(card: Card(saying: "You're the best!"))
        .padding()
}
