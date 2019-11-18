//
//  ViewController.swift
//  airbank-ocr-demo
//
//  Created by Marek Přidal on 18/11/2019.
//  Copyright © 2019 Marek Přidal. All rights reserved.
//

import Photos
import UIKit
import Vision

final class ViewController: UIViewController {
    lazy var textDetectionRequest: VNRecognizeTextRequest = {
        let request = VNRecognizeTextRequest(completionHandler: self.handleDetectedText)
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["cs_CZ", "en_GB"]
        return request
    }()
    
    private lazy var uploadPhotoButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.roundedRect)
        button.addTarget(self, action: #selector(presentImageActionSheet), for: .touchUpInside)
        button.setTitle("Upload picture", for: .normal)
        return button
    }()
    
    private lazy var imageView: UIImageView = {
       let imageView = UIImageView()
        return imageView
    }()
    
    private lazy var previewView: PreviewView = {
       PreviewView()
    }()
    
    private let pickerController: UIImagePickerController = .init()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        pickerController.delegate = self
        setupLayout()
        setupNavigationBar()
    }
    
    private func process(image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        let requests = [textDetectionRequest]
        let imageRequestHandler = VNImageRequestHandler(cgImage: cgImage, orientation: .right, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try imageRequestHandler.perform(requests)
            } catch let error {
                print("Error: \(error)")
            }
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
    
    private func setupLayout() {
        view.backgroundColor = .systemBackground
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        imageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor).isActive = true
        imageView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor).isActive = true
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 3/2).isActive = true
        
        previewView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewView)
        previewView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor).isActive = true
        previewView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor).isActive = true
        previewView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor).isActive = true
        previewView.topAnchor.constraint(equalTo: imageView.topAnchor).isActive = true
        
        uploadPhotoButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(uploadPhotoButton)
        uploadPhotoButton.leadingAnchor.constraint(equalToSystemSpacingAfter: view.safeAreaLayoutGuide.leadingAnchor, multiplier: 0).isActive = true
        uploadPhotoButton.trailingAnchor.constraint(equalToSystemSpacingAfter: view.safeAreaLayoutGuide.trailingAnchor, multiplier: 0).isActive = true
        uploadPhotoButton.bottomAnchor.constraint(equalToSystemSpacingBelow: view.safeAreaLayoutGuide.bottomAnchor, multiplier: 0).isActive = true
        uploadPhotoButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }

    private func action(for type: UIImagePickerController.SourceType, title: String) -> UIAlertAction? {
        guard UIImagePickerController.isSourceTypeAvailable(type) else { return nil }

        return UIAlertAction(title: title, style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.pickerController.sourceType = type
            self.present(self.pickerController, animated: true)
        }
    }

    @objc
    private func presentImageActionSheet() {
        let alertController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if let action: UIAlertAction = action(for: .camera, title: "Take photo") {
            alertController.addAction(action)
        }
        if let action: UIAlertAction = action(for: .savedPhotosAlbum, title: "Saved photos album") {
            alertController.addAction(action)
        }
        if let action: UIAlertAction = action(for: .photoLibrary, title: "Photo library") {
            alertController.addAction(action)
        }

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        if UIDevice.current.userInterfaceIdiom == .pad {
            alertController.popoverPresentationController?.sourceView = view
            alertController.popoverPresentationController?.sourceRect = view.bounds
            alertController.popoverPresentationController?.permittedArrowDirections = [.down, .up]
        }

        present(alertController, animated: true)
    }
    
    func drawVisionRequestResults(_ results: [VNRecognizedTextObservation]) {
        DispatchQueue.main.async { [weak self] in
            self?.previewView.removeMask()
            for textObservation in results {
                self?.previewView.drawRect(textObservation: textObservation)
            }
        }
    }
    
    private func setupNavigationBar() {
        let imageButton = UIBarButtonItem(title: "Hide image", style: .plain, target: self, action: #selector(toggleImageViewHidden))
        imageButton.isEnabled = false
        navigationItem.rightBarButtonItem = imageButton
    }
    
    @objc
    private func toggleImageViewHidden() {
        imageView.isHidden.toggle()
        navigationItem.rightBarButtonItem?.title = imageView.isHidden ? "Show image" : "Hide image"
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true, completion: nil)
        guard let image = info[.originalImage] as? UIImage else { return }
        navigationItem.rightBarButtonItem?.isEnabled = true
        imageView.image = image
        process(image: image)
    }
    
}
