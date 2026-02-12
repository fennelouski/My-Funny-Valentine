//
//  AppTextField.swift
//  My Funny Valentine
//

import SwiftUI

struct AppTextField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var characterLimit: Int?
    var axis: Axis = .horizontal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            TextField(placeholder, text: $text, axis: axis)
                .textFieldStyle(.roundedBorder)
                .lineLimit(axis == .vertical ? 3...6 : 1...1)
                .onChange(of: text) { _, newValue in
                    if let limit = characterLimit, newValue.count > limit {
                        text = String(newValue.prefix(limit))
                    }
                }
            
            if let limit = characterLimit {
                Text("\(text.count)/\(limit)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

#Preview {
    AppTextField(
        title: "Inspiration",
        text: .constant(""),
        placeholder: "Enter your inspiration...",
        characterLimit: 50
    )
    .padding()
}
