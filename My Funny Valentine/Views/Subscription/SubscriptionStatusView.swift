//
//  SubscriptionStatusView.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import SwiftUI

struct SubscriptionStatusView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @ObservedObject var usageTracker: UsageTracker
    @State private var showUpgradeView = false
    @State private var showManageSubscription = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Subscription Status Badge
            HStack {
                Image(systemName: subscriptionManager.isPremium ? "crown.fill" : "crown")
                    .foregroundColor(subscriptionManager.isPremium ? .yellow : .gray)
                
                Text(subscriptionManager.isPremium ? "Premium" : "Free")
                    .font(.headline)
                    .foregroundColor(subscriptionManager.isPremium ? .primary : .secondary)
                
                Spacer()
                
                if subscriptionManager.isPremium, let expiresAt = subscriptionManager.subscriptionExpiresAt {
                    Text("Expires: \(expiresAt, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.appFill)
            .cornerRadius(12)
            
            // Usage Statistics
            VStack(alignment: .leading, spacing: 12) {
                Text("Usage")
                    .font(.headline)
                
                // AI Requests
                UsageRow(
                    title: "AI Requests",
                    used: usageTracker.aiRequestsUsed,
                    limit: subscriptionManager.isPremium ? 20 : 3,
                    remaining: usageTracker.remainingAIRequests
                )
                
                // Image Generations (Premium only)
                if subscriptionManager.isPremium {
                    UsageRow(
                        title: "Image Generations",
                        used: usageTracker.imageGenerationsUsed,
                        limit: 10,
                        remaining: usageTracker.remainingImageGenerations
                    )
                }
            }
            .padding()
            .background(Color.appFill)
            .cornerRadius(12)
            
            // Action Buttons
            VStack(spacing: 12) {
                if !subscriptionManager.isPremium {
                    Button(action: {
                        showUpgradeView = true
                    }) {
                        HStack {
                            Image(systemName: "star.fill")
                            Text("Upgrade to Premium")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                } else {
                    Button(action: {
                        showManageSubscription = true
                    }) {
                        HStack {
                            Image(systemName: "gear")
                            Text("Manage Subscription")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appSecondaryFill)
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                }
                
                Button(action: {
                    Task {
                        do {
                            try await subscriptionManager.restorePurchases()
                        } catch {
                            // Error handled by SubscriptionManager
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Restore Purchases")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.appSecondaryFill)
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Subscription")
        .sheet(isPresented: $showUpgradeView) {
            PremiumUpgradeView(subscriptionManager: subscriptionManager)
        }
        .sheet(isPresented: $showManageSubscription) {
            ManageSubscriptionView(subscriptionManager: subscriptionManager)
        }
    }
}

struct UsageRow: View {
    let title: String
    let used: Int
    let limit: Int
    let remaining: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text("\(used) / \(limit)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: Double(used), total: Double(limit))
                .tint(remaining > 0 ? .green : .red)
            
            Text("\(remaining) remaining")
                .font(.caption)
                .foregroundColor(remaining > 0 ? .secondary : .red)
        }
    }
}

#Preview {
    NavigationView {
        SubscriptionStatusView(
            subscriptionManager: SubscriptionManager.shared,
            usageTracker: UsageTracker.shared
        )
    }
}
