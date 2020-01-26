import UIKit

class ViewController: UITableViewController {

    var allWords = [String]()
    var usedWords = [String]()
    var gameState : GameState!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defaults = UserDefaults.standard
        if let gameStateSaved = defaults.object(forKey: "GameState") as? Data {
            let jsonDecoder = JSONDecoder()
            do {
                gameState = try jsonDecoder.decode(GameState.self, from: gameStateSaved)
            } catch {
                print("errrroooorr")
            }
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add
            , target: self, action: #selector(promptForAnswer))
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh
            , target: self, action: #selector(resetGame))
        
    
        if let startWordsUrl = Bundle.main.url(forResource: "start",
                                               withExtension: "txt") {
            if let startWords = try? String(contentsOf: startWordsUrl){
                allWords = startWords.components(separatedBy: "\n")
            }
        }
        
        if allWords.isEmpty {
            allWords = ["silkworm"]
        }
        
        startGame()
    
    }

    @objc func startGame(){
        
        if gameState == nil {
            title = allWords.randomElement()
            usedWords.removeAll(keepingCapacity: true)
        } else {
            title = gameState.currentWord
            usedWords = gameState.wordsUsed
        }
        tableView.reloadData()
    }
    
    @objc func resetGame() {
        title = allWords.randomElement()
        usedWords.removeAll(keepingCapacity: true)
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        usedWords.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Word", for: indexPath)
        cell.textLabel?.text = usedWords[indexPath.row]
        return cell
    }
    
    @objc func promptForAnswer(){
        
        let ac = UIAlertController(title: "Enter message", message: nil, preferredStyle: .alert)
        ac.addTextField()
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) {
            [weak self, weak ac] _ in
            guard let answer = ac?.textFields?[0].text else { return }
            self?.submit(answer)
        }
        ac.addAction(submitAction)
        present(ac, animated: true)
        
    }
    
    func submit(_ answer: String){
        let lowerAnswer = answer.lowercased()
        
        if isPossible(word: lowerAnswer){
            if isOriginal(word: lowerAnswer){
                if isReal(word: lowerAnswer){
                    usedWords.insert(lowerAnswer, at: 0)
                    let indexPath = IndexPath(row: 0, section: 0)
                    tableView.insertRows(at: [indexPath], with: .automatic)
                    save()
                    return
                } else {
                    showErrorMessage(withTitle: "Word not recognized",
                                     andMessage: "You cant just make them up, you know")
                }
            } else {
                showErrorMessage(withTitle: "Word already in use",
                                 andMessage: "Be more original")
            }
        } else {
            showErrorMessage(withTitle: "Word not possible", andMessage: "Cant spell back that word \(title!.lowercased())")
        }
    }
    
    func isPossible(word: String) -> Bool {
        
        guard var tempWord = title?.lowercased() else { return false }
        
        if tempWord == word {
            return false
        }
        
        if word.count < 2 {
            return false
        }
        
        for letter in word {
            if let position = tempWord.firstIndex(of: letter) {
                tempWord.remove(at: position)
            } else {
                return false
            }
        }
        return true
    }
    
    
    func isOriginal(word: String) -> Bool {
        return !usedWords.contains(word)
    }
    
    
    func isReal(word: String) -> Bool {
        
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
        
        return misspelledRange.location == NSNotFound
    }
    
    func showErrorMessage(withTitle errorTitle: String, andMessage errorMessage: String){
        let ac = UIAlertController(title: errorTitle, message: errorMessage, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Ok", style: .default))
        present(ac, animated: true)
    }
    
    func save() {
        print("salvou agora?")
        gameState = GameState()
        gameState.currentWord = title
        gameState.wordsUsed = usedWords
        
        let jsonEncoder = JSONEncoder()
        if let savedData = try? jsonEncoder.encode(gameState) {
            let defaults = UserDefaults.standard
            defaults.set(savedData, forKey: "GameState")
        } else {
            print("We failed to save the array")
        }
    }
    
}
