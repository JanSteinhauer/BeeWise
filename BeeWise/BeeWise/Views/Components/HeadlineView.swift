//
//  HeadlineView.swift
//  BeeDetector
//
//  Created by Steinhauer, Jan on 17.02.26.
//

import SwiftUI

struct HeadlineView: View {
    let text: String
    let show: Bool
    
    var body: some View {
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        if show {
            Text(text)
                .font(.system(size: isPad ? 40 : 32, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.top, isPad ? 60 : 20)
                .padding(.horizontal)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                .transition(.move(edge: .top).combined(with: .opacity))
        } else {
            Color.clear.frame(height: isPad ? 100 : 60)
        }
    }
}

