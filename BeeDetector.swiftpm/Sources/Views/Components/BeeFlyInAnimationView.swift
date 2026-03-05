//
//  BeeFlyInAnimationView.swift
//  BeeDetector
//
//  Created by Steinhauer, Jan on 17.02.26.
//

import SwiftUI

struct BeeFlyInAnimationView: View {
    @State private var isTalking: Bool = false
    @State private var isFlapping: Bool = true
    
    // Animation States
    @State private var beeOffsetX: CGFloat = -1500
    @State private var beeOffsetY: CGFloat = 150
    @State private var beeRotation: Double = -10
    
    @Binding var showHeadline: Bool
    @Binding var showContent: Bool
    
    var body: some View {
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        LogoAnimation(isTalking: $isTalking, isFlapping: $isFlapping)
            .frame(width: isPad ? 400 : 250, height: isPad ? 400 : 250)
            .rotationEffect(.degrees(beeRotation))
            .offset(x: beeOffsetX, y: beeOffsetY)
            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            .onAppear {
                withAnimation(.easeOut(duration: 1.5)) {
                    beeOffsetX = 0
                }
                
                withAnimation(.easeInOut(duration: 1.5)) {
                    beeOffsetY = 0
                }
                
                withAnimation(.easeInOut(duration: 1.5)) {
                    beeRotation = 0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    isTalking = true
                    withAnimation(.spring()) {
                        showHeadline = true
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.spring()) {
                        showContent = true
                    }
                }
            }
    }
    
    
}
