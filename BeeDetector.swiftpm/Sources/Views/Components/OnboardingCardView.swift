//
//  OnboardingCardView.swift
//  BeeDetector
//
//  Created by Steinhauer, Jan on 17.02.26.
//

import SwiftUI

struct OnboardingCardView: View {
    let title: String
    let bullets: [String]
    
    var body: some View {
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        
        VStack(alignment: .leading, spacing: isPad ? 24 : 16) {
            Text(title)
                .font(isPad ? .largeTitle : .title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary.opacity(0.8))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
            
            VStack(alignment: .leading, spacing: isPad ? 16 : 12) {
                ForEach(bullets, id: \.self) { bullet in
                    BullletPoint(text: bullet, isPad: isPad)
                }
                
            }
            
            
        }
        .padding(isPad ? 32 : 20)
        .background(.ultraThinMaterial)
        .cornerRadius(isPad ? 30 : 20)
        .overlay(
            RoundedRectangle(cornerRadius: isPad ? 30 : 20)
                .stroke(.white.opacity(0.4), lineWidth: 1) // Frosty border
        )
        .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 10) // Depth shadow
        .padding(.horizontal, isPad ? 30 : 16)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}


struct BullletPoint: View {
    let text: String
    var isPad: Bool = UIDevice.current.userInterfaceIdiom == .pad
    
    var body: some View {
        HStack(alignment: .top, spacing: isPad ? 16 : 10) {
            Image(systemName: "circle.fill")
                .font(.system(size: isPad ? 8 : 6))
                .foregroundColor(.black)
                .padding(.top, isPad ? 10 : 8)
            
            Text(LocalizedStringKey(text))
                .font(isPad ? .title3 : .body)
                .foregroundColor(.black)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
        }
    }
}

