//
//  HiveView.swift
//  BeeWise
//
//  Created by Steinhauer, Jan on 06.02.26.
//

import SwiftUI

// MARK: - Main HiveView

struct HiveView: View {
    @StateObject private var viewModel = HiveViewModel()
    @State private var showAddSheet  = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.hives.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("My Hives")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.beeGold)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddHiveSheet { newHive in
                    viewModel.addHive(newHive)
                }
            }
        }
    }

    // MARK: Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Image("BeeHive")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 220)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 8)

            Text("No Hives Yet")
                .font(.title2.bold())
            Text("Tap + to add your first bee hive.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button { showAddSheet = true } label: {
                Label("Add Hive", systemImage: "plus")
                    .foregroundStyle(.white)
                    .font(.headline)
                    .padding(.horizontal, 28).padding(.vertical, 12)
                    .background(Color.beeGold, in: Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: List

    private var list: some View {
        List {
            ForEach($viewModel.hives) { $hive in
                NavigationLink {
                    HiveDetailView(hive: $hive) { updatedHive in
                        viewModel.updateHive(updatedHive)
                    }
                } label: {
                    HiveRow(hive: hive)
                }
            }
            .onDelete { idx in
                viewModel.deleteHive(at: idx)
            }
        }
    }



// MARK: - Hive Row

struct HiveRow: View {
    let hive: Hive
    var body: some View {
        HStack(spacing: 14) {
            Image("BeeHive")
                .resizable()
                .scaledToFill()
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(hive.name)
                    .font(.headline)
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image("bee_gray").resizable().scaledToFit().frame(width: 14, height: 14).foregroundStyle(.secondary)
                        Text(hive.breed.rawValue)
                    }
                    .font(.caption).foregroundStyle(.secondary)
                    Label("Queen \(hive.queenAgeYears)yr", systemImage: "crown.fill")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Text("Last: \(hive.lastTreatment.rawValue)")
                    .font(.caption).foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Hive Detail View

struct HiveDetailView: View {
    @Binding var hive: Hive
    var onSave: (Hive) -> Void
    
    @State private var isTalking: Bool  = true
    @State private var isFlapping: Bool = false
    @State private var showEditSheet = false
    @State private var selectedDetection: DetectionRecord? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image("BeeHive")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 8)
                    .padding(.top, 16)

                VStack(spacing: 12) {
                    infoRow(icon: "bee_yellow",      color: .orange, label: "Breed",         value: hive.breed.rawValue) { showEditSheet = true }
                    infoRow(icon: "crown.fill",      color: .yellow, label: "Queen Age",      value: "\(hive.queenAgeYears) year\(hive.queenAgeYears == 1 ? "" : "s")") { showEditSheet = true }
                    infoRow(icon: "cross.case.fill", color: .green,  label: "Last Treatment", value: hive.lastTreatment.rawValue) { showEditSheet = true }

                    if !hive.notes.isEmpty {
                        Button { showEditSheet = true } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Label("Notes", systemImage: "note.text")
                                        .font(.caption.bold()).foregroundStyle(.secondary)
                                    Spacer()
                                    Image(systemName: "square.and.pencil")
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(.tertiary)
                                }
                                Text(hive.notes).font(.body).foregroundStyle(.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)

                analyzeCard
                    .padding(.horizontal)
                    
                if !hive.pastDetections.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Past Detections")
                            .font(.title2.bold())
                            .padding(.horizontal)
                        
                        ForEach(hive.pastDetections) { record in
                            Button {
                                selectedDetection = record
                            } label: {
                                DetectionRow(record: record)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 120)
                } else {
                    Spacer().frame(height: 120)
                }
            }
        }
        .navigationTitle(hive.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditHiveSheet(hive: $hive) { updatedHive in
                hive = updatedHive
                onSave(updatedHive)
            }
        }
        .sheet(item: $selectedDetection) { record in
            PastDetectionDetailSheet(record: record)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isFlapping = true
            }
        }
    }


    // MARK: Analyze Card

    private var analyzeCard: some View {
        NavigationLink(destination: HiveDetectionView(hive: $hive, onSave: { updatedHive in
            hive = updatedHive
            onSave(updatedHive)
        })) {
            HStack(spacing: 20) {
                // Animated bee
                LogoAnimation(isTalking: $isTalking, isFlapping: $isFlapping)
                    .frame(width: 100, height: 100)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Ready to detect mites?")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("Tap to start analyzing now")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Label("Analyze Now", systemImage: "magnifyingglass.circle.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.beeGold)
                }
                Spacer()
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.beeGold)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .padding(.bottom, 12)
            .background {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: -6)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Info Row

    private func infoRow(icon: String, color: Color, label: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    if icon.hasPrefix("bee_") {
                        Image(icon).resizable().scaledToFit().frame(width: 20, height: 20)
                    } else {
                        Image(systemName: icon).foregroundStyle(color).font(.system(size: 18))
                    }
                }
                Text(label).font(.subheadline).foregroundStyle(.secondary)
                Spacer()
                Text(value).font(.subheadline.bold()).foregroundStyle(.primary)
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Hive Sheet

struct AddHiveSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (Hive) -> Void

    @State private var name: String                  = ""
    @State private var breed: BeeBreed               = .carniolan
    @State private var queenAgeYears: Int            = 1
    @State private var lastTreatment: TreatmentMethod = .oxalicAcid
    @State private var notes: String                 = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("General") {
                    TextField("Hive Name", text: $name)
                }
                Section("Colony") {
                    Picker("Bee Breed", selection: $breed) {
                        ForEach(BeeBreed.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    Stepper("Queen Age: \(queenAgeYears) year\(queenAgeYears == 1 ? "" : "s")",
                            value: $queenAgeYears, in: 0...10)
                }
                Section("Treatment") {
                    Picker("Last Treatment", selection: $lastTreatment) {
                        ForEach(TreatmentMethod.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                }
                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Hive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading)  { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onAdd(Hive(name: name, breed: breed,
                                   queenAgeYears: queenAgeYears,
                                   lastTreatment: lastTreatment,
                                   notes: notes))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - Edit Hive Sheet

struct EditHiveSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var hive: Hive
    var onSave: (Hive) -> Void

    @State private var name: String
    @State private var breed: BeeBreed
    @State private var queenAgeYears: Int
    @State private var lastTreatment: TreatmentMethod
    @State private var notes: String

    init(hive: Binding<Hive>, onSave: @escaping (Hive) -> Void) {
        self._hive = hive
        self.onSave = onSave
        self._name = State(initialValue: hive.wrappedValue.name)
        self._breed = State(initialValue: hive.wrappedValue.breed)
        self._queenAgeYears = State(initialValue: hive.wrappedValue.queenAgeYears)
        self._lastTreatment = State(initialValue: hive.wrappedValue.lastTreatment)
        self._notes = State(initialValue: hive.wrappedValue.notes)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("General") {
                    TextField("Hive Name", text: $name)
                }
                Section("Colony") {
                    Picker("Bee Breed", selection: $breed) {
                        ForEach(BeeBreed.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    Stepper("Queen Age: \(queenAgeYears) year\(queenAgeYears == 1 ? "" : "s")",
                            value: $queenAgeYears, in: 0...10)
                }
                Section("Treatment") {
                    Picker("Last Treatment", selection: $lastTreatment) {
                        ForEach(TreatmentMethod.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                }
                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Hive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading)  { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        hive.name = name
                        hive.breed = breed
                        hive.queenAgeYears = queenAgeYears
                        hive.lastTreatment = lastTreatment
                        hive.notes = notes
                        onSave(hive)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - Detection Row

    struct DetectionRow: View {
        let record: DetectionRecord
        
        var body: some View {
            HStack {
                let (icon, color) = getStatusUI(status: record.result.status)
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(record.date, style: .date)
                        .font(.headline)
                    Text("Bees: \(record.bees) | Mites: \(record.mites)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        
        private func getStatusUI(status: AnalysisStatus) -> (String, Color) {
            switch status {
            case .safe: return ("checkmark.shield.fill", .green)
            case .warning: return ("exclamationmark.triangle.fill", .orange)
            case .danger: return ("xmark.octagon.fill", .red)
            }
        }
    }
}



// MARK: - Past Detection Detail Sheet

struct PastDetectionDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let record: DetectionRecord
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Status Header
                    let (icon, color) = getStatusUI(status: record.result.status)
                    VStack(spacing: 8) {
                        Image(systemName: icon)
                            .font(.system(size: 48))
                            .foregroundStyle(color)
                        
                        Text(record.result.status.rawValue)
                            .font(.largeTitle.bold())
                            .foregroundStyle(color)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                    
                    // Raw Counts
                    HStack(spacing: 30) {
                        VStack {
                            Text("\(record.bees)").font(.title.bold())
                            Text("Total Bees").font(.caption).foregroundStyle(.secondary)
                        }
                        VStack {
                            Text("\(record.mites)").font(.title.bold())
                            Text("Total Mites").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    
                    // Recommendation
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Recommendation", systemImage: "stethoscope")
                            .font(.headline)
                        Text(record.result.recommendation)
                            .font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                    
                    // Scientific Context
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Scientific Context", systemImage: "book.fill")
                            .font(.headline)
                        Text(record.result.scientificContext)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .navigationTitle("Detection Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func getStatusUI(status: AnalysisStatus) -> (String, Color) {
        switch status {
        case .safe: return ("checkmark.shield.fill", .green)
        case .warning: return ("exclamationmark.triangle.fill", .orange)
        case .danger: return ("xmark.octagon.fill", .red)
        }
    }
}
