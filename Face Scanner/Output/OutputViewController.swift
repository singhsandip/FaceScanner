//
//  OutputViewController.swift
//  Face Scanner
//
//  Created by sandeepsing-maclaptop on 05/02/24.
//

import UIKit

class OutputViewController: UIViewController {
    
    @IBOutlet weak var detecedImage: UIImageView!
    
    
    @IBOutlet weak var cbAll: UIImageView!
    
    @IBOutlet weak var cbWrinkles: UIImageView!
    
    
    @IBOutlet weak var cbPores: UIImageView!
    
    @IBOutlet weak var cbPegmantation: UIImageView!
    
    var capturedImage: UIImage?
    var previewSize: CGSize?
    var faceBoundingBox: CGRect?
    var transformedBoundingBox: CGRect?
    
    var abnormalities: [FacialAbnormality] = []
    var selectedType: FacialAbnormalityType? = nil
    var fromCamera: Bool = true
    
    private var drawings: [CALayer] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.displayCapturedImage()
        self.calculateBoundingBox()
    
        self.drawAbnormalities(type: nil)
    }
    
    private func displayCapturedImage() {
        detecedImage.image = capturedImage
    }
    
    private func calculateBoundingBox() {
        if let image = capturedImage, let boundingBox = faceBoundingBox {
            
            transformedBoundingBox = transformBoundingBox(
                originalBoundingBox: boundingBox,
                from: previewSize!, // Original preview layer size
                to: detecedImage.frame.size // Size of the image view
            )
            
            calculateAbnormalities(screenBoundingBox: transformedBoundingBox)
        }
    }
    
    private func calculateAbnormalities(screenBoundingBox: CGRect?) {
        if let transformedBoundingBox = screenBoundingBox{
            abnormalities = generateSpecificAbnormalities(within: transformedBoundingBox)
        }
        
    }
    
    private func drawAbnormalities(type: FacialAbnormalityType?) {
        selectedType = type
        if let transformedBoundingBox = transformedBoundingBox {
            self.clearDrawings()
            var newDrawings = [CALayer]()
            
            let faceRectLayer = CAShapeLayer()
            faceRectLayer.frame = transformedBoundingBox
            faceRectLayer.borderColor = UIColor.blue.cgColor // Choose a color that stands out
            faceRectLayer.borderWidth = 2.0
            faceRectLayer.cornerRadius = 5.0 // Optional, for rounded corners
            newDrawings.append(faceRectLayer)
            
            newDrawings += self.drawFaceFeatures(screenBoundingBox: transformedBoundingBox,type: type)
            
            newDrawings.forEach({ drawing in self.view.layer.addSublayer(drawing) })
            self.drawings = newDrawings
        }
    }
    
    
    func transformBoundingBox(originalBoundingBox: CGRect, from originalSize: CGSize, to newSize: CGSize, withRotation rotation: Bool = false) -> CGRect {
        
        var transformedBoundingBox = originalBoundingBox
        
        if fromCamera {
            let heightScale = newSize.height / originalSize.height
            
            if rotation {
                // Rotate the bounding box if needed
                transformedBoundingBox = rotateBoundingBox90DegreesClockwise(originalBoundingBox: originalBoundingBox, imageSize: originalSize)
            }
            
            // Apply scale to the rotated/transposed bounding box
            transformedBoundingBox.origin.x *= heightScale
            transformedBoundingBox.origin.y *= heightScale
            transformedBoundingBox.size.width *= heightScale
            transformedBoundingBox.size.height *= heightScale
            
        }else {
            let imageViewSize = detecedImage.frame.size
            
            // Calculate the pixel coordinates
            let rectX = originalBoundingBox.origin.x * imageViewSize.width
            let rectY = originalBoundingBox.origin.y * imageViewSize.height
            let rectWidth = originalBoundingBox.size.width * imageViewSize.width
            let rectHeight = originalBoundingBox.size.height * imageViewSize.height

            // Create a CGRect using the calculated coordinates
            let boundingBoxRect = CGRect(x: rectX, y: rectY/2.0, width: rectWidth, height: rectHeight)

            transformedBoundingBox = boundingBoxRect
        }
        
        return transformedBoundingBox
    }
    
    func rotateBoundingBox90DegreesClockwise(originalBoundingBox: CGRect, imageSize: CGSize) -> CGRect {
        var rotatedBoundingBox = CGRect()
        
        // Switch x and y, and adjust them based on the new width and height
        rotatedBoundingBox.origin.x = originalBoundingBox.origin.y
        rotatedBoundingBox.origin.y = imageSize.width - originalBoundingBox.origin.x - originalBoundingBox.width
        rotatedBoundingBox.size.width = originalBoundingBox.size.height
        rotatedBoundingBox.size.height = originalBoundingBox.size.width
        
        return rotatedBoundingBox
    }
    
    
    private func drawFaceFeatures(screenBoundingBox: CGRect,type: FacialAbnormalityType?) -> [CALayer] {
        var drawingLayers: [CALayer] = []
        
        let abnormalitiesToDraw: [FacialAbnormality]
        
        if let type = type {
                // Filter abnormalities based on selected types
                abnormalitiesToDraw = abnormalities.filter { $0.type == type }
            } else {
                // If type is nil, use all abnormalities
                abnormalitiesToDraw = abnormalities
            }
    
        // Drawing code for abnormalities
        for abnormality in abnormalitiesToDraw {
            // Draw rectangle at the abnormality location
            let rectLayer = CAShapeLayer()
            rectLayer.frame = CGRect(x: abnormality.location.x, y: abnormality.location.y, width: 10, height: 10)
            rectLayer.borderColor = UIColor.red.cgColor
            rectLayer.borderWidth = 2
            drawingLayers.append(rectLayer)
            
            // Draw text label for the abnormality
            let textLayer = CATextLayer()
            textLayer.string = abnormality.type.description
            textLayer.foregroundColor = UIColor.white.cgColor
            textLayer.backgroundColor = UIColor.black.cgColor
            textLayer.fontSize = 12
            
            // Adjusting the X-coordinate for the textLayer's frame based on the abnormality type
            let textWidth: CGFloat = 100
            let textHeight: CGFloat = 20
            let xOffset: CGFloat = (abnormality.description == "Left Cheek Abnormality") ? -textWidth - 5 : 15
            
            textLayer.frame = CGRect(x: abnormality.location.x + xOffset, y: abnormality.location.y - (textHeight / 2), width: textWidth, height: textHeight)
            drawingLayers.append(textLayer)
        }
        
        return drawingLayers
    }
    
    
    private func clearDrawings() {
        self.drawings.forEach({ drawing in drawing.removeFromSuperlayer() })
    }
    
    private func generateSpecificAbnormalities(within boundingBox: CGRect) -> [FacialAbnormality] {
        var abnormalities = [FacialAbnormality]()
        
        // Abnormality on the forehead
        let foreheadX = boundingBox.midX
        let foreheadY = boundingBox.minY + boundingBox.height * 0.1 // Adjust the multiplier to position on the forehead
        let foreheadAbnormality = FacialAbnormality(location: CGPoint(x: foreheadX, y: foreheadY), type: .wrinkle, description: "Forehead Abnormality")
        abnormalities.append(foreheadAbnormality)
        
        // Abnormalities on the cheeks
        let cheekY = boundingBox.midY + boundingBox.height * 0.10
        
        let leftCheekX = boundingBox.minX + boundingBox.width * 0.3 // Adjust the multiplier to position on the left cheek
        let rightCheekX = boundingBox.maxX - boundingBox.width * 0.3 // Adjust the multiplier to position on the right cheek
        let leftCheekAbnormality = FacialAbnormality(location: CGPoint(x: leftCheekX, y: cheekY), type: .pores, description: "Left Cheek Abnormality")
        let rightCheekAbnormality = FacialAbnormality(location: CGPoint(x: rightCheekX, y: cheekY), type: .pigmentation, description: "Right Cheek Abnormality")
        abnormalities.append(leftCheekAbnormality)
        abnormalities.append(rightCheekAbnormality)
        
        // Abnormality on the chin
        let chinX = boundingBox.midX
        let chinY = boundingBox.midY + boundingBox.height * 0.30 // Adjust the multiplier to position on the chin
        print("cheekY: \(chinY)")
        let chinAbnormality = FacialAbnormality(location: CGPoint(x: chinX, y: chinY), type: .pores, description: "Chin Abnormality")
        abnormalities.append(chinAbnormality)
        
        return abnormalities
    }
    
   
    @IBAction func drawAllAbnormalities(_ sender: Any) {
        deselect()
        drawAbnormalities(type: nil)
        cbAll.image = UIImage(systemName: "checkmark.square.fill")
    }
    
    @IBAction func drawWrinkles(_ sender: Any) {
        deselect()
        drawAbnormalities(type: .wrinkle)
       
        cbWrinkles.image = UIImage(systemName: "checkmark.square.fill")
    }
    
    @IBAction func drawPores(_ sender: Any) {
        deselect()
        drawAbnormalities(type: .pores)
       
        cbPores.image = UIImage(systemName: "checkmark.square.fill")
    }
    
    @IBAction func drawPegmentation(_ sender: Any) {
        deselect()
        drawAbnormalities(type: .pigmentation)
        
        cbPegmantation.image = UIImage(systemName: "checkmark.square.fill")
    }
    
    private func deselect() {
        
        if selectedType == nil {
            cbAll.image = UIImage(systemName: "square")
            return
        }
        
        switch selectedType {
            
        case .wrinkle:
            cbWrinkles.image = UIImage(systemName: "square")
        case .pores:
            cbPores.image = UIImage(systemName: "square")
        case .pigmentation:
            cbPegmantation.image = UIImage(systemName: "square")
        case .none:
            cbAll.image = UIImage(systemName: "square")
        }
    }
    
    @IBAction func goToHome(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
}
