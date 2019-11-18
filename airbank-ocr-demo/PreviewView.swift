//
//  PreviewView.swift
//  VisionDetection
//
//  Created by Wei Chieh Tseng on 09/06/2017.
//  Copyright © 2017 Willjay. All rights reserved.
//

import UIKit
import Vision
import AVFoundation

class PreviewView: UIView {
    
    private var maskLayer = [CAShapeLayer]()
    
    // MARK: AV capture properties
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        
        set {
            videoPreviewLayer.session = newValue
        }
    }
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    // Create a new layer drawing the bounding box
    private func createLayer(in rect: CGRect) -> CAShapeLayer{
        
        let mask = CAShapeLayer()
        mask.frame = rect
        mask.cornerRadius = 10
        mask.opacity = 0.75
        mask.borderColor = UIColor.yellow.cgColor
        mask.borderWidth = 2.0
        
        maskLayer.append(mask)
        layer.insertSublayer(mask, at: 1)
        
        return mask
    }
    
    func drawFaceboundingBox(face : VNFaceObservation) {
        
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -frame.height)
        
        let translate = CGAffineTransform.identity.scaledBy(x: frame.width, y: frame.height)
        
        // The coordinates are normalized to the dimensions of the processed image, with the origin at the image's lower-left corner.
        let facebounds = face.boundingBox.applying(translate).applying(transform)
        
        _ = createLayer(in: facebounds)
        
    }
    
    private func drawPointsOnLayer(rect:CGRect, landmarkPoints: [CGPoint], isClosed: Bool = true) -> CALayer {
        let linePath = UIBezierPath()
        linePath.move(to: landmarkPoints.first!)
        
        for point in landmarkPoints.dropFirst() {
            linePath.addLine(to: point)
        }
        
        if isClosed {
            linePath.addLine(to: landmarkPoints.first!)
        }
        
        let lineLayer = CAShapeLayer()
        lineLayer.path = linePath.cgPath
        lineLayer.fillColor = nil
        lineLayer.opacity = 1.0
        lineLayer.strokeColor = UIColor.green.cgColor
        lineLayer.lineWidth = 0.02
        
        return lineLayer
    }
    
    func drawRect(textObservation: VNRecognizedTextObservation) {
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -frame.height)
        
        let translate = CGAffineTransform.identity.scaledBy(x: frame.width, y: frame.height)
        
        // The coordinates are normalized to the dimensions of the processed image, with the origin at the image's lower-left corner.
        let textBounds = textObservation.boundingBox.applying(translate).applying(transform)
        
        let layer = createLayer(in: textBounds)
        
        let label = UILabel(frame: layer.frame)
        label.font = .systemFont(ofSize: 8)
        label.textColor = .systemRed
        if let topResult = textObservation.topCandidates(1).first {
            label.text = topResult.string
        }
        addSubview(label)
    }
    
    func removeMask() {
        for mask in maskLayer {
            mask.removeFromSuperlayer()
        }
        maskLayer.removeAll()
    }
    
}
