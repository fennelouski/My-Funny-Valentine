//
//  AIGenerationExampleView.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import SwiftUI
import SwiftData

struct AIGenerationExampleView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var preferencesService = UserPreferencesService()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @State private var showingSayingsGeneration = false
    @State private var showingImageGeneration = false
    @State private var showingUpgradePrompt = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Usage Limit Display
                UsageLimitView(
                    remainingRequests: preferencesService.getRemainingAIRequests(),
                    limit: preferencesService.isPremium ? 20 : 3,
                    isPremium: preferencesService.isPremium,
                    onUpgrade: {
                        showingUpgradePrompt = true
                    }
                )
                .padding()
                
                // AI Generation Buttons
                VStack(spacing: 16) {
                    Button(action: {
                        if preferencesService.canMakeAIRequest() {
                            showingSayingsGeneration = true
                        } else {
                            showingUpgradePrompt = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Generate Sayings")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(preferencesService.canMakeAIRequest() ? Color.accentColor : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!preferencesService.canMakeAIRequest())
                    
                    Button(action: {
                        if preferencesService.canGenerateImage() {
                            showingImageGeneration = true
                        } else {
                            showingUpgradePrompt = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "photo")
                            Text("Generate Custom Image")
                            if preferencesService.isPremium {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(preferencesService.canGenerateImage() ? Color.accentColor : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!preferencesService.canGenerateImage())
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("AI Generation")
            .onAppear {
                preferencesService.setModelContext(modelContext)
                subscriptionManager.checkSubscriptionStatus()
            }
            .sheet(isPresented: $showingSayingsGeneration) {
                SayingsGenerationView(userId: preferencesService.userId) { saying in
                    // Handle selected saying
                    print("Selected saying: \(saying)")
                    preferencesService.recordAIRequest()
                }
            }
            .sheet(isPresented: $showingImageGeneration) {
                ImageGenerationView(
                    userId: preferencesService.userId,
                    isPremium: preferencesService.isPremium
                ) { imageURL in
                    // Handle generated image
                    print("Generated image: \(imageURL)")
                    preferencesService.recordImageGeneration()
                }
            }
            .sheet(isPresented: $showingUpgradePrompt) {
                UpgradePromptView(
                    message: preferencesService.canMakeAIRequest() 
                        ? "Upgrade to Premium to unlock custom image generation and more AI requests!"
                        : "You've reached your limit. Upgrade to Premium for 20 requests per month!",
                    onUpgrade: {
                        Task {
                            do {
                                try await subscriptionManager.purchasePremium()
                                preferencesService.updateSubscriptionStatus(.premium)
                            } catch {
                                print("Purchase error: \(error)")
                            }
                        }
                    },
                    onDismiss: {
                        showingUpgradePrompt = false
                    }
                )
            }
        }
    }
}

#Preview {
    AIGenerationExampleView()
        .modelContainer(for: [UserPreferences.self], inMemory: true)
}
