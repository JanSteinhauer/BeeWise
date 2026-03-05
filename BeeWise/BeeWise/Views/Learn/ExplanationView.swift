//
//  ExplanationView.swift
//  BeeWise
//
//  Created by Steinhauer, Jan on 22.02.26.
//

import SwiftUI
import PDFKit

// MARK: - PDF Viewer

struct PDFViewerView: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> PDFView {
        let v = PDFView()
        v.autoScales = true
        v.displayMode = .singlePageContinuous
        v.displayDirection = .vertical
        if let doc = PDFDocument(url: url) { v.document = doc }
        return v
    }
    func updateUIView(_ uiView: PDFView, context: Context) {}
}

// MARK: - Card Model

struct LearnCard: Identifiable {
    enum Destination { case sheet, varroaDetail, whyItMatters, scientificRelationship, varroaInfluences, behindTheBuild }
    let id = UUID()
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let body: String
    let destination: Destination
}

// MARK: - Main View

struct ExplanationView: View {
    @State private var sheetCard: LearnCard? = nil
    @State private var navPath = NavigationPath()

    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

// MARK: - Card Button Style

struct CardButtonStyle: ButtonStyle {
    let color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .shadow(color: color.opacity(configuration.isPressed ? 0.05 : 0.15), radius: configuration.isPressed ? 4 : 12, x: 0, y: configuration.isPressed ? 2 : 6)
    }
}

    private let cards: [LearnCard] = [
        LearnCard(icon: "allergens",              color: .red,     title: "What is Varroa?",      subtitle: "The hive's silent killer",      body: "", destination: .varroaDetail),
        LearnCard(icon: "chart.bar.fill",         color: .green,   title: "Why It Matters",       subtitle: "Early action saves colonies",   body: "", destination: .whyItMatters),
        LearnCard(icon: "building.columns.fill",  color: .brown,   title: "Research Basis",       subtitle: "Inspired by science",           body: "", destination: .scientificRelationship),
        LearnCard(icon: "leaf.fill",              color: .teal,    title: "Varroa Influences",    subtitle: "Breed & queen age effects",     body: "", destination: .varroaInfluences),
        LearnCard(icon: "paintpalette.fill",      color: .indigo,  title: "Behind the Build",     subtitle: "Custom ML & Graphics",          body: "", destination: .behindTheBuild),
    ]

    var body: some View {
        NavigationStack(path: $navPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {

                    // ── 2×N card grid ────────────────────────────────
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(cards) { card in
                            LearnCardCell(card: card) {
                                switch card.destination {
                                case .sheet:                  sheetCard = card
                                case .varroaDetail:           navPath.append("varroa")
                                case .whyItMatters:           navPath.append("whyItMatters")
                                case .scientificRelationship: navPath.append("scientific")
                                case .varroaInfluences:       navPath.append("influences")
                                case .behindTheBuild:         navPath.append("behindTheBuild")
                                }
                            }
                        }
                    }
                }
                .padding()
                .padding(.bottom, 100)
            }
            .navigationTitle("Learn")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: String.self) { key in
                switch key {
                case "varroa":       WhatIsVarroaView()
                case "whyItMatters": WhyItMattersView()
                case "scientific":     ScientificRelationshipView()
                case "influences":     VarroaInfluencesView()
                case "behindTheBuild": BehindTheBuildView()
                default:               EmptyView()
                }
            }
            .sheet(item: $sheetCard) { card in
                LearnCardSheetView(card: card)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

// MARK: - Card Cell

struct LearnCardCell: View {
    let card: LearnCard
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(card.color.opacity(0.15)).frame(width: 52, height: 52)
                    Image(systemName: card.icon)
                        .font(.title2.weight(.semibold)).foregroundStyle(card.color)
                }
                Text(card.title).font(.headline).foregroundStyle(Color.primary)
                Text(card.subtitle).font(.caption).foregroundStyle(Color.primary)
                Spacer(minLength: 0)
                Label("Read more", systemImage: "arrow.right.circle.fill")
                    .font(.caption.bold()).foregroundStyle(card.color)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.regularMaterial)
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(.white.opacity(0.25), lineWidth: 1))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens details about \(card.title)")
    }
}

// MARK: - Simple Sheet

struct LearnCardSheetView: View {
    let card: LearnCard
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(card.color.opacity(0.15)).frame(width: 64, height: 64)
                            Image(systemName: card.icon).font(.largeTitle.weight(.semibold)).foregroundStyle(card.color)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(card.title).font(.title2.bold())
                            Text(card.subtitle).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    Divider()
                    Text(card.body).font(.body).lineSpacing(5)
                }
                .padding(24)
            }
            .navigationTitle(card.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() }.fontWeight(.semibold) } }
        }
    }
}

// MARK: - What is Varroa Detail

struct WhatIsVarroaView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                infoCard(color: .red) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Varroa destructor is an ectoparasitic mite that feeds on the fat bodies of adult bees and developing brood, weakening immunity, stunting development, and transmitting lethal viruses.")
                            .font(.body)
                        Text("Originally a parasite of the Asian bee Apis cerana, it jumped to Apis mellifera in the 1950s and has since spread globally.")
                            .font(.body).foregroundStyle(.secondary)
                    }
                }

                sectionHeader("Viruses It Transmits", icon: "allergens", color: .purple)
                infoCard(color: .purple) {
                    VStack(alignment: .leading, spacing: 6) {
                        bullet("Deformed Wing Virus (DWV): causes crumpled wings and shortened abdomen")
                        bullet("Israeli Acute Paralysis Virus (IAPV): linked to colony collapse")
                        bullet("Sacbrood Virus: kills larvae inside their cells")
                    }
                }

                sectionHeader("Reproduction Cycle", icon: "arrow.triangle.2.circlepath", color: .orange)
                infoCard(color: .orange) {
                    Text("A female mite enters a brood cell just before capping. She lays 1 male and 1–5 females. By the time the bee emerges, a new mated female mite is ready to infest the next cell. Without treatment, populations double every 3–4 weeks during peak season.")
                        .font(.body)
                }

                sectionHeader("Scientific Sources", icon: "book.closed.fill", color: .brown)
                linkRow(title: "Rosenkranz et al. (2010) — Biology and control of Varroa destructor", url: "https://doi.org/10.1016/j.jip.2009.07.016")
                linkRow(title: "Nazzi & Le Conte (2016) — Ecology of Varroa destructor, Annual Review of Entomology", url: "https://doi.org/10.1146/annurev-ento-010715-023731")
                linkRow(title: "Genersch et al. (2010) — The German bee monitoring project, Apidologie", url: "https://doi.org/10.1051/apido/2010014")
            }
            .padding()
            .padding(.bottom, 100)
        }
        .navigationTitle("What is Varroa?")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Why It Matters Detail

struct WhyItMattersView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                infoCard(color: .green) {
                    Text("Detecting Varroa early is the difference between a small, targeted treatment and losing the entire colony. BeeWise replaces destructive counting methods (sugar shake, alcohol wash) with a non-invasive photo scan.")
                        .font(.body)
                }

                sectionHeader("What Happens With Wrong Treatment", icon: "exclamationmark.triangle.fill", color: .red)

                infoCard(color: .orange) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("**Treating too late**: populations above the economic threshold (3 mites per 100 bees) cause exponential colony damage before the treatment takes effect.")
                            .font(.body)
                        Text("**Incorrect timing**: oxalic acid applied with capped brood present is only ~40% effective vs. ~95%+ during a brood-free period.")
                            .font(.body)
                        Text("**Resistance build-up**: repeated use of Apivar (amitraz) without rotation leads to miticide-resistant Varroa populations, documented across Europe and North America.")
                            .font(.body)
                        Text("**Miticide residues**: synthetic treatments accumulate in beeswax, affecting queen fertility and larval survival over multiple seasons.")
                            .font(.body)
                    }
                }

                sectionHeader("Why Monitoring Frequency Matters", icon: "calendar", color: .blue)
                infoCard(color: .blue) {
                    Text("The Honey Bee Health Coalition recommends monitoring at least once a month during the active season. A colony that crosses the 3% threshold can collapse within 4–6 weeks without intervention. BeeWise makes frequent monitoring practical.")
                        .font(.body)
                }

                sectionHeader("Scientific Sources", icon: "book.closed.fill", color: .brown)
                linkRow(title: "Maggi et al. (2016) — Amitraz resistance in Varroa, Apidologie", url: "https://doi.org/10.1007/s13592-015-0388-5")
                linkRow(title: "Higes et al. (2020) — Effects of oxalic acid on honey bees, Apidologie", url: "https://doi.org/10.1007/s13592-020-00776-5")
                linkRow(title: "Mullin et al. (2010) — Miticide residues in North American apiaries, PLoS ONE", url: "https://doi.org/10.1371/journal.pone.0009754")
                linkRow(title: "Honey Bee Health Coalition — Varroa management guide", url: "https://honeybeehealthcoalition.org/varroa/")
            }
            .padding()
            .padding(.bottom, 100)
        }
        .navigationTitle("Why It Matters")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Scientific Relationship

struct ScientificRelationshipView: View {
    @State private var showPDF = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                infoCard(color: .brown) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("BeeWise's detection pipeline directly implements the approach described in this peer-reviewed paper:")
                            .font(.body)
                        Text("\"Deep Learning Beehive Monitoring System for Early Detection of the Varroa Mite\"")
                            .font(.headline)
                        Text("Voudiotis, Moraiti & Kontogiannis — University of Ioannina, Greece (2022)")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                }

                sectionHeader("Pipeline Mapping", icon: "arrow.triangle.branch", color: .indigo)
                infoCard(color: .indigo) {
                    VStack(alignment: .leading, spacing: 8) {
                        mappingRow(paper: "Bee Object Detection", app: "Custom ML model → bounding boxes")
                        Divider()
                        mappingRow(paper: "Image Processing for Mite", app: "HSB colour filter + Hough circles")
                        Divider()
                        mappingRow(paper: "Brood-frame camera module", app: "iPhone camera → imported photo")
                    }
                }

                sectionHeader("Research Paper", icon: "doc.fill", color: .red)
                Button { showPDF = true } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.red.opacity(0.12)).frame(width: 52, height: 52)
                            Image(systemName: "doc.fill").font(.title2).foregroundStyle(.red)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Detection of Varroa Mite").font(.headline).foregroundStyle(.primary)
                            Text("Tap to open PDF").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityHint("Opens research paper PDF")
            }
            .padding()
            .padding(.bottom, 100)
        }
        .navigationTitle("Scientific Relationship")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showPDF) {
            NavigationStack {
                Group {
                    if let url = Bundle.main.url(forResource: "Detection of Varroa Mite", withExtension: "pdf") {
                        PDFViewerView(url: url).ignoresSafeArea(edges: .bottom)
                    } else {
                        ContentUnavailableView("PDF not found", systemImage: "doc.fill")
                    }
                }
                .navigationTitle("Research Paper")
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Varroa Influences

struct VarroaInfluencesView: View {
    @State private var selectedBreed: String = "Carniolan"
    private let breeds = ["Carniolan", "Italian", "Buckfast", "Saskatraz", "Caucasian"]

    private let breedInfo: [String: (resistance: String, detail: String)] = [
        "Carniolan": (
            resistance: "Moderate",
            detail: "Carniolan bees show moderate hygienic behaviour and brood break tendency in autumn, which naturally interrupts the Varroa reproductive cycle. However, they are not selectively bred for mite resistance, so standard monitoring and treatment protocols still apply."
        ),
        "Italian": (
            resistance: "Lower",
            detail: "Italian bees are prolific breeders with large, continuous brood areas, giving Varroa maximum opportunity to reproduce. Studies show Italian colonies reach critical infestation levels faster than other breeds. More frequent monitoring (every 3 weeks) is recommended."
        ),
        "Buckfast": (
            resistance: "Good",
            detail: "Developed by Brother Adam at Buckfast Abbey, this breed was partly selected for hygienic behaviour. Buckfast bees show above-average grooming and uncapping of mite-infested cells, reducing Varroa build up. Still requires regular monitoring."
        ),
        "Saskatraz": (
            resistance: "High",
            detail: "A Canadian-developed breed combining Russian genetics (known for natural Varroa tolerance) with high honey production traits. Saskatraz colonies maintain lower mite loads, but are not immune annual monitoring remains essential, especially before winter."
        ),
        "Caucasian": (
            resistance: "Moderate",
            detail: "Gentle bees known for propolis collection. Caucasian bees show moderate susceptibility — similar to Carniolan. No specific selective breeding for Varroa resistance. Colony monitoring should follow standard seasonal protocols."
        )
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Breed picker
                sectionHeader("Bee Breed", icon: "bee_yellow", color: .orange)
                Picker("Breed", selection: $selectedBreed) {
                    ForEach(breeds, id: \.self) { Text($0) }
                }
                .pickerStyle(.segmented)

                if let info = breedInfo[selectedBreed] {
                    infoCard(color: .orange) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Varroa Resistance")
                                    .font(.caption.bold()).foregroundStyle(.secondary)
                                Spacer()
                                resistanceBadge(info.resistance)
                            }
                            Text(info.detail).font(.body)
                        }
                    }
                }

                // Queen age
                sectionHeader("Queen Age Effects", icon: "crown.fill", color: .yellow)
                infoCard(color: .yellow) {
                    VStack(alignment: .leading, spacing: 10) {
                        ageRow(age: "< 1 year", label: "Young", detail: "Peak laying rate → large brood area → maximum Varroa reproduction. Monitor every 2–3 weeks during summer.")
                        Divider()
                        ageRow(age: "1–2 years", label: "Prime", detail: "Optimal honey production; balanced brood rhythm. Varroa populations build predictably, monthly monitoring sufficient.")
                        Divider()
                        ageRow(age: "> 2 years", label: "Older", detail: "Reduced egg laying creates natural brood breaks that interrupt Varroa cycles. However, supersedure events can disrupt timing. Plan queen replacement strategically to maximise the mite reduction benefit.")
                    }
                }

                sectionHeader("Scientific Sources", icon: "book.closed.fill", color: .brown)
                linkRow(title: "Büchler et al. (2014) — Survival of Varroa-infested honey bee colonies, J. Apicultural Research", url: "https://doi.org/10.3896/IBRA.1.53.2.04")
                linkRow(title: "Locke (2016) — Natural Varroa mite-surviving Apis mellifera, Apidologie", url: "https://doi.org/10.1007/s13592-015-0412-9")
                linkRow(title: "Büchler et al. (2010) — Breeding for Varroa resistance, Bee World", url: "https://doi.org/10.1080/0005772X.2010.11417329")
            }
            .padding()
            .padding(.bottom, 100)
        }
        .navigationTitle("Varroa Influences")
        .navigationBarTitleDisplayMode(.large)
    }

    private func resistanceBadge(_ level: String) -> some View {
        let color: Color = level == "High" ? .green : level == "Good" ? .mint : level == "Moderate" ? .orange : .red
        return Text(level)
            .font(.caption.bold())
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }

    private func ageRow(age: String, label: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 2) {
                Text(label).font(.caption.bold()).foregroundStyle(.secondary)
                Text(age).font(.caption2).foregroundStyle(.tertiary)
            }
            .frame(width: 60, alignment: .leading)
            Text(detail).font(.footnote).lineSpacing(3)
        }
    }
}

// MARK: - Behind The Build

struct BehindTheBuildView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // The Journey
                sectionHeader("A beekeeper by heart", icon: "heart.fill", color: .red)
                infoCard(color: .red) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("I am a fourth generation beekeeper. My great grandparents started their journey in a small shed in Donnersdorf.")
                            .font(.body)
                        
                        Text("While a lot has changed since then, the Varroa Mite remains a pressing and ever evolving challenge for our colonies today.")
                            .font(.body)
                    }
                }
                
                // Machine Learning
                sectionHeader("Custom Machine Learning", icon: "sparkles", color: .indigo)
                infoCard(color: .indigo) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("The core of BeeWise is powered by a custom object detection model built entirely with **Create ML**.")
                            .font(.body)
                        
                        Text("To train the model to accurately recognize bees on varied frames, I utilised the open-source dataset **Honey Bee Detection Model** by Matt Nudi from Roboflow Universe.")
                            .font(.body)
                    }
                }
                
                linkRow(title: "Dataset source: Roboflow Universe", url: "https://universe.roboflow.com/matt-nudi/honey-bee-detection-model-zgjnb")

                // Graphics & Animation
                sectionHeader("Graphics & Animation", icon: "paintpalette.fill", color: .orange)
                infoCard(color: .orange) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("All graphics, including the bee characters and UI assets, were designed and illustrated from scratch using **Pixelmator Pro**.")
                            .font(.body)
                        
                        Text("To bring the application to life, the talking and flying animations were entirely rigged and animated by myself utilizing **Apple Motion**.")
                            .font(.body)
                    }
                }
                
                linkRow(title: "All Assets, Pixelmator Pro & Apple Motion Files", url: "https://drive.google.com/drive/folders/1ERKtx6p3Dbc2SYmnpQ_2Jd8zCpwoih4O?usp=sharing")
                
                HStack{
                    Spacer()
                    Image("JanBeekeeper")
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.top, 10)
                        .frame(width: 250)
                    Spacer()

                }
                
            }
            .padding()
            .padding(.bottom, 100)
        }
        .navigationTitle("Behind the Build")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Shared Helpers

@ViewBuilder
private func infoCard<Content: View>(color: Color, @ViewBuilder content: () -> Content) -> some View {
    content()
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.07), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(color.opacity(0.15), lineWidth: 1))
}

@ViewBuilder
private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
    if icon.hasPrefix("bee_") {
        Label {
            Text(title)
        } icon: {
            Image(icon).resizable().scaledToFit().frame(width: 24, height: 24)
        }
        .font(.title3.bold())
        .foregroundStyle(color)
    } else {
        Label(title, systemImage: icon)
            .font(.title3.bold())
            .foregroundStyle(color)
    }
}

@ViewBuilder
private func bullet(_ text: String) -> some View {
    HStack(alignment: .top, spacing: 8) {
        Text("•").foregroundStyle(.secondary)
        Text(text).font(.body)
    }
}

@ViewBuilder
private func linkRow(title: String, url: String) -> some View {
    if let dest = URL(string: url) {
        Link(destination: dest) {
            HStack(spacing: 10) {
                Image(systemName: "link.circle.fill").foregroundStyle(.blue)
                Text(title).font(.footnote).foregroundStyle(.blue).multilineTextAlignment(.leading)
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
}

@ViewBuilder
private func mappingRow(paper: String, app: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
        Label(paper, systemImage: "doc.text").font(.caption.bold()).foregroundStyle(.secondary)
        Label(app, systemImage: "arrow.right").font(.caption).foregroundStyle(.primary)
    }
}
