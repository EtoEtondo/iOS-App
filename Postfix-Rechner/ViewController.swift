import UIKit



class ViewController: UIViewController {

    @IBOutlet weak var display: UILabel!
    var isTypingNumber = false
    var firstNumber = 0
    var secondNumber = 0
    var operation = " "
    var operationcounter = 0

    //3. Aufgabe
    @IBOutlet weak var showoperator: UILabel!

    //3. Aufgabe
    @IBOutlet weak var PositivNegativ: UILabel!
    
    
    @IBAction func numberTapped(_ sender: UIButton) { // sender vom Objekt Button
        print("Number tapped!")
        let number = sender.currentTitle! //currentTitle ist die Beschriftung des Buttons
                                          //! implicitily umwrapped optional
        
        if isTypingNumber{
            display.text = display.text! + number //display bekommt aktuellen Wert + neue Zahl
        }else{
            isTypingNumber = true //auf true setzen falls er noch weiter tippen sollte
            display.text = number //aktuelle Zahl
        }
        
    }
    
    
    @IBAction func calculationTapped(_ sender: UIButton) {
        print("Operation Tapped")
        isTypingNumber = false
        secondNumber = Int(display.text!)!
        operation = sender.currentTitle!
        var result = 0
        
        //checken welche operation gedrückt wurde
        if operation == "+"{
            result = firstNumber + secondNumber
        } else if operation == "-"{
            result = firstNumber - secondNumber
        } else if operation == "*"{
            result = firstNumber * secondNumber
        } else if operation == "/"{
            result = firstNumber / secondNumber
        }
        
        //Ergebnis Ausgeben -> Ergebnis wird neue erste Nummer
        display.text = String(result)
        firstNumber = result
        
        //3. Aufgabe
        if result < 0 {
            PositivNegativ.text = "N"
        }else{
            PositivNegativ.text = "P"
        }
        
        //3. Aufgabe
        operationcounter += 1
        if operationcounter >= 10 {
            var s = String(showoperator.text!)
            s.remove(at: s.startIndex)
            showoperator.text = s
        }
        showoperator.text = showoperator.text! + operation
        
    }
    
    @IBAction func equalenterTapped(_ sender: UIButton) {
        print("Equals/Enter Tapped")
        isTypingNumber = false
        firstNumber = Int(display.text!)! //durch Enter bekommt unsere erste Zahl die Zahl auf dem Display
    }
    
    @IBAction func restart(_ sender: UIButton) {
        print("Restart Tapped")
        //zurücksetzen der Variablen durch drücken von C
        display.text = "0"
        firstNumber = 0
        secondNumber = 0
        operation = " "
        isTypingNumber = false
        PositivNegativ.text = "P"
        showoperator.text = " "
        operationcounter = 0
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        display.text = "0"
        showoperator.text = " "
        PositivNegativ.text = "P"
    }


}

