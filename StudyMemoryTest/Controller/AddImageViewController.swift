//
//  AddImageViewController.swift
//  StudyMemoryTest
//
//  Created by 이상도 on 2023/05/18.
//

import UIKit
import AVFoundation
import Photos
import Vision

class AddImageViewController: UIViewController {
    
    private var addImageView : AddImageView! // View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addImageView = AddImageView(frame: view.bounds)
        view.addSubview(addImageView)
        
        // MARK: 네비게이션
        title = "오늘의 문제집" // 네비게이션 타이틀 제목
        navigationController?.navigationBar.tintColor = UIColor.black
        
        let addCameraButton = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(addCameraTapped))
        addCameraButton.tintColor = .black
        
        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))
        saveButton.tintColor = .black
        
        navigationItem.rightBarButtonItems = [ saveButton, addCameraButton ] // 네비게이션 버튼2개 배열로 할당
        
        
        addImageView.setImage(UIImage(named: "example1"))
        recognizerText(image: addImageView.imageView.image)
        
        /*
         let navigationBar = UINavigationBar(frame: CGRect(x:0, y:0, width:view.frame.size.width, height:view.frame.size.height))
         navigationBar.backgroundColor = .systemBlue
         
         let navigationItem = UINavigationItem(title: "오늘의 문제집")
         navigationBar.items = [navigationItem]
         view.addSubview(navigationBar)
         */
        
    }
    
    // MARK: Visision - Image -> Text
    private func recognizerText(image: UIImage?) { // 이미지는 선택사항
        guard let cgImage = image?.cgImage else { return } // Ui 이미지의 CG이미지 버전을 얻는 것
        
        // Handler
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // Reqeust ( 텍스트 감지를 위한 요청 생성 )
        let request = VNRecognizeTextRequest{ [weak self] request, error in
            // 실제 관찰된 정보 가져오기 ( request.results = 관찰 / 여기에서 문자열을 가져오고 )
            guard let observations = request.results as? [VNRecognizedTextObservation],
                  error == nil else {
                return
            }
            
            // 압축매핑
            let text = observations.compactMap({
                $0.topCandidates(1).first?.string
            }).joined(separator:"\n") // 줄바꿈으로 구분
            
            DispatchQueue.main.async {
                self?.addImageView.setLabelText(text)
            }
        }
        
        // 텍스트 감지 언어 -> 한국어, 영어
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["ko","en"]
        request.usesLanguageCorrection = true
        request.revision = VNRecognizeTextRequestRevision3
        
        // Process request
        do {
            try handler.perform([request]) // Handler에서 요청 수행
        }
        catch {
            addImageView.setLabelText("\(error)")
        }
        
    }
    
    
    // 카메라 선택
    @objc func addCameraTapped() {
        checkCameraPermissions()
        checkAlbumPermission()
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        let alertController = UIAlertController(title: "사진 선택", message: nil, preferredStyle: .actionSheet)
        
        let cameraAction = UIAlertAction(title: "카메라", style: .default) { _ in
            imagePicker.sourceType = .camera
            self.present(imagePicker, animated: true, completion: nil)
        }
        alertController.addAction(cameraAction)
        
        let albumAction = UIAlertAction(title: "앨범", style: .default) { _ in
            imagePicker.sourceType = .photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
        }
        alertController.addAction(albumAction)
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        present(alertController, animated: true, completion: nil)
        
    }
    
    // Camera -> 사진 추가 or 추
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[.originalImage] as? UIImage {
            addImageView.imageView.image = image
            recognizerText(image: image)
        }
        picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    // 카메라 Permission
    func checkCameraPermissions() {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
            if granted {
                print("Camera: 권한 허용")
            } else {
                print("Camera: 권한 거부")
            }
            
        })
    }
    // 앨범 Permission
    func checkAlbumPermission() {
        PHPhotoLibrary.requestAuthorization( { status in
            switch status {
            case .authorized:
                print("Album : 권한 허용")
            case .denied:
                print("Album : 권한 거부")
            case .restricted, .notDetermined:
                print("Album : 선택되지 않음")
            default:
                break
            }
        })
    }
    
    @objc func saveTapped() {
        
    }
    
}


extension AddImageViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    
}