//
//  OnboardingView.swift
//  My Funny Valentine
//
//  First-launch welcome. Custom paging rather than `.tabViewStyle(.page)`
//  so the same flow works on macOS.
//

import SwiftUI

struct OnboardingPage: Identifiable {
    let id = UUID()
    let symbol: String
    let title: String
    let body: String
}

struct OnboardingView: View {
    /// Called when the user finishes or skips.
    var onFinish: () -> Void

    @State private var index = 0

    private var pages: [OnboardingPage] {
        [
            OnboardingPage(
                symbol: "heart.fill",
                title: "My Funny Valentine",
                body: "Make a Valentine's card that actually sounds like you — funny, sweet, and yours in about a minute."
            ),
            OnboardingPage(
                symbol: "sparkles",
                title: "Written on your device",
                body: sayingsBody
            ),
            OnboardingPage(
                symbol: "photo.on.rectangle.angled",
                title: "Add a face, add some art",
                body: "Drop in a photo and we'll find the face for you, or generate artwork to go with your message. Then share it anywhere."
            )
        ]
    }

    /// Tailored to what this device can actually do, so the promise matches
    /// reality on hardware without Apple Intelligence.
    private var sayingsBody: String {
        if OnDeviceSayingsGenerator.isAvailable {
            return "Give us a word — coffee, hiking, their terrible puns — and Apple Intelligence writes the message right here on your device. Nothing you type is sent anywhere."
        }
        return "Give us a word — coffee, hiking, their terrible puns — and we'll suggest messages built around it. Nothing you type leaves your device."
    }

    private var isLastPage: Bool { index == pages.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            skipButton

            Spacer(minLength: 0)

            page(pages[index])
                .id(index)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

            Spacer(minLength: 0)

            pageIndicator
                .padding(.bottom, 24)

            controls
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(background)
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color.pink.opacity(0.18),
                Color.appGroupedBackground
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var skipButton: some View {
        HStack {
            Spacer()
            Button("Skip") {
                onFinish()
            }
            .buttonStyle(.borderless)
            .tint(.secondary)
            .padding(.trailing, 20)
            .padding(.top, 12)
            .opacity(isLastPage ? 0 : 1)
            .disabled(isLastPage)
            .accessibilityIdentifier("onboarding.skip")
        }
    }

    private func page(_ page: OnboardingPage) -> some View {
        VStack(spacing: 24) {
            Image(systemName: page.symbol)
                .font(.system(size: 72))
                .foregroundStyle(Color.pink)
                .accessibilityHidden(true)

            Text(page.title)
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)

            Text(page.body)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
        }
        .padding(.horizontal, 32)
        .accessibilityElement(children: .combine)
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { i in
                Circle()
                    .fill(i == index ? Color.pink : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Page \(index + 1) of \(pages.count)")
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Button(isLastPage ? "Make my first card" : "Next") {
                if isLastPage {
                    onFinish()
                } else {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        index += 1
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .accessibilityIdentifier("onboarding.next")

            Button("Back") {
                withAnimation(.easeInOut(duration: 0.25)) {
                    index -= 1
                }
            }
            .buttonStyle(.borderless)
            .tint(.secondary)
            .opacity(index == 0 ? 0 : 1)
            .disabled(index == 0)
            .accessibilityIdentifier("onboarding.back")
        }
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
