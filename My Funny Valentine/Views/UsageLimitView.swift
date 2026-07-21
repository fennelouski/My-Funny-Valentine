//
//  UsageLimitView.swift
//  My Funny Valentine
//
//  Created by Nathan Fennel on 2/12/26.
//

import SwiftUI

struct UsageLimitView: View {
    let remainingRequests: Int
    let limit: Int
    let isPremium: Bool
    let onUpgrade: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: isPremium ? "crown.fill" : "info.circle.fill")
                    .foregroundColor(isPremium ? .yellow : .blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(isPremium ? "Premium" : "Free Tier")
                        .font(.headline)
                    
                    Text("\(remainingRequests) of \(limit) requests remaining")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !isPremium {
                    Button(action: onUpgrade) {
                        Text("Upgrade")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(Color.appFill)
            .cornerRadius(10)
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.appSecondaryFill)
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(remainingRequests > 0 ? Color.accentColor : Color.red)
                        .frame(width: geometry.size.width * CGFloat(remainingRequests) / CGFloat(limit), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
    }
}

struct UpgradePromptView: View {
    let message: String
    let onUpgrade: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 40))
                .foregroundColor(.yellow)
            
            Text("Upgrade to Premium")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                Button(action: onDismiss) {
                    Text("Maybe Later")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.appSecondaryFill)
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                }
                
                Button(action: onUpgrade) {
                    Text("Upgrade")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color.appBackground)
        .cornerRadius(16)
        .shadow(radius: 10)
    }
}

#Preview {
    VStack(spacing: 20) {
        UsageLimitView(
            remainingRequests: 2,
            limit: 3,
            isPremium: false,
            onUpgrade: {}
        )
        
        UsageLimitView(
            remainingRequests: 15,
            limit: 20,
            isPremium: true,
            onUpgrade: {}
        )
    }
    .padding()
}
