import UIKit
import Vision

class FaceView: UIView {
    
    //Arrays to draw points of face elements
    var leftEye: [CGPoint] = []
    var rightEye: [CGPoint] = []
    var leftEyebrow: [CGPoint] = []
    var rightEyebrow: [CGPoint] = []
    var nose: [CGPoint] = []
    var outerLips: [CGPoint] = []
    var innerLips: [CGPoint] = []
    var faceContour: [CGPoint] = []
    //Box around face
    var boundingBox = CGRect.zero
  
    func clear() {
        leftEye = []
        rightEye = []
        leftEyebrow = []
        rightEyebrow = []
        nose = []
        outerLips = []
        innerLips = []
        faceContour = []
    
        boundingBox = .zero
    
        DispatchQueue.main.async {
            self.setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {return}
        context.saveGState()

        defer { //like a stack
            context.restoreGState() //will be done at least
        }
        
        //draw red box around face
        context.addRect(boundingBox)
        UIColor.blue.setStroke()
        
        //draw white face elements
        context.strokePath()
        UIColor.yellow.setStroke()

        //drawing face elements by points in array
        if !leftEye.isEmpty {
            context.addLines(between: leftEye)
            context.closePath()
            context.strokePath()
        }

        if !rightEye.isEmpty {
            context.addLines(between: rightEye)
            context.closePath()
            context.strokePath()
        }

        if !leftEyebrow.isEmpty {
            context.addLines(between: leftEyebrow)
            context.strokePath()
        }

        if !rightEyebrow.isEmpty {
            context.addLines(between: rightEyebrow)
            context.strokePath()
        }

        if !nose.isEmpty {
            context.addLines(between: nose)
            context.strokePath()
        }

        if !outerLips.isEmpty {
            context.addLines(between: outerLips)
            context.closePath()
            context.strokePath()
        }

        if !innerLips.isEmpty {
            context.addLines(between: innerLips)
            context.closePath()
            context.strokePath()
        }

        if !faceContour.isEmpty {
            context.addLines(between: faceContour)
            context.strokePath()
        }
    }
}
