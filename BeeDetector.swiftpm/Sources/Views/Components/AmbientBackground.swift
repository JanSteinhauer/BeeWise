//
//  AmbientBackground.swift
//  BeeDetector
//
//  Created by Steinhauer, Jan on 17.02.26.
//

import SwiftUI

struct AmbientBackground: View {
    var body: some View {
        GeometryReader { proxy in
            Circle()
                .fill(Color.orange.opacity(0.15))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .position(x: proxy.size.width * 0.8, y: proxy.size.height * 0.2)
            
            Circle()
                .fill(Color.blue.opacity(0.15))
                .frame(width: 250, height: 250)
                .blur(radius: 50)
                .position(x: proxy.size.width * 0.2, y: proxy.size.height * 0.8)
        }
        .ignoresSafeArea()
    }
}
