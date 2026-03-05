
//
//  OnboardingView.swift
//  BeeDetector
//
//  Created by Steinhauer, Jan on 13.02.26.
//

import SwiftUI
import AVKit
import AVFoundation
import UIKit

struct OnboardingPageData {
    let headline: String
    let title: String
    let bullets: [String]
    let animation: String
}

struct LoopingVideoPlayer: UIViewRepresentable {
    let videoName: String
    
    func makeUIView(context: Context) -> LoopingVideoUIView {
        return LoopingVideoUIView(videoName: videoName)
    }
    
    func updateUIView(_ uiView: LoopingVideoUIView, context: Context) {}
}

class LoopingVideoUIView: UIView {
    private let playerLayer = AVPlayerLayer()
    private var playerLooper: AVPlayerLooper?
    private var queuePlayer: AVQueuePlayer?
    
    init(videoName: String) {
        super.init(frame: .zero)
        
        if let url = Bundle.main.url(forResource: videoName, withExtension: "mov") {
            let asset = AVAsset(url: url)
            let item = AVPlayerItem(asset: asset)
            
            let player = AVQueuePlayer(playerItem: item)
            player.isMuted = true
            
            self.playerLooper = AVPlayerLooper(player: player, templateItem: item)
            self.queuePlayer = player
            
            self.playerLayer.player = player
            self.playerLayer.videoGravity = .resizeAspectFill
            self.layer.addSublayer(playerLayer)
            
            player.play()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

struct OnboardingView: View {
    @State private var currentPage = 0
    
    @State private var showHeadline: Bool = false
    @State private var showContent: Bool = false
    
    @AppStorage("isOnboardingCompleted") var isOnboardingCompleted: Bool = false
    
    private let pages: [OnboardingPageData] = [
        OnboardingPageData(
            headline: "Meet Bee Spector",
            title: "Fighting the Hive's Vampire",
            bullets: [
                "Varroa Mites are tiny parasites that suck the life out of honey bees.",
                "They are the number 1 threat to bee colonies worldwide.",
                "To save the bees, we first have to find the mites."
            ],
            animation: "BeeFlyInAnimtion"
        ),
        OnboardingPageData(
            headline: "The Old Way is Sticky",
            title: "The Powdered Sugar Shake",
            bullets: [
                "Beekeepers currently shake 300+ bees in a jar with powdered sugar.",
                "This dislodges mites for manual counting but is messy and stressful.",
                "Counting tiny red dots by hand is slow and often inaccurate."
            ],
            animation: "SugarShakeAnimation"
        ),
        OnboardingPageData(
            headline: "A High Tech Lens",
            title: "How Computer Vision Sees Mites",
            bullets: [
                "**Smart Scanning:** AI identifies individual bees on the frame via Saliency.",
                "**Color Filtering:** The app filters for the specific reddish-brown hue of a mite.",
                "**Geometry Check:** A Hough Transform detects the mite’s unique round shape."
            ],
            animation: "ScanAnimation"
        ),
        OnboardingPageData(
            headline: "Healthier Hives, Zero Stress",
            title: "Better for Bees and Beekeepers",
            bullets: [
                "**Non Invasive:** Identify threats from a photo. No bees die in a jar today.",
                "**Precision Care:** Spot infestations early, before the colony collapses.",
                "**Data Driven:** Track mite levels over time to treat only when necessary."
            ],
            animation: "ComparisionAnimation"
        ),
        OnboardingPageData(
            headline: "Why This Matters",
            title: "A Hero for the Hive",
            bullets: [
                "**Zero Casualties:** Traditional tests kill hundreds of bees in sugar or alcohol jars. My AI requires only a photo.",
                "**Smart Treatment:** Many beekeepers use harsh preventive chemicals. With precise data, you only treat when truly necessary.",
                "**Less Stress:** Avoid organic acids that can agitate the colony and shorten the queen's lifespan."
            ],
            animation: "ComparisionAnimation"
        )
    ]
    
    
    var body: some View {
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let videoSize: CGFloat = isPad ? 300 : 220
        
        ZStack {
            
            AmbientBackground()
            
            VStack(spacing: 0) {
                
                HeadlineView(text: pages[currentPage].headline, show: showHeadline)
                
                
                Spacer()
                
                switch pages[currentPage].animation {
                case "BeeFlyInAnimtion":
                    BeeFlyInAnimationView(showHeadline: $showHeadline, showContent: $showContent)
                    
                case "SugarShakeAnimation":
                    LoopingVideoPlayer(videoName: "SugarShakeAnimation")
                        .frame(width: videoSize, height: videoSize)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
                        .onAppear {
                            withAnimation(.spring()) {
                                showHeadline = true
                                showContent = true
                            }
                        }
                case "ScanAnimation":
                    LoopingVideoPlayer(videoName: "ScanAnimation")
                        .frame(width: videoSize, height: videoSize)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
                        .onAppear {
                            withAnimation(.spring()) {
                                showHeadline = true
                                showContent = true
                            }
                        }
                    
                case "ComparisionAnimation":
                    LoopingVideoPlayer(videoName: "ComparisionAnimation")
                        .frame(width: videoSize, height: videoSize)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
                        .onAppear {
                            withAnimation(.spring()) {
                                showHeadline = true
                                showContent = true
                            }
                        }
                    
                default:
                    EmptyView()
                }
                
                Spacer()
                
                if showContent {
                    OnboardingCardView(
                        title: pages[currentPage].title,
                        bullets: pages[currentPage].bullets
                    )
                }
                
                else {
                    Color.clear.frame(height: 300)
                }
                
                Spacer()
                
                
                
                if showContent {
                    
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Capsule()
                                .fill(currentPage == index ? Color.beeGold : Color.gray.opacity(0.3))
                                .frame(width: currentPage == index ? 30 : 10, height: 10)
                                .opacity(index > currentPage ? 0.4 : 1.0) // Dim future dots
                                .animation(.spring(), value: currentPage)
                                .onTapGesture {
                                    guard index < currentPage else { return }
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        showHeadline = false
                                        showContent = false
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                        currentPage = index
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            withAnimation(.spring()) {
                                                showHeadline = true
                                                showContent = true
                                            }
                                        }
                                    }
                                }
                        }
                    }
                    .padding(.bottom, 30)
                    
                    Button(action: {
                        advancePage()
                    }) {
                        Text("Next")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(
                                Color.beeGold
                            )
                            .clipShape(Capsule())
                            .shadow(color: .blue.opacity(0.4), radius: 10, x: 0, y: 5)
                            .overlay(
                                Capsule().stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                    .transition(.opacity)
                } else {
                    Color.clear.frame(height: 80).padding(.bottom, 50)
                }
            }
        }
        
    }
    
    private func advancePage() {
        if currentPage < pages.count - 1 {
            withAnimation(.easeOut(duration: 0.2)) {
                showHeadline = false
                showContent = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                currentPage += 1
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring()) {
                        showHeadline = true
                        showContent = true
                    }
                }
            }
        } else {
            isOnboardingCompleted = true
        }
    }
}





#Preview {
    OnboardingView()
}
