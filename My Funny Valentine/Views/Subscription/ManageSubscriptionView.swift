//
//  ManageSubscriptionView.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import SwiftUI

struct ManageSubscriptionView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @State private var isRestoring = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if subscriptionManager.isPremium {
                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.yellow)
                        
                        Text("Premium Active")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let expiresAt = subscriptionManager.subscriptionExpiresAt {
                            Text("Expires: \(expiresAt, style: .date)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    
                    VStack(spacing: 16) {
                        Button(action: {
                            subscriptionManager.manageSubscription()
                        }) {
                            HStack {
                                Image(systemName: "gear")
                                Text("Manage in App Store")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            restorePurchases()
                        }) {
                            HStack {
                                if isRestoring {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Restore Purchases")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.appSecondaryFill)
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                        }
                        .disabled(isRestoring)
                    }
                    .padding()
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "crown")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No Active Subscription")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("You're currently on the free tier")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    Button(action: {
                        restorePurchases()
                    }) {
                        HStack {
                            if isRestoring {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                            } else {
                                Image(systemName: "arrow.clockwise")
                                Text("Restore Purchases")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appSecondaryFill)
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                    .disabled(isRestoring)
                    .padding()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Manage Subscription")
            .appInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func restorePurchases() {
        isRestoring = true
        
        Task {
            do {
                try await subscriptionManager.restorePurchases()
                try? await Task.sleep(nanoseconds: 500_000_000)
                dismiss()
            } catch {
                // Error handled by SubscriptionManager
            }
            
            isRestoring = false
        }
    }
}

#Preview {
    ManageSubscriptionView(subscriptionManager: SubscriptionManager.shared)
}
