//
//  ErrorMessageView.swift
//  My Funny Valentine
//

import SwiftUI

struct ErrorMessageView: View {
    let message: String
    var onRetry: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title)
                .foregroundStyle(.orange)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            if let onRetry {
                Button("Retry", action: onRetry)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal)
    }
}

#Preview {
    ErrorMessageView(message: "Something went wrong", onRetry: {})
        .padding()
}
