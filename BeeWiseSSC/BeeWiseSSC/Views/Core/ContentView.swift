//
//  BeeDetectorView.swift
//  BeeWiseSSC
//
//  Created by Steinhauer, Jan on 01.02.26.
//

import SwiftUI


// MARK: - Glass Tab Bar

struct GlassTabBar: View {
    @Binding var selected: AppTab
    @State private var bounceTrigger: [AppTab: Int] = Dictionary(
        uniqueKeysWithValues: AppTab.allCases.map { ($0, 0) }
    )

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    bounceTrigger[tab, default: 0] += 1
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selected = tab
                    }
                } label: {
                    VStack(spacing: 5) {
                        if tab == .detector {
                            Image(selected == tab ? "bee_yellow" : "bee_gray")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                        } else {
                            Image(systemName: tab.icon)
                                .font(.system(size: 22, weight: selected == tab ? .bold : .regular))
                                .symbolEffect(.bounce, value: bounceTrigger[tab, default: 0])
                        }
                        Text(tab.title)
                            .font(.caption2.weight(selected == tab ? .semibold : .regular))
                    }
                    .foregroundStyle(selected == tab ? Color.beeGold : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay {
                    Capsule()
                        .strokeBorder(.white.opacity(0.25), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.18), radius: 24, x: 0, y: 8)
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Content View

struct ContentView: View {
    @State private var selectedTab: AppTab = .detector
    @State private var showSettings = false

    var body: some View {
        ZStack(alignment: .bottom) {

            Group {
                switch selectedTab {
                case .detector:
                    NavigationStack {
                        BeeDetectorView()
                            .toolbar {
                                ToolbarItem(placement: .principal) {
                                    Text("Varroa Mite Detector")
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                }
                                ToolbarItem(placement: .topBarTrailing) {
                                    
                                    Button {
                                        showSettings = true
                                    } label: {
                                        Image(systemName: "gearshape.fill")
                                            .foregroundStyle(.primary)
                                    }
                                }
                            }
                    }

                case .hive:
                    HiveView()

                case .learn:
                    ExplanationView()
           
                }
            }
            .ignoresSafeArea(edges: .bottom)

            GlassTabBar(selected: $selectedTab)
                .padding(.bottom, 16)
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}
