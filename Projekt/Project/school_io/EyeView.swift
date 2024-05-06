import UIKit

struct Eye {
    var origin: CGPoint
    var focus: CGPoint
}

class EyeView: UIView {
    //Arrays to draw points of view direction elements
    private var Eyes: [Eye] = []
  
    func add(Eye: Eye) {
        Eyes.append(Eye)
    }
  
    func clear() {
        Eyes.removeAll()
        DispatchQueue.main.async {
            self.setNeedsDisplay()
        }
    }
  
    override func draw(_ rect: CGRect) {
    
        guard let context = UIGraphicsGetCurrentContext() else {return}
        context.saveGState()
        //drawing eye direction by points in array
        for Eye in Eyes {
            context.addLines(between: [Eye.origin, Eye.focus])
            context.setStrokeColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.5)
            context.setLineWidth(4.5)
            context.strokePath()
            context.addLines(between: [Eye.origin, Eye.focus])
            context.setStrokeColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 0.8)
            context.setLineWidth(3.0)
            context.strokePath()
        }
        context.restoreGState()
    }
}
