//
//  PhotoCameraViewController.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/16/26.
//

import UIKit
import AVFoundation
import RxSwift
import RxCocoa

final class PhotoCameraViewController: UIViewController {
    
    let photoCaptured = PublishRelay<UIImage>()
    
    private let disposeBag = DisposeBag()
    private let mainView = PhotoCameraView()
    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var currentCameraPosition: AVCaptureDevice.Position = .back
    private let photoOutput = AVCapturePhotoOutput()
    
    override func loadView() {
        self.view = mainView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkCameraPermission()
        bind()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = mainView.previewView.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if captureSession.isRunning == false {
            DispatchQueue.global(qos: .background).async {
                self.captureSession.startRunning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DispatchQueue.global(qos: .background).async {
            self.captureSession.stopRunning()
        }
    }
}

extension PhotoCameraViewController {
    private func bind() {
        mainView.captureButton.rx.tap
            .bind(onNext: { [weak self] in
                guard let self else { return }
                let settings = AVCapturePhotoSettings()
                photoOutput.capturePhoto(with: settings, delegate: self)
            })
            .disposed(by: disposeBag)
        
        mainView.flipButton.rx.tap
            .bind(onNext: { [weak self] in
                self?.flipCamera()
            })
            .disposed(by: disposeBag)
        
        mainView.closeButton.rx.tap
            .bind(onNext: { [weak self] in
                self?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
    }
}

extension PhotoCameraViewController {
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else { return }
                self?.setCaptureSession()
            }
        default:
            showPermissionAlert()
        }
    }
    
    private func showPermissionAlert() {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "카메라 권한 필요",
                message: "카메라 사용을 위해 설정에서 권한을 허용해주세요..",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            })
            alert.addAction(UIAlertAction(title: "취소", style: .cancel))
            self.present(alert, animated: true)
        }
    }
    
    private func setCaptureSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            // 세션 설정 시작
            self.captureSession.beginConfiguration()
            
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                self.captureSession.commitConfiguration()
                return
            }
            // canAdd 없이 추가 시 크래시 발생
            if self.captureSession.canAddInput(input) {
                self.captureSession.addInput(input)
            }
            if self.captureSession.canAddOutput(self.photoOutput) {
                self.captureSession.addOutput(self.photoOutput)
            }
            self.captureSession.commitConfiguration()
            self.captureSession.startRunning()
            
            // 카메라 피드를 화면에 그림: layer에 추가
            DispatchQueue.main.async { [weak self] in
                guard let self, self.previewLayer == nil else { return }
                let layer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                layer.frame = self.mainView.previewView.bounds
                layer.videoGravity = .resizeAspectFill
                self.mainView.previewView.layer.addSublayer(layer)
                self.previewLayer = layer
            }
        }
    }
    
    private func flipCamera() {
        currentCameraPosition = currentCameraPosition == .back ? .front : .back
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            captureSession.beginConfiguration()
            captureSession.inputs.forEach { self.captureSession.removeInput($0) }
            
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition),
                  let input = try? AVCaptureDeviceInput(device: device),
                  captureSession.canAddInput(input) else {
                captureSession.commitConfiguration()
                return
            }
            captureSession.addInput(input)
            captureSession.commitConfiguration()
        }
    }
}

extension PhotoCameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        
        DispatchQueue.main.async { [weak self] in
            self?.photoCaptured.accept(image)
            self?.dismiss(animated: true)
        }
    }
}
