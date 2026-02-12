//
//  SubscriptionBadge.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import SwiftUI

struct SubscriptionBadge: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @State private var showUpgrade = false
    
    var body: some View {
        Button(action: {
            if subscriptionManager.isPremium {
                // Could show subscription details
            } else {
                showUpgrade = true
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: subscriptionManager.isPremium ? "crown.fill" : "crown")
                    .font(.caption)
                
                Text(subscriptionManager.isPremium ? "Premium" : "Free")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(subscriptionManager.isPremium ? .yellow : .secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                subscriptionManager.isPremium
                    ? Color.yellow.opacity(0.2)
                    : Color(.systemGray5)
            )
            .cornerRadius(8)
        }
        .sheet(isPresented: $showUpgrade) {
            PremiumUpgradeView(subscriptionManager: subscriptionManager)
        }
    }
}

#Preview {
    HStack {
        SubscriptionBadge(subscriptionManager: SubscriptionManager.shared)
    }
    .padding()
}
