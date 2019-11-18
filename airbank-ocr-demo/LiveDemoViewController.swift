//
//  LiveDemoViewController.swift
//  airbank-ocr-demo
//
//  Created by Marek Přidal on 18/11/2019.
//  Copyright © 2019 Marek Přidal. All rights reserved.
//

import AVFoundation
import UIKit
import Vision

final class LiveDemoViewController: UIViewController {
    private let session = AVCaptureSession()

    private lazy var imageView: UIImageView = {
        .init()
    }()
    
    private lazy var textDetectionRequest: VNRecognizeTextRequest = {
        let request = VNRecognizeTextRequest(completionHandler: self.handleDetectedText)
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["cs_CZ", "en_GB"]
        return request
    }()
    
    private lazy var previewView: PreviewView = {
        .init()
    }()
    
    private lazy var cameraOutput: UIView = {
        .init()
    }()

    private let captureQueue = DispatchQueue(label: "captureQueue")

    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let previewView = AVCaptureVideoPreviewLayer(session: self.session)
        return previewView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        startLiveVideo()
        setupLayout()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = cameraOutput.bounds;
    }
    
    private func setupLayout() {
        cameraOutput.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cameraOutput)
        cameraOutput.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        cameraOutput.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        cameraOutput.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        cameraOutput.topAnchor.constraint(equalTo: view.topAnchor).isActive = true

        previewView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewView)
        previewView.leadingAnchor.constraint(equalTo: cameraOutput.leadingAnchor).isActive = true
        previewView.trailingAnchor.constraint(equalTo: cameraOutput.trailingAnchor).isActive = true
        previewView.bottomAnchor.constraint(equalTo: cameraOutput.bottomAnchor).isActive = true
        previewView.topAnchor.constraint(equalTo: cameraOutput.topAnchor).isActive = true
    }

    private func startLiveVideo() {
        cameraOutput.layer.addSublayer(previewLayer)

        guard let camera =  AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: .unspecified) else { return }
        let input = try! AVCaptureDeviceInput(device: camera)
        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: captureQueue)
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        session.addOutput(output)

        session.commitConfiguration()
        
        // make sure we are in portrait mode
        let conn = output.connection(with: .video)
        conn?.videoOrientation = .portrait
        
        session.startRunning()
    }

    
    private func process(imageBuffer: CVImageBuffer, sampleBuffer: CMSampleBuffer) {
        var requestOptions:[VNImageOption: Any] = [:]
        
        if let cameraIntrinsicData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
          requestOptions = [.cameraIntrinsics: cameraIntrinsicData]
        }
        
        // for orientation see kCGImagePropertyOrientation
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: imageBuffer, orientation: .up, options: requestOptions)
        do {
          try imageRequestHandler.perform([textDetectionRequest])
        } catch {
          print(error)
        }
    }
    
    private func handleDetectedText(request: VNRequest?, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        guard let results = request?.results, results.count > 0 else {
            print("No text was found.")
            return
        }
        
        drawVisionRequestResults((results as? [VNRecognizedTextObservation]) ?? [])
        
        for result in results {
            if let observation = result as? VNRecognizedTextObservation {
                print(observation)
            }
        }
    }
    
    private func drawVisionRequestResults(_ results: [VNRecognizedTextObservation]) {
        DispatchQueue.main.async { [weak self] in
            self?.previewView.removeMask()
            for textObservation in results {
                self?.previewView.drawRect(textObservation: textObservation)
            }
        }
    }
}

extension LiveDemoViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        connection.videoOrientation = .portrait
        process(imageBuffer: imageBuffer, sampleBuffer: sampleBuffer)
    }
}
