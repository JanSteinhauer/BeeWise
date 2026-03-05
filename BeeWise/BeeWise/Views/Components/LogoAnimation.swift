//
//  SwiftUIView.swift
//  BeeDetector
//
//  Created by Steinhauer, Jan on 13.02.26.
//

import SwiftUI
import Combine

struct LogoAnimation: View {
    @Binding var isTalking: Bool
    @Binding var isFlapping: Bool
    
    @State private var mouthState: Int = 0
    let timer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Image("RightWing")
                .resizable()
                .scaledToFit()
                .rotationEffect(.degrees(isFlapping ? 10 : -10), anchor: UnitPoint(x: 0.5574, y: 0.3111))
                .animation(.easeInOut(duration: 0.15).repeatForever(autoreverses: true), value: isFlapping)
            
            Image("LeftWing")
                .resizable()
                .scaledToFit()
                .rotationEffect(.degrees(isFlapping ? -10 : 10), anchor: UnitPoint(x: 0.6528, y: 0.4472))
                .animation(.easeInOut(duration: 0.15).repeatForever(autoreverses: true), value: isFlapping)
            
            Image("BeeBase")
                .resizable()
                .scaledToFit()
            
            Group {
                if mouthState == 0 {
                    Image("MouthClosed")
                        .resizable()
                        .scaledToFit()
                } else if mouthState == 1 {
                    Image("MouthSlightlyOpen")
                        .resizable()
                        .scaledToFit()
                } else {
                    Image("MouthOpen")
                        .resizable()
                        .scaledToFit()
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .onReceive(timer) { _ in
            if isTalking {
                withAnimation(.easeInOut(duration: 0.1)) {
                     mouthState = [0, 1, 2, 1].randomElement() ?? 0
                }
            } else {
                withAnimation(.easeInOut(duration: 0.1)) {
                    mouthState = 0
                }
            }
        }
    }
}

#Preview {
    LogoAnimation(isTalking: .constant(true), isFlapping: .constant(true))
}
