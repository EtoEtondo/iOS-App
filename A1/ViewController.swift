import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var HalloLabel: UILabel!
    
    @IBOutlet weak var CounterLabel: UILabel!
    var countNumbers : Int = 0
    
    @IBAction func tapped(_ sender: UIButton) {
        print("Mensch Ethem ich fange jetzt einen Knopfdruck ab! Mensch, Ethem Gürbüz")
        self.countNumbers += 1
        self.CounterLabel.text = String(self.countNumbers)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        HalloLabel.text = "Hallo, ich bin es: Ethem"
        CounterLabel.text = "0"
    }


}

