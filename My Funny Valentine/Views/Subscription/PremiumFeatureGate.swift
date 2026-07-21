//
//  PremiumFeatureGate.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import SwiftUI

struct PremiumFeatureGate<Content: View>: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    let content: () -> Content
    let premiumContent: (() -> Content)?
    @State private var showUpgrade = false
    
    init(
        subscriptionManager: SubscriptionManager,
        @ViewBuilder content: @escaping () -> Content,
        premiumContent: (() -> Content)? = nil
    ) {
        self.subscriptionManager = subscriptionManager
        self.content = content
        self.premiumContent = premiumContent
    }
    
    var body: some View {
        if subscriptionManager.isPremium {
            if let premiumContent = premiumContent {
                premiumContent()
            } else {
                content()
            }
        } else {
            ZStack {
                content()
                    .blur(radius: 2)
                    .disabled(true)
                
                VStack(spacing: 16) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("Premium Feature")
                        .font(.headline)
                    
                    Text("Upgrade to unlock this feature")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        showUpgrade = true
                    }) {
                        HStack {
                            Image(systemName: "star.fill")
                            Text("Upgrade to Premium")
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color(.systemBackground).opacity(0.95))
                .cornerRadius(16)
                .shadow(radius: 10)
            }
            .sheet(isPresented: $showUpgrade) {
                PremiumUpgradeView(subscriptionManager: subscriptionManager)
            }
        }
    }
}

// MARK: - View Modifier

struct PremiumGateModifier: ViewModifier {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @State private var showUpgrade = false
    
    func body(content: Content) -> some View {
        Group {
            if subscriptionManager.isPremium {
                content
            } else {
                content
                    .overlay(
                        Button(action: {
                            showUpgrade = true
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: "lock.fill")
                                    .font(.title2)
                                Text("Premium")
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.accentColor.opacity(0.8))
                            .cornerRadius(8)
                        }
                        .sheet(isPresented: $showUpgrade) {
                            PremiumUpgradeView(subscriptionManager: subscriptionManager)
                        }
                    )
            }
        }
    }
}

extension View {
    func premiumGate(subscriptionManager: SubscriptionManager) -> some View {
        modifier(PremiumGateModifier(subscriptionManager: subscriptionManager))
    }
}

#Preview {
    PremiumFeatureGate(subscriptionManager: SubscriptionManager.shared) {
        Text("Premium Content")
            .padding()
            .background(Color.blue)
    }
}
