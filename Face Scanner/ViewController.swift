//
//  ViewController.swift
//  Face Scanner
//
//  Created by sandeepsing-maclaptop on 05/02/24.
//

import UIKit
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate ,UINavigationControllerDelegate{
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
    }
    
    
    @IBAction func takeSelfie(_ sender: Any) {
        let story = UIStoryboard(name: "Main", bundle: nil)
        
        if let vc = story.instantiateViewController(withIdentifier: "FaceDetectionViewController") as? FaceDetectionViewController {
            vc.modalPresentationStyle = .fullScreen
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            print("Failed to instantiate FaceDetectionViewController")
        }
    }
    
    @IBAction func uploadPhoto(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            print("image selected")
            detectFaces(in: selectedImage)
        } else {
            print("image not selected")
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func detectFaces(in image: UIImage) {
        guard let cgImage = image.cgImage else { return }

        let request = VNDetectFaceRectanglesRequest { [weak self] request, error in
            DispatchQueue.main.async {
                guard let strongSelf = self else { return }

                if let faces = request.results as? [VNFaceObservation], let firstFace = faces.first {
                    let boundingBox = firstFace.boundingBox
                    let size = CGSize(width: boundingBox.width * CGFloat(cgImage.width),
                                      height: boundingBox.height * CGFloat(cgImage.height))
                    let origin = CGPoint(x: boundingBox.minX * CGFloat(cgImage.width),
                                         y: (1 - boundingBox.minY - boundingBox.height) * CGFloat(cgImage.height)) // Flip the y-coordinate
                    
                    strongSelf.toOutput(image: image, faceBoundingBox: CGRect(origin: origin, size: size))
                } else {
                    strongSelf.showAlert(title: "No Face Detected", message: "Please try again.")
                }
            }
        }

        let handler = VNImageRequestHandler(cgImage: cgImage,orientation: .up ,options: [:])
        try? handler.perform([request])
    }
    
    
    func detectFaceCoordinates(in image: UIImage) {
        guard let cgImage = image.cgImage else { return }
//        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: image.pixelBuffer()!, orientation: .up, options: [:])
        
        let request = VNDetectFaceLandmarksRequest { [weak self] request, error in
                DispatchQueue.main.async {
                    guard let strongSelf = self else { return }

                    if let faces = request.results as? [VNFaceObservation], let firstFace = faces.first {
                        let boundingBox = firstFace.boundingBox
                        strongSelf.toOutput(image: image, faceBoundingBox: boundingBox)
                    } else {
                        strongSelf.showAlert(title: "No Face Detected", message: "Please try again.")
                    }
                }
            }
        
        do {
            try imageRequestHandler.perform([request])
        } catch {
            print("Error: \(error)")
        }
    }

    private func toOutput(image: UIImage,faceBoundingBox: CGRect) {
        if let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "OutputViewController") as? OutputViewController {
            viewController.capturedImage = image
            viewController.faceBoundingBox = faceBoundingBox
            viewController.previewSize = image.size
            viewController.fromCamera = false
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}

extension UIImage {
    func pixelBuffer() -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let imageWidth = Int(self.size.width)
        let imageHeight = Int(self.size.height)

        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary

        let status = CVPixelBufferCreate(kCFAllocatorDefault, imageWidth, imageHeight, kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)

        guard let buffer = pixelBuffer, status == kCVReturnSuccess else {
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(buffer)

        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue)
        let context = CGContext(
            data: pixelData,
            width: imageWidth,
            height: imageHeight,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: rgbColorSpace,
            bitmapInfo: bitmapInfo.rawValue
        )

        context?.translateBy(x: 0, y: CGFloat(imageHeight))
        context?.scaleBy(x: 1.0, y: -1.0)

        UIGraphicsPushContext(context!)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))

        return buffer
    }
}
