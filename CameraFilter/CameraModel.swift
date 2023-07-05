//
//  CameraModel.swift
//  CameraFilter
//
//  Created by Іван Богоносюк on 05.07.2023.
//

import SwiftUI
import Foundation
import AVFoundation
import CoreImage.CIFilterBuiltins

class CameraModel: NSObject, ObservableObject {
    @Published var image: UIImage?

    private let session = AVCaptureSession()
    private let context = CIContext()

    private let filters: [CIFilter] = [.sepiaTone(), .photoEffectNoir(), .colorInvert()]
    private var currentFilter: CIFilter

    private var output = AVCapturePhotoOutput()
    private var videoOutput = AVCaptureVideoDataOutput()

    override init() {
        currentFilter = filters[0]
        super.init()
    }

    func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                setupSession()
                return
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { [weak self] status in
                    if status {
                        self?.setupSession()
                    }
                }
            default:
                return
        }
    }

    func changeFilter() {
        guard let currentIndex = filters.firstIndex(of: currentFilter) else {
            currentFilter = filters[0]
            return
        }

        let nextIndex = (currentIndex + 1) % filters.count

        currentFilter = filters[nextIndex]
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let image = CIImage(cvPixelBuffer: pixelBuffer)

        currentFilter.setValue(image, forKey: kCIInputImageKey)

        guard let outputImage = currentFilter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent)
        else { return }

        DispatchQueue.main.async { [weak self] in
            self?.image = UIImage(cgImage: cgImage)
        }
    }
}

// MARK: - Private
private extension CameraModel {
    func setupSession() {
        session.beginConfiguration()

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device)
        else { return }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        if let connection = videoOutput.connection(with: .video) {
            connection.videoOrientation = .portrait
        }

        session.commitConfiguration()

        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.session.startRunning()
        }
    }
}
