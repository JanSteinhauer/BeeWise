//
//  SmartCaptureCameraView.swift
//  BeeWiseSSC
//
//  Smart auto-capture for honeycomb frames. Combines several cues so that
//  any one of them is enough to trigger a shot:
//   - Vision rectangle detector (frame edges)
//   - Vision classifier (bee/honeycomb/hive/insect labels)
//   - Attention-based saliency (something worth looking at is centered & large)
//  CoreMotion confirms the device isn't being actively swept around, and
//  AVCapture's adjusting flags wait for focus before firing the shutter.
//

import SwiftUI
import AVFoundation
import Vision
import CoreMotion
import AudioToolbox
import UIKit

struct SmartCaptureCameraView: View {
    @Environment(\.dismiss) private var dismiss
    var onCapture: (UIImage) -> Void

    @State private var status: SmartCaptureStatus = .searching
    @State private var flashOpacity: Double = 0
    @State private var capturedThisSession: Int = 0

    var body: some View {
        ZStack {
            SmartCaptureCameraContainer(
                status: $status,
                flashOpacity: $flashOpacity,
                onCapture: { image in
                    capturedThisSession += 1
                    onCapture(image)
                }
            )
            .ignoresSafeArea()

            // White flash overlay on capture
            Color.white
                .opacity(flashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .padding(12)
                            .background(.ultraThinMaterial, in: Circle())
                            .foregroundStyle(.primary)
                    }
                    Spacer()
                    if capturedThisSession > 0 {
                        Text("\(capturedThisSession) captured")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                }
                .padding()

                Spacer()

                statusBanner
                    .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var statusBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: status.icon)
                .font(.headline)
            Text(status.message)
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .foregroundStyle(.white)
        .background(status.color.opacity(0.85), in: Capsule())
        .shadow(radius: 4)
        .animation(.easeInOut(duration: 0.2), value: status)
    }
}

enum SmartCaptureStatus: Equatable {
    case searching
    case holdSteadyFrame
    case holdSteadyBee
    case holdSteadyComb
    case focusing
    case captured

    var message: String {
        switch self {
        case .searching:        return "Point at a frame, bees, or comb"
        case .holdSteadyFrame:  return "Frame detected — hold steady"
        case .holdSteadyBee:    return "Bees detected — hold steady"
        case .holdSteadyComb:   return "Comb detected — hold steady"
        case .focusing:         return "Focusing…"
        case .captured:         return "Captured!"
        }
    }

    var icon: String {
        switch self {
        case .searching:       return "viewfinder"
        case .holdSteadyFrame: return "rectangle.dashed"
        case .holdSteadyBee:   return "ant.fill"
        case .holdSteadyComb:  return "hexagon.fill"
        case .focusing:        return "scope"
        case .captured:        return "checkmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .searching:       return .blue
        case .holdSteadyFrame: return .orange
        case .holdSteadyBee:   return .orange
        case .holdSteadyComb:  return .orange
        case .focusing:        return .purple
        case .captured:        return .green
        }
    }
}

// MARK: - UIViewControllerRepresentable bridge

private struct SmartCaptureCameraContainer: UIViewControllerRepresentable {
    @Binding var status: SmartCaptureStatus
    @Binding var flashOpacity: Double
    var onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> SmartCaptureViewController {
        let vc = SmartCaptureViewController()
        vc.statusHandler = { newStatus in
            DispatchQueue.main.async {
                self.status = newStatus
            }
        }
        vc.captureHandler = { image in
            DispatchQueue.main.async {
                withAnimation(.easeOut(duration: 0.08)) {
                    self.flashOpacity = 0.9
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    withAnimation(.easeIn(duration: 0.25)) {
                        self.flashOpacity = 0
                    }
                }
                self.onCapture(image)
            }
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: SmartCaptureViewController, context: Context) {}
}

// MARK: - Cue source for status messaging

private enum CaptureCue {
    case frame
    case bee
    case comb
}

// MARK: - View controller doing the actual work

final class SmartCaptureViewController: UIViewController,
                                        AVCaptureVideoDataOutputSampleBufferDelegate,
                                        AVCapturePhotoCaptureDelegate {

    var statusHandler: ((SmartCaptureStatus) -> Void)?
    var captureHandler: ((UIImage) -> Void)?

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "beewise.smartcapture.session")
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var deviceInput: AVCaptureDeviceInput?

    private let motionManager = CMMotionManager()
    private var rotationSamples: [Double] = []  // rolling buffer of recent rotation magnitudes
    private let motionBufferSize = 10

    // Stability tracking
    private var subjectSeenSince: Date?
    private var lastCaptureAt: Date?
    private let requiredStableSeconds: TimeInterval = 0.35
    private let captureCooldown: TimeInterval = 1.2
    private let motionThreshold: Double = 0.6           // rad/s — per-sample
    private let motionTolerantFraction: Double = 0.3    // up to 30% of recent samples can spike

    private var isCapturing = false

    // Rectangle cadence
    private var lastRectAnalyzedAt: Date = .distantPast
    private let rectInterval: TimeInterval = 0.15

    // ML / saliency cadence + cache (runs less often, results live briefly)
    private var lastMLAnalyzedAt: Date = .distantPast
    private let mlInterval: TimeInterval = 0.4
    private let mlResultTTL: TimeInterval = 1.0
    private var mlInFlight = false
    private let mlQueue = DispatchQueue(label: "beewise.smartcapture.ml", qos: .userInitiated)

    private var lastBeeSeenAt: Date?
    private var lastCombSeenAt: Date?
    private var lastFrameSeenAt: Date?
    private let frameResultTTL: TimeInterval = 0.5  // rectangle cue is cheap, expire faster

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
        startMotionUpdates()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sessionQueue.async { [weak self] in
            guard let self = self, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sessionQueue.async { [weak self] in
            guard let self = self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
        motionManager.stopDeviceMotionUpdates()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        if let connection = previewLayer?.connection, connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
    }

    // MARK: - Setup

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)
        deviceInput = input

        if (try? device.lockForConfiguration()) != nil {
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            device.unlockForConfiguration()
        }

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "beewise.smartcapture.video"))
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            if let conn = videoOutput.connection(with: .video), conn.isVideoOrientationSupported {
                conn.videoOrientation = .portrait
            }
        }

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }

        session.commitConfiguration()

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let layer = AVCaptureVideoPreviewLayer(session: self.session)
            layer.videoGravity = .resizeAspectFill
            layer.frame = self.view.bounds
            self.view.layer.insertSublayer(layer, at: 0)
            self.previewLayer = layer
        }
    }

    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 30.0
        motionManager.startDeviceMotionUpdates(to: OperationQueue()) { [weak self] motion, _ in
            guard let self = self, let m = motion else { return }
            let r = m.rotationRate
            let mag = sqrt(r.x * r.x + r.y * r.y + r.z * r.z)
            self.appendRotationSample(mag)
        }
    }

    private func appendRotationSample(_ value: Double) {
        rotationSamples.append(value)
        if rotationSamples.count > motionBufferSize {
            rotationSamples.removeFirst(rotationSamples.count - motionBufferSize)
        }
    }

    /// True when the device is being actively swept around. A single twitch is tolerated;
    /// sustained motion across the rolling buffer is not.
    private var isMovingTooMuch: Bool {
        guard !rotationSamples.isEmpty else { return false }
        let spikes = rotationSamples.filter { $0 > motionThreshold }.count
        let fraction = Double(spikes) / Double(rotationSamples.count)
        return fraction > motionTolerantFraction
    }

    // MARK: - Live frame analysis

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard !isCapturing else { return }

        let now = Date()
        if let last = lastCaptureAt, now.timeIntervalSince(last) < captureCooldown {
            return
        }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Cheap rectangle pass — every rectInterval
        if now.timeIntervalSince(lastRectAnalyzedAt) >= rectInterval {
            lastRectAnalyzedAt = now
            runRectangleRequest(on: pixelBuffer)
        }

        // Heavier classifier + saliency pass — every mlInterval, off the video queue
        if !mlInFlight, now.timeIntervalSince(lastMLAnalyzedAt) >= mlInterval {
            lastMLAnalyzedAt = now
            mlInFlight = true
            // Retain the pixel buffer for use on another queue.
            let retainedBuffer = pixelBuffer
            mlQueue.async { [weak self] in
                self?.runMLAndSaliency(on: retainedBuffer)
                self?.mlInFlight = false
            }
        }

        evaluateCaptureDecision()
    }

    private func runRectangleRequest(on pixelBuffer: CVPixelBuffer) {
        let request = VNDetectRectanglesRequest { [weak self] req, _ in
            guard let self = self else { return }
            let rects = (req.results as? [VNRectangleObservation]) ?? []
            let bigEnough = rects.first { obs in
                let area = obs.boundingBox.width * obs.boundingBox.height
                return area > 0.15
            }
            if bigEnough != nil {
                self.lastFrameSeenAt = Date()
            }
        }
        request.minimumAspectRatio = 0.4
        request.maximumAspectRatio = 1.0
        request.minimumSize = 0.25
        request.minimumConfidence = 0.5
        request.maximumObservations = 4

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
        try? handler.perform([request])
    }

    private func runMLAndSaliency(on pixelBuffer: CVPixelBuffer) {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])

        // Classifier — bee / honeycomb / hive / insect
        let classify = VNClassifyImageRequest { [weak self] req, _ in
            guard let self = self,
                  let results = req.results as? [VNClassificationObservation] else { return }
            let beeIDs = ["bee", "insect", "invertebrate", "arthropod"]
            let combIDs = ["honeycomb", "hive", "comb"]
            for obs in results {
                guard obs.confidence > 0.05 else { continue }
                let id = obs.identifier.lowercased()
                if beeIDs.contains(where: { id.contains($0) }) {
                    self.lastBeeSeenAt = Date()
                }
                if combIDs.contains(where: { id.contains($0) }) {
                    self.lastCombSeenAt = Date()
                }
            }
        }

        // Saliency — if the salient region is large and reasonably centered, treat it
        // as a "subject in view" cue (catches comb texture even when the rectangle
        // detector misses ragged edges).
        let saliency = VNGenerateAttentionBasedSaliencyImageRequest { [weak self] req, _ in
            guard let self = self,
                  let result = (req.results as? [VNSaliencyImageObservation])?.first,
                  let salient = result.salientObjects?.first else { return }
            let box = salient.boundingBox
            let area = box.width * box.height
            let cx = box.midX
            let cy = box.midY
            let centered = abs(cx - 0.5) < 0.3 && abs(cy - 0.5) < 0.35
            if area > 0.18 && centered {
                self.lastCombSeenAt = Date()
            }
        }

        try? handler.perform([classify, saliency])
    }

    private func evaluateCaptureDecision() {
        guard !isCapturing else { return }

        let cue = freshestCue()

        guard let cue = cue else {
            subjectSeenSince = nil
            statusHandler?(.searching)
            return
        }

        if subjectSeenSince == nil {
            subjectSeenSince = Date()
        }

        if isMovingTooMuch {
            statusHandler?(holdStatus(for: cue))
            return
        }

        if let device = deviceInput?.device, device.isAdjustingFocus || device.isAdjustingExposure {
            statusHandler?(.focusing)
            return
        }

        let stableFor = Date().timeIntervalSince(subjectSeenSince ?? Date())
        if stableFor >= requiredStableSeconds {
            triggerCapture()
        } else {
            statusHandler?(holdStatus(for: cue))
        }
    }

    /// Picks the most recently observed cue across rectangle / bee / comb, if any
    /// is still within its TTL.
    private func freshestCue() -> CaptureCue? {
        let now = Date()
        var best: (CaptureCue, Date)? = nil

        if let t = lastFrameSeenAt, now.timeIntervalSince(t) < frameResultTTL {
            best = (.frame, t)
        }
        if let t = lastBeeSeenAt, now.timeIntervalSince(t) < mlResultTTL {
            if best == nil || t > best!.1 { best = (.bee, t) }
        }
        if let t = lastCombSeenAt, now.timeIntervalSince(t) < mlResultTTL {
            if best == nil || t > best!.1 { best = (.comb, t) }
        }
        return best?.0
    }

    private func holdStatus(for cue: CaptureCue) -> SmartCaptureStatus {
        switch cue {
        case .frame: return .holdSteadyFrame
        case .bee:   return .holdSteadyBee
        case .comb:  return .holdSteadyComb
        }
    }

    // MARK: - Capture

    private func triggerCapture() {
        guard !isCapturing else { return }
        isCapturing = true
        lastCaptureAt = Date()
        subjectSeenSince = nil
        // Clear cue cache so the next decision starts fresh after the cooldown.
        lastFrameSeenAt = nil
        lastBeeSeenAt = nil
        lastCombSeenAt = nil

        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        defer { isCapturing = false }

        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            return
        }

        AudioServicesPlaySystemSound(1108)

        statusHandler?(.captured)
        captureHandler?(image)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.statusHandler?(.searching)
        }
    }
}
