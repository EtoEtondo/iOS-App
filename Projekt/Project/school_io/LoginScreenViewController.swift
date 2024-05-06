import UIKit
import AVFoundation

//global variables to segue to next view
var name = ""
var pw = ""
var snbr = ""
var exmid = ""

class LoginScreenViewController: UIViewController, UITextFieldDelegate{

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var studentnumber: UITextField!
    @IBOutlet weak var examid: UITextField!
    
    var audioPlayer = AVAudioPlayer()
    
    @IBAction func loginbutton(_ sender: UIButton) {
        if (username.text != "" && password.text != "" && studentnumber.text != "" && examid.text != ""){
            //neglect checking of the taken inputs
            name = username.text!
            pw = password.text!
            snbr = studentnumber.text!
            exmid = examid.text!
            
            if((name == "Miko" || name == "Hans") && pw == "Pass" && snbr == "1234" && (exmid == "0000" || exmid == "1111")){
                //plays startingexam.mp3 when login works
                audioPlayer.play()
                //goes to the next view
                performSegue(withIdentifier: "segue", sender: self)
            }else{
                //for wrong data
                let alertController = UIAlertController(title: "Wrong Data!", message:
                           "Check your Username, Password, Student ID or Exam ID!", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Okay", style: .default))
                present(alertController, animated: true, completion: nil)
            }
        }else{
            //for no data
            let alertController = UIAlertController(title: "Did not found all data!", message:
                       "Write all your data inside the fields!", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Okay", style: .default))
            present(alertController, animated: true, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //loading the mp3
        guard let url = Bundle.main.url(forResource: "startingexam", withExtension: "mp3") else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            
        } catch {
            print("No audio found!")
        }
        
        self.username.delegate = self
        self.password.delegate = self
        self.studentnumber.delegate = self
        self.examid.delegate = self
        
        username.placeholder = "Username"
        studentnumber.placeholder = "Student ID"
        password.placeholder = "Password"
        examid.placeholder = "Exam ID"
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.switchBasedNextTextField(textField)
        return true
    }
    
    private func switchBasedNextTextField(_ textField: UITextField) {
        //switching textfields by pressing enter
        switch textField {
        case self.username:
            self.studentnumber.becomeFirstResponder()
            self.studentnumber.selectAll(nil)
        case self.studentnumber:
            self.password.becomeFirstResponder()
            self.password.selectAll(nil)
        case self.password:
            self.examid.becomeFirstResponder()
            self.examid.selectAll(nil)
        case self.examid:
            let button = view.viewWithTag(22) as? UIButton
            button?.sendActions(for: .touchUpInside)
        default:
            self.username.resignFirstResponder()
            self.username.selectAll(nil)
        }
    }

}
