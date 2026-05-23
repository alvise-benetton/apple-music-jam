//
//  QRCodeView.swift
//  AppleMusicJAM
//
//  Created by Apple Music JAM.
//

import SwiftUI

/// A reusable SwiftUI view that renders a QR code for the given URL string.
///
/// Uses `QRCodeService` to generate the image and displays it with nearest-
/// neighbour interpolation so the code stays pixel-sharp at any size.
struct QRCodeView: View {

    // MARK: - Parameters

    /// The URL string to encode in the QR code.
    let url: String

    /// The desired point size of the QR code image. Defaults to 200.
    var size: CGFloat = 200

    // MARK: - State

    @State private var appeared = false

    // MARK: - Body

    var body: some View {
        Group {
            if let uiImage = QRCodeService.generateQRCode(
                from: url,
                size: size * 2 // retina
            ) {
                Image(uiImage: uiImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            } else {
                // Fallback when generation fails.
                Image(systemName: "qrcode")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.6, height: size * 0.6)
                    .foregroundColor(.white.opacity(0.3))
                    .frame(width: size, height: size)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "8b5cf6"), Color(hex: "ec4899")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
        )
        .shadow(color: Color(hex: "8b5cf6").opacity(0.35), radius: 20, y: 8)
        .scaleEffect(appeared ? 1.0 : 0.85)
        .opacity(appeared ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: appeared)
        .onAppear { appeared = true }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(hex: "0a0a1a").ignoresSafeArea()
        QRCodeView(url: "http://192.168.1.42:8080", size: 220)
    }
}
