//
//  SmartCaptureCameraView.swift
//  BeeWiseSSC
//
//  Smart auto-capture for honeycomb frames. Uses Vision's rectangle
//  detector to spot a frame in view, CoreMotion to confirm the device
//  is steady, and AVCapture's adjusting flags to wait for focus before
//  firing the shutter automatically. Plays a system sound and flashes
//  the screen on success so the beekeeper knows hands-free capture worked.
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
    case holdSteady
    case focusing
    case captured

    var message: String {
        switch self {
        case .searching: return "Hold a frame in front of the camera"
        case .holdSteady: return "Hold steady…"
        case .focusing: return "Focusing…"
        case .captured: return "Captured!"
        }
    }

    var icon: String {
        switch self {
        case .searching: return "viewfinder"
        case .holdSteady: return "hand.raised.fill"
        case .focusing: return "scope"
        case .captured: return "checkmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .searching: return .blue
        case .holdSteady: return .orange
        case .focusing: return .purple
        case .captured: return .green
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
                // Flash animation
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
    private var latestRotationRate: Double = 0  // rad/s magnitude

    // Stability tracking
    private var rectangleSeenSince: Date?
    private var lastCaptureAt: Date?
    private let requiredStableSeconds: TimeInterval = 0.6
    private let captureCooldown: TimeInterval = 2.5
    private let motionThreshold: Double = 0.35  // rad/s — anything above means moving

    private var isCapturing = false
    private var lastSampleAnalyzedAt: Date = .distantPast
    private let analysisInterval: TimeInterval = 0.15

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

        // Continuous autofocus & exposure so we can react to "adjusting" flags.
        if (try? device.lockForConfiguration()) != nil {
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            device.unlockForConfiguration()
        }

        // Live frame stream for Vision
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
            self.latestRotationRate = mag
        }
    }

    // MARK: - Live frame analysis

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard !isCapturing else { return }

        let now = Date()
        if now.timeIntervalSince(lastSampleAnalyzedAt) < analysisInterval { return }
        lastSampleAnalyzedAt = now

        if let last = lastCaptureAt, now.timeIntervalSince(last) < captureCooldown {
            return
        }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNDetectRectanglesRequest { [weak self] req, _ in
            guard let self = self else { return }
            let rects = (req.results as? [VNRectangleObservation]) ?? []
            // Honeycomb frame: roughly rectangular, taking up a meaningful chunk of the view.
            let bigEnough = rects.first { obs in
                let area = obs.boundingBox.width * obs.boundingBox.height
                return area > 0.25
            }
            self.handleDetection(foundFrame: bigEnough != nil)
        }
        request.minimumAspectRatio = 0.4
        request.maximumAspectRatio = 1.0
        request.minimumSize = 0.4
        request.minimumConfidence = 0.6
        request.maximumObservations = 4

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
        try? handler.perform([request])
    }

    private func handleDetection(foundFrame: Bool) {
        guard !isCapturing else { return }

        if !foundFrame {
            rectangleSeenSince = nil
            statusHandler?(.searching)
            return
        }

        if rectangleSeenSince == nil {
            rectangleSeenSince = Date()
        }

        // Motion check
        if latestRotationRate > motionThreshold {
            rectangleSeenSince = Date()  // reset stability clock
            statusHandler?(.holdSteady)
            return
        }

        // Focus check
        if let device = deviceInput?.device, device.isAdjustingFocus || device.isAdjustingExposure {
            statusHandler?(.focusing)
            return
        }

        let stableFor = Date().timeIntervalSince(rectangleSeenSince ?? Date())
        if stableFor >= requiredStableSeconds {
            triggerCapture()
        } else {
            statusHandler?(.holdSteady)
        }
    }

    // MARK: - Capture

    private func triggerCapture() {
        guard !isCapturing else { return }
        isCapturing = true
        lastCaptureAt = Date()
        rectangleSeenSince = nil

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

        // Loud shutter sound (system shutter; respects silent switch on some devices).
        AudioServicesPlaySystemSound(1108)

        statusHandler?(.captured)
        captureHandler?(image)

        // Quickly revert status so the next capture cycle starts fresh.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.statusHandler?(.searching)
        }
    }
}
