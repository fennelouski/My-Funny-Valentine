//
//  PrimaryButtonStyle.swift
//  My Funny Valentine
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    var isDestructive: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isDestructive ? Color.red : Color.pink)
                    .opacity(configuration.isPressed ? 0.8 : 1)
            )
    }
}

#Preview {
    VStack(spacing: 16) {
        Button("Primary") {}
            .buttonStyle(PrimaryButtonStyle())
        
        Button("Destructive") {}
            .buttonStyle(PrimaryButtonStyle(isDestructive: true))
    }
    .padding()
}
