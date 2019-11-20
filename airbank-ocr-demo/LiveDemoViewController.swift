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
    
    private lazy var surnameLabel: UILabel = {
        .init()
    }()
    
    private lazy var givenNameLabel: UILabel = {
        .init()
    }()
    
    private lazy var documentNoLabel: UILabel = {
        .init()
    }()
    
    private lazy var dateOfBirthLabel: UILabel = {
        .init()
    }()
    
    private lazy var placeOfBirthLabel: UILabel = {
        .init()
    }()
    
    private lazy var nationalityLabel: UILabel = {
        .init()
    }()
    
    private lazy var dateOfIssueLabel: UILabel = {
        .init()
    }()
    
    private lazy var dateOfExpiryLabel: UILabel = {
        .init()
    }()
    
    private lazy var sexLabel: UILabel = {
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
        setupNavigationBar()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = cameraOutput.bounds;
    }
    
    private func setupLayout() {
        view.backgroundColor = .systemBackground
        
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
        
        let stackBackgroundView = UIView()
        stackBackgroundView.backgroundColor = .white
        view.addSubview(stackBackgroundView)
        stackBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        stackBackgroundView.leadingAnchor.constraint(equalToSystemSpacingAfter: view.leadingAnchor, multiplier: 0).isActive = true
        stackBackgroundView.trailingAnchor.constraint(equalToSystemSpacingAfter: view.trailingAnchor, multiplier: 0).isActive = true
        stackBackgroundView.bottomAnchor.constraint(equalToSystemSpacingBelow: view.safeAreaLayoutGuide.bottomAnchor, multiplier: 0).isActive = true
        stackBackgroundView.topAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: view.safeAreaLayoutGuide.topAnchor, multiplier: 0).isActive = true
        
        
        let stackView = UIStackView(arrangedSubviews: [surnameLabel, givenNameLabel, documentNoLabel, dateOfBirthLabel, placeOfBirthLabel, nationalityLabel, dateOfIssueLabel, dateOfExpiryLabel, sexLabel])
        stackView.axis = .vertical
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.leadingAnchor.constraint(equalTo: stackBackgroundView.leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: stackBackgroundView.trailingAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: stackBackgroundView.bottomAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: stackBackgroundView.topAnchor).isActive = true
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

        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: imageBuffer, orientation: .up, options: requestOptions)
        do {
          try imageRequestHandler.perform([textDetectionRequest])
        } catch {
          print(error)
        }
    }
    
    private func handleDetectedText(request: VNRequest?, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.previewView.removeMask()
        }
        if let error = error {
            print(error.localizedDescription)
            return
        }

        guard let results = request?.results as? [VNRecognizedTextObservation], results.count > 0 else {
            print("No text was found.")
            return
        }

        drawVisionRequestResults(transformToRecognizedKeyValue(recognizedTextObservations: results))
    }
    
    private func drawVisionRequestResults(_ results: [RecognizedKeyValue]) {
        DispatchQueue.main.async { [weak self] in
            for textObservation in results {
                self?.previewView.drawRect(textObservation: textObservation.keyTextObservation)
                self?.fillLabel(for: textObservation)
                if let valueTextObservation = textObservation.valueTextObservation {
                    self?.previewView.drawRect(textObservation: valueTextObservation)
                }
            }
        }
    }
    
    private func setupNavigationBar() {
        let imageButton = UIBarButtonItem(title: "Hide video", style: .plain, target: self, action: #selector(toggleImageViewHidden))
        navigationItem.rightBarButtonItem = imageButton
    }
    
    @objc
    private func toggleImageViewHidden() {
        cameraOutput.isHidden.toggle()
        navigationItem.rightBarButtonItem?.title = cameraOutput.isHidden ? "Show video" : "Hide video"
    }
    
    private func transformToRecognizedKeyValue(recognizedTextObservations: [VNRecognizedTextObservation]) -> [RecognizedKeyValue] {
        var values: [VNRecognizedTextObservation] = recognizedTextObservations
        
        RecognizedKeyValue.DocumentElement.allCases.map { $0.rawValue }.forEach { (key) in
            values = values.filter({ !($0.topCandidates(1).first?.string.contains(key) ?? true) })
        }
        
        var result: [RecognizedKeyValue] = []
        
        RecognizedKeyValue.DocumentElement.allCases.map { $0.rawValue }.forEach { (key) in
            guard let recognizedTextObservation = recognizedTextObservations.first(where: { $0.topCandidates(10).contains(where: { $0.string.contains(key) }) }), let textObservation = recognizedTextObservation.topCandidates(10).first(where: { $0.string.contains(key) }) else { return }
            print(textObservation.string)
            var keyValue = RecognizedKeyValue(key: key, keyTextObservation: recognizedTextObservation)
            switch keyValue.alignment {
            case .horizontal:
                let value = values.filter({ $0.topLeft.x >= keyValue.keyTextObservation.topRight.x }).sorted (by: { (lhs, rhs) -> Bool in
                    lhs.topLeft.distance(to: keyValue.keyTextObservation.topRight) < rhs.topLeft.distance(to: keyValue.keyTextObservation.topRight)
                })
                .first
                keyValue.value = value?.topCandidates(1).first?.string
                keyValue.valueTextObservation = value
            case .vertical:
                let value = values.filter({ $0.topLeft.y <= keyValue.keyTextObservation.bottomLeft.y }).sorted (by: { (lhs, rhs) -> Bool in
                    lhs.bottomLeft.distance(to: keyValue.keyTextObservation.topLeft) < rhs.bottomLeft.distance(to: keyValue.keyTextObservation.topLeft)
                })
                .first
                keyValue.value = value?.topCandidates(1).first?.string
                keyValue.valueTextObservation = value
            }
            result.append(keyValue)
        }
        
        return result
    }
    
    private func fillLabel(for keyValue: RecognizedKeyValue) {
        switch keyValue.documentElement {
        case .dateOfBirth:
            dateOfBirthLabel.text = "\(keyValue.key) \(keyValue.value ?? "")"
        case .dateOfExpiry:
            dateOfExpiryLabel.text = "\(keyValue.key) \(keyValue.value ?? "")"
        case .dateOfIssue:
            dateOfIssueLabel.text = "\(keyValue.key) \(keyValue.value ?? "")"
        case .documentNo:
            documentNoLabel.text = "\(keyValue.key) \(keyValue.value ?? "")"
        case .givenNames:
            givenNameLabel.text = "\(keyValue.key) \(keyValue.value ?? "")"
        case .nationality:
            nationalityLabel.text = "\(keyValue.key) \(keyValue.value ?? "")"
        case .placeOfBirth:
            placeOfBirthLabel.text = "\(keyValue.key) \(keyValue.value ?? "")"
        case .sex:
            sexLabel.text = "\(keyValue.key) \(keyValue.value ?? "")"
        case .surname:
            surnameLabel.text = "\(keyValue.key) \(keyValue.value ?? "")"
        case .none:
            break
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

extension CGPoint {
    func distance(to point: CGPoint) -> Float {
        let startPoint = powf(Float(self.x - point.x), 2.0)
        let endPoint = powf(Float(self.y - point.y), 2.0)
        return sqrtf(startPoint + endPoint)
    }
}
