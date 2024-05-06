// Tic-Tac-Toe Feld beginnt mit 1 und geht bis 9

import UIKit

class ViewController: UIViewController {
    var activePlayer = 1 //Cross
    var gameState = [0, 0, 0, 0, 0, 0, 0, 0, 0]
    let winningCombinations = [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]]
    var gameisactive = true
    var gameover = false
    var counter = 0
    var gamemode = true //PvP
    var movedone = false

    
    @IBOutlet weak var game_title: UILabel!
    
    
    @IBOutlet weak var result_label: UILabel!
    
    
    @IBOutlet weak var gamemode_label: UILabel!
    
    
    @IBAction func action(_ sender: AnyObject) {
        print("Field action tapped: ",Int(sender.tag))
        print(gameisactive)
        //Feld nach gesetzten Formen untersuchen und checken ob Spiel schon gewonnen wurde
        if(gameState[sender.tag - 1] == 0 && gameisactive == true){
            gameState[sender.tag - 1] = activePlayer
            
            //Form aufs Feld setzen und Spieler setzen
            if(activePlayer == 1){
                sender.setImage(UIImage(named: "Cross.png"), for: UIControl.State())
                activePlayer = 2
            }
            else{
                sender.setImage(UIImage(named: "Circle.png"), for: UIControl.State())
                activePlayer = 1
            }
        }
        
        
        //Untersuchen ob gewonnen wurde wegen KI doppelt
        for combination in winningCombinations{
            
            if gameState[combination[0]] != 0 && gameState[combination[0]] == gameState[combination[1]] && gameState[combination[1]] == gameState[combination[2]]
            {
                if(gameState[combination[0]] == 1){
                    print("Cross wins!")
                    result_label.text = "Cross wins!"
                }else{
                    print("Circle wins!")
                    result_label.text = "Circle wins!"
                }
                gameover = true //Spiel ist vorbei
            }
        }
        
        //Untersuchen ob das Feld voll ist (Unentschieden) wegen KI
               gameisactive = false
               if(gameover == false){
                   for i in gameState{
                       if(i == 0){ //falls Spiel schon beendet ist das Feldüberprüfen egal
                           gameisactive = true
                           break
                       }
                       if(i != 0){
                           counter += 1
                           if(counter == 9){
                               print("It's a Draw!")
                               result_label.text = "It's a Draw!"
                               gameover = true
                           }
                       }
                   }
                   counter = 0
               }
        
        //KI-Modus (KI ist immer Spieler2/Kreis)
        if(activePlayer == 2 && gamemode == false && gameover == false){
            activePlayer = 1
            movedone = false //falls einmal gesetzt wurde soll er die anderen Fälle überspringen
            
            //Gewinnen
            if(movedone == false){
                for wincombi in winningCombinations{
                    if(gameState[wincombi[0]] == 2 && gameState[wincombi[1]] == 2 && gameState[wincombi[2]] == 0){
                            gameState[wincombi[2]] = 2
                            let index = wincombi[2]
                            let button = self.view.viewWithTag(index+1) as! UIButton
                            button.setImage(UIImage(named: "Circle.png"), for: UIControl.State())
                            movedone = true
                            break
                    }
                    if(gameState[wincombi[0]] == 0 && gameState[wincombi[1]] == 2 && gameState[wincombi[2]] == 2){
                            gameState[wincombi[0]] = 2
                            let index = wincombi[0]
                            let button = self.view.viewWithTag(index+1) as! UIButton
                            button.setImage(UIImage(named: "Circle.png"), for: UIControl.State())
                            movedone = true
                            break
                    }
                    if(gameState[wincombi[0]] == 2 && gameState[wincombi[1]] == 0 && gameState[wincombi[2]] == 2){
                            gameState[wincombi[1]] = 2
                            let index = wincombi[1]
                            let button = self.view.viewWithTag(index+1) as! UIButton
                            button.setImage(UIImage(named: "Circle.png"), for: UIControl.State())
                            movedone = true
                            break
                    }
                }
            }
            
            //Verteidigen
            if(movedone == false){
                for wincombi in winningCombinations{
                    if(gameState[wincombi[0]] == 1 && gameState[wincombi[1]] == 1 && gameState[wincombi[2]] == 0){
                            gameState[wincombi[2]] = 2
                            let index = wincombi[2]
                            let button = self.view.viewWithTag(index+1) as! UIButton
                            button.setImage(UIImage(named: "Circle.png"), for: UIControl.State())
                            movedone = true
                            break
                    }
                    if(gameState[wincombi[0]] == 0 && gameState[wincombi[1]] == 1 && gameState[wincombi[2]] == 1){
                            gameState[wincombi[0]] = 2
                            let index = wincombi[0]
                            let button = self.view.viewWithTag(index+1) as! UIButton
                            button.setImage(UIImage(named: "Circle.png"), for: UIControl.State())
                            movedone = true
                            break
                    }
                    if(gameState[wincombi[0]] == 1 && gameState[wincombi[1]] == 0 && gameState[wincombi[2]] == 1){
                            gameState[wincombi[1]] = 2
                            let index = wincombi[1]
                            let button = self.view.viewWithTag(index+1) as! UIButton
                            button.setImage(UIImage(named: "Circle.png"), for: UIControl.State())
                            movedone = true
                            break
                    }
                }
            }
            
            //Setzen der Form in die Mitte, falls nicht Verteidigen oder Gewinnen möglich
            if(movedone == false){
                if(gameState[4] == 0){
                    gameState[4] = 2
                    movedone = true
                    let button = self.view.viewWithTag(5) as! UIButton
                    button.setImage(UIImage(named: "Circle.png"), for: UIControl.State())
                }else{  //Falls Mitte besetzt, wird zufällig wohin gesetzt
                    movedone = true
                    while(true){
                        let number = Int.random(in: 0...8)
                        if(gameState[number] == 0){
                            gameState[number] = 2
                            let button = self.view.viewWithTag(number+1) as! UIButton
                            button.setImage(UIImage(named: "Circle.png"), for: UIControl.State())
                            break
                        }
                    }
                }
            }
        }
        
        
        //Untersuchen ob gewonnen wurde
        for combination in winningCombinations{
            
            if gameState[combination[0]] != 0 && gameState[combination[0]] == gameState[combination[1]] && gameState[combination[1]] == gameState[combination[2]]
            {
                if(gameState[combination[0]] == 1){
                    print("Cross wins!")
                    result_label.text = "Cross wins!"
                }else{
                    print("Circle wins!")
                    result_label.text = "Circle wins!"
                }
                gameover = true //Spiel ist vorbei
            }
        }
        
        
        //Untersuchen ob das Feld voll ist (Unentschieden)
        gameisactive = false
        if(gameover == false){
            for i in gameState{
                if(i == 0){ //falls Spiel schon beendet ist das Feldüberprüfen egal
                    gameisactive = true
                    break
                }
                if(i != 0){
                    counter += 1
                    if(counter == 9){
                        print("It's a Draw!")
                        result_label.text = "It's a Draw!"
                        gameover = true
                    }
                }
            }
            counter = 0
        }
    }
    
    
    
    @IBAction func switch_gamemode(_ sender: UIButton) {
        print("Switch gamemode tapped")
        activePlayer = 1
        gameState = [0, 0, 0, 0, 0, 0, 0, 0, 0]
        gameisactive = true
        result_label.text = " "
        gameover = false
        counter = 0
        movedone = false
        
        for i in 1...9{
            let button = view.viewWithTag(i) as! UIButton
            button.setImage(nil, for: UIControl.State())
        }
        
        if sender.currentTitle == "PvP" {
            gamemode = true
            print("PvP Mode")
            gamemode_label.text = "PvP Mode selected.."
        }
        if sender.currentTitle == "PvE" {
            gamemode = false
            print("PvE Mode")
            gamemode_label.text = "PvE Mode selected.."
        }
    }
    
    
    @IBAction func new_game_button(_ sender: UIButton) {
        print("New Game tapped")
        activePlayer = 1
        gameState = [0, 0, 0, 0, 0, 0, 0, 0, 0]
        gameisactive = true
        result_label.text = " "
        gameover = false
        counter = 0
        movedone = false
        
        //Images zurücksetzen
        for i in 1...9{
            let button = view.viewWithTag(i) as! UIButton
            button.setImage(nil, for: UIControl.State())
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        game_title.text = "Tic-Tac-Toe"
        result_label.text = " "
        gamemode_label.text = "PvP Mode selected.."
    }

}

