//
//  SplashScreenView.swift
//  scrume
//
//  Created by NEIHT on 17/1/26.
//

import SwiftUI

/// Splash Screen - Màn hình khởi động đơn giản
struct SplashScreenView: View {
    @State private var isActive = false
    @State private var logoOpacity: Double = 0

    var body: some View {
        if isActive {
            ContentView()
        } else {
            splashContent
                .onAppear {
                    startAnimations()
                }
        }
    }

    private var splashContent: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()

            // App Icon
            Image("SplashLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .opacity(logoOpacity)
        }
    }

    private func startAnimations() {
        // Fade in logo
        withAnimation(.easeOut(duration: 0.5)) {
            logoOpacity = 1.0
        }

        // Transition to main content
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isActive = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SplashScreenView()
}
