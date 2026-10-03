import SwiftUI

struct CardTileView: View {
    let card: Card
    var size = CGSize(width: 160, height: 240)
    var faceAnimationPhase: Double? = nil

    var body: some View {
        Group {
            if let image = CardRenderer.shared.renderCard(card, size: CGSize(width: size.width * 2, height: size.height * 2), faceAnimationPhase: faceAnimationPhase) {
                PlatformImageUtils.swiftUIImage(from: image)
                    .resizable()
                    .scaledToFit()
            } else {
                ContentUnavailableView("Card unavailable", systemImage: "photo")
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.primary.opacity(0.1)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([card.saying, card.customText].compactMap { $0 }.joined(separator: ". "))
    }
}
