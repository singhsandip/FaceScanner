//
//  FaceDetectionViewController.swift
//  Face Scanner
//
//  Created by sandeepsing-maclaptop on 05/02/24.
//

import UIKit
import AVFoundation
import Vision

class FaceDetectionViewController: UIViewController {
    
    
    @IBOutlet weak var cameraView: UIView!
    
    
    var captureSession : AVCaptureSession!
    var frontCamera : AVCaptureDevice!
    
    var frontInput : AVCaptureInput!
    var videoOutput : AVCaptureVideoDataOutput!
    
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    private var drawings: [CALayer] = []
    var isFaceDetected = false
    
    var capturedImage: UIImage?
    var faceBoundingBox: CGRect?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkPermissions()
        setupAndStartCaptureSession()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }
    
    @IBAction func captureImage(_ sender: Any) {
        
        if !isFaceDetected {
            showAlert(title: "No Face Detected", message: "Please try again.")
            return
        }
        if let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "OutputViewController") as? OutputViewController {
            viewController.capturedImage = capturedImage
            viewController.faceBoundingBox = faceBoundingBox
            viewController.previewSize = self.previewLayer.frame.size
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    func setupAndStartCaptureSession(){
        DispatchQueue.global(qos: .userInitiated).async{
            //init session
            self.captureSession = AVCaptureSession()
            //start configuration
            self.captureSession.beginConfiguration()
            
            //session specific configuration
            if self.captureSession.canSetSessionPreset(.photo) {
                self.captureSession.sessionPreset = .photo
            }
            self.captureSession.automaticallyConfiguresCaptureDeviceForWideColor = true
            
            //setup inputs
            self.setupInputs()
            
            DispatchQueue.main.async {
                //setup preview layer
                self.setupPreviewLayer()
            }
            
            //setup output
            self.setupOutput()
            
            //commit configuration
            self.captureSession.commitConfiguration()
            //start running it
            self.captureSession.startRunning()
        }
    }
    
    func setupInputs(){
        
        //get front camera
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            frontCamera = device
        } else {
            fatalError("no front camera")
        }
        
        guard let fInput = try? AVCaptureDeviceInput(device: frontCamera) else {
            fatalError("could not create input device from front camera")
        }
        frontInput = fInput
        if !captureSession.canAddInput(frontInput) {
            fatalError("could not add front camera input to capture session")
        }
        
        //connect back camera input to session
        captureSession.addInput(frontInput)
    }
    
    func setupOutput(){
        videoOutput = AVCaptureVideoDataOutput()
        let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInteractive)
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            fatalError("could not add video output")
        }
        
        videoOutput.connections.first?.videoOrientation = .portrait
    }
    
    func setupPreviewLayer(){
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraView.layer.addSublayer(previewLayer)
        self.previewLayer.videoGravity = .resizeAspect
        self.previewLayer.connection?.videoOrientation = .portrait
        self.cameraView.layoutIfNeeded()
        self.previewLayer.frame = self.cameraView.bounds
    }
}



extension FaceDetectionViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let frame = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            debugPrint("unable to get image from sample buffer")
            return
        }
        
        detectFace(in: frame)
    }
    
    private func detectFace(in image: CVPixelBuffer) {
        
        let faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: { (request: VNRequest, error: Error?) in
            DispatchQueue.main.async {
                if let results = request.results as? [VNFaceObservation], !results.isEmpty {
                    self.isFaceDetected = true
                    
                    //get a CIImage out of the CVImageBuffer
                    let ciImage = CIImage(cvImageBuffer: image)
                    
                    //get UIImage out of CIImage
                    let uiImage = UIImage(ciImage: ciImage)
                    
                    self.handleFaceDetectionResults(results,image: uiImage)
                } else {
                    self.isFaceDetected = false
                    self.clearDrawings()
                }
            }
        })
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: image, orientation: .leftMirrored, options: [:])
        try? imageRequestHandler.perform([faceDetectionRequest])
    }
    
    private func handleFaceDetectionResults(_ observedFaces: [VNFaceObservation],image: UIImage) {
        self.clearDrawings()
        var newDrawings = [CALayer]()
        
        if let observedFace = observedFaces.first {
            let faceBoundingBoxOnScreen = self.previewLayer.layerRectConverted(fromMetadataOutputRect: observedFace.boundingBox)
            
            print("face in code: \(observedFace.boundingBox)")
            self.capturedImage = image
            self.faceBoundingBox = faceBoundingBoxOnScreen
            
            print("face detected from existing code \(faceBoundingBoxOnScreen)")
            // Draw the face rectangle
            let faceRectLayer = CAShapeLayer()
            faceRectLayer.frame = faceBoundingBoxOnScreen
            faceRectLayer.borderColor = UIColor.blue.cgColor // Choose a color that stands out
            faceRectLayer.borderWidth = 2.0
            faceRectLayer.cornerRadius = 5.0 // Optional, for rounded corners
            newDrawings.append(faceRectLayer)
        }
        
        newDrawings.forEach({ drawing in self.view.layer.addSublayer(drawing) })
        self.drawings = newDrawings
    }
    
    func fixOrientation(of image: UIImage) -> UIImage {
          if image.imageOrientation == .up {
              return image
          }
          
          UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
          image.draw(in: CGRect(origin: .zero, size: image.size))
          let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
          UIGraphicsEndImageContext()
          
          return normalizedImage ?? image
      }
    
    private func clearDrawings() {
        self.drawings.forEach({ drawing in drawing.removeFromSuperlayer() })
    }
    
}

