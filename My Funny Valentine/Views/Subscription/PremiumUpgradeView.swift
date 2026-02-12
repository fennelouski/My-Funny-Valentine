//
//  PremiumUpgradeView.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import SwiftUI

struct PremiumUpgradeView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow)
                        
                        Text("Upgrade to Premium")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Unlock unlimited creativity")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Benefits List
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Premium Benefits")
                            .font(.headline)
                        
                        BenefitRow(
                            icon: "sparkles",
                            title: "20 AI Requests per Month",
                            description: "Get 20 AI-generated sayings every month"
                        )
                        
                        BenefitRow(
                            icon: "photo.artframe",
                            title: "10 Custom Image Generations",
                            description: "Create unique images for your cards"
                        )
                        
                        BenefitRow(
                            icon: "star.fill",
                            title: "Priority Support",
                            description: "Get help when you need it"
                        )
                        
                        BenefitRow(
                            icon: "gift.fill",
                            title: "Early Access",
                            description: "Be first to try new templates"
                        )
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    // Pricing
                    VStack(spacing: 8) {
                        Text("$0.99")
                            .font(.system(size: 48, weight: .bold))
                        
                        Text("per month")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    // Purchase Button
                    Button(action: {
                        purchasePremium()
                    }) {
                        HStack {
                            if isPurchasing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "star.fill")
                                Text("Subscribe for $0.99/month")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isPurchasing ? Color.gray : Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isPurchasing)
                    
                    // Terms
                    Text("Subscription automatically renews unless cancelled at least 24 hours before the end of the current period.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Restore Purchases
                    Button(action: {
                        restorePurchases()
                    }) {
                        Text("Restore Purchases")
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                    }
                }
                .padding()
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func purchasePremium() {
        isPurchasing = true
        
        Task {
            do {
                try await subscriptionManager.purchasePremium()
                // Success - dismiss after a brief delay to show success
                try? await Task.sleep(nanoseconds: 500_000_000)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            
            isPurchasing = false
        }
    }
    
    private func restorePurchases() {
        Task {
            do {
                try await subscriptionManager.restorePurchases()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    PremiumUpgradeView(subscriptionManager: SubscriptionManager.shared)
}
