import UIKit

import CoreData
import PencilKit



class UserTestViewController: UIViewController {
    
    public var userTestView : UserTestView! /// 뷰 프로퍼티
    
    var receivedText: String? /// 전달받는 텍스트 변수
    var originalText: String? /// 정답으로 사용할 변수
    var pasteReceivedText: String = "" /// 정답확인 후 다시 문제 Text로 돌아가기 위한 복사된 receivedTtext
    
    var answerButton: UIBarButtonItem! /// 네비게이션 버튼
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: 뷰
        userTestView = UserTestView(frame: view.bounds)
        view.addSubview(userTestView)
        
        // MARK: 네비게이션
        title = "테스트"
        let saveButton = UIBarButtonItem(title: "저장", style: .plain, target: self, action: #selector(saveTapped))
        saveButton.tintColor = .white
        
        answerButton = UIBarButtonItem(title: "정답확인", style: .plain, target: self, action: #selector(answerTapped))
        answerButton.tintColor = .white
        navigationItem.rightBarButtonItems = [ saveButton, answerButton ] // 네비게이션 버튼2개 배열로 할당
        
        let userTestAppearance = UINavigationBarAppearance()
        userTestAppearance.backgroundColor = .tintColor
        userTestAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        userTestAppearance.shadowColor = .none
        
        let backButtonAppearance = UIBarButtonItemAppearance()
        backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
        userTestAppearance.backButtonAppearance = backButtonAppearance
        
        let backButtonImage = UIImage(systemName: "chevron.left")
        userTestAppearance.setBackIndicatorImage(backButtonImage, transitionMaskImage: backButtonImage)
        
        
        navigationController?.navigationBar.tintColor = .tintColor
        navigationController?.navigationBar.scrollEdgeAppearance = userTestAppearance
        navigationController?.navigationBar.standardAppearance = userTestAppearance
        
        
        userTestView.serveTextView.text = replaceCharacter(text: receivedText!) // image에서 변환된 text 전달 받기
        pasteReceivedText = userTestView.serveTextView.text
        originalText = receivedText
        
        
        // Trash Undo Redo Palette
        let undoTapGesture = UITapGestureRecognizer(target: self, action: #selector(undoTapped))
        userTestView.undoImageButton.addGestureRecognizer(undoTapGesture)
        userTestView.undoImageButton.isUserInteractionEnabled = true
        
        let redoTapGesture = UITapGestureRecognizer(target: self, action: #selector(redoTapped))
        userTestView.redoImageButton.addGestureRecognizer(redoTapGesture)
        userTestView.redoImageButton.isUserInteractionEnabled = true
        
        let trashTapGesture = UITapGestureRecognizer(target: self, action: #selector(trashTapped))
        userTestView.trashImageButton.addGestureRecognizer(trashTapGesture)
        userTestView.trashImageButton.isUserInteractionEnabled = true
        
        userTestView.canvasView.drawingGestureRecognizer.addTarget(self, action: #selector(drawingStarted))
        
        setupCanvasView() // PKToolPicker : Palette
        setUpTool()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        let appearance = UINavigationBarAppearance() /// 네비게이션 바 타이틀 컬러 고정 및 네비게이션 설정
        appearance.backgroundColor = .systemBlue
        appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        appearance.shadowColor = .none
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    // 원본 text -> test용 text로 랜덤 인덱스 변환
    func replaceCharacter(text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        var modifiedLines: [String] = []
        var problemNumber = 1
        
        for line in lines {
            let modifiedLine = replaceLine(line, problemNumber: &problemNumber)
            modifiedLines.append(modifiedLine)
        }
        
        return modifiedLines.joined(separator: "\n")
    }
    
    func replaceLine(_ line: String, problemNumber: inout Int) -> String {
        let words = line.components(separatedBy: .whitespaces)
        let numberOfWordsToReplace = Int(ceil(Double(words.count) / 3.0))
        
        var modifiedWords = words
        var replacedWordIndices = Set<Int>()
        
        while replacedWordIndices.count < numberOfWordsToReplace {
            let randomIndex = Int.random(in: 0..<words.count)
            
            let word = words[randomIndex]
            if !isSpecialCharacter(word) && !isConsecutiveWordsReplaced(randomIndex, replacedWordIndices) {
                replacedWordIndices.insert(randomIndex)
            }
        }
        
        let sortedIndices = replacedWordIndices.sorted(by: <)
        
        for index in sortedIndices {
            let replacedWord = words[index]
            let replacedWordCount = replacedWord.count
            if replacedWordCount > 2 {
                let numberOfUnderscores = replacedWordCount - 2
                let underscores = String(repeating: "_", count: numberOfUnderscores)
                let replacedWordWithNumber = "(\(problemNumber))\(underscores)"
                modifiedWords[index] = replacedWordWithNumber
                problemNumber += 1
            }
        }
        
        return modifiedWords.joined(separator: " ")
    }
    
    // 특수문자는 변환 금지
    func isSpecialCharacter(_ word: String) -> Bool {
        let specialCharacters = CharacterSet.punctuationCharacters.subtracting(CharacterSet(charactersIn: "_"))
        return word.rangeOfCharacter(from: specialCharacters) != nil
    }
    // 2개 연속 단어 변환 금지
    func isConsecutiveWordsReplaced(_ currentIndex: Int, _ replacedIndices: Set<Int>) -> Bool {
        if currentIndex > 0 && replacedIndices.contains(currentIndex - 1) {
            return true
        }
        if currentIndex < replacedIndices.count - 1 && replacedIndices.contains(currentIndex + 1) {
            return true
        }
        return false
    }
    
    // MARK: 캔버스 뷰 관련
    @objc func drawingStarted() {
        userTestView.drawingLabel.isHidden = true
    }
    
    @objc private func trashTapped() {
        clearCanvas()
    }
    func clearCanvas(){
        userTestView.canvasView.drawing = PKDrawing()
        userTestView.drawingLabel.isHidden = false
    }
    
    @objc private func undoTapped() {
        userTestView.canvasView.undoManager?.undo()
    }
    
    @objc private func redoTapped() {
        userTestView.canvasView.undoManager?.redo()
    }
    
    // PKToolPicker : Palette
    @objc func paletteTapped() {
        print("팔레트 호출")
    }
    
    private func setupCanvasView() {
        userTestView.canvasView.drawingPolicy = .pencilOnly
        //userTestView.canvasView.allowsFingerDrawing = false
    }
    private func setUpTool() {
        if let window = UIApplication.shared.windows.first, let toolPicker =
            PKToolPicker.shared(for: window) {
            toolPicker.addObserver(userTestView.canvasView)
            toolPicker.setVisible(true, forFirstResponder: userTestView.canvasView)
            userTestView.canvasView.becomeFirstResponder()
        }
    }
    
    // 정답확인하기
    @objc func answerTapped() {
        if answerButton.title == "정답확인" {
            userTestView.serveTextView.text = originalText
            answerButton.title = "확인완료"
        } else {
            userTestView.serveTextView.text = pasteReceivedText
            answerButton.title = "정답확인"
        }
    }
    
    // CollectionView 저장
    @objc func saveTapped(){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
               return
           }
           
           let context = appDelegate.persistentContainer.newBackgroundContext()
           context.perform {
               let canvasData = NSEntityDescription.insertNewObject(forEntityName: "CanvasData", into: context)
               
               if self.userTestView.canvasView.drawing.bounds.isEmpty {
                   canvasData.setValue(nil, forKey: "canvasState") // Set canvasState as nil when no drawing is present
               } else {
                   let drawingData = NSKeyedArchiver.archivedData(withRootObject: self.userTestView.canvasView.drawing)
                   canvasData.setValue(drawingData, forKey: "canvasState")
               }
               
               // Capture image on the main thread
               DispatchQueue.main.async {
                   if let capturedImage = self.captureImage() {
                       let imageData = capturedImage.jpegData(compressionQuality: 1.0)
                       canvasData.setValue(imageData, forKey: "imageData")
                   }
                   
                   do {
                       try context.save()
                       print("데이터 저장 성공")
                       
                       // Move to CollectionViewController
                       DispatchQueue.main.async {
                           let collectionViewController = CollectionViewController() // 실제 CollectionViewController 인스턴스를 초기화하는 코드로 대체해야 합니다.
                           self.navigationController?.pushViewController(collectionViewController, animated: true)
                       }
                   } catch {
                       print("데이터 저장 실패: \(error.localizedDescription)")
                   }
               }
           }
           
    }
    
    // CollectionView에 Cell로 저장할때의 캡쳐 이미지 함수
    func captureImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(userTestView.canvasView.bounds.size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        userTestView.canvasView.drawHierarchy(in: userTestView.canvasView.bounds, afterScreenUpdates: true)
        let captureImage = UIGraphicsGetImageFromCurrentImageContext()
        return captureImage
    }
}

