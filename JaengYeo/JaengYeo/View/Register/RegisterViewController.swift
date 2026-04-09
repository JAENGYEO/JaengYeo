//
//  RegisterViewController.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/7/26.
//

import UIKit
import AVFoundation
import RxSwift
import RxCocoa

final class RegisterViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    
    private let mainView = RegisterView()
    
    private let captureSession = AVCaptureSession() // 카메라 입출력 연결
    private var previewLayer: AVCaptureVideoPreviewLayer? // 카메라 화면 레이어
    private var currentCameraPosition: AVCaptureDevice.Position = .back
    private let photoOutput = AVCapturePhotoOutput() // 출력 객체
    
    private var currentMode: CameraMode = .barcode
    
    private let sessionQueue = DispatchQueue(label: "com.jaengyeo.camera.session")
    
    override func loadView() {
        self.view = mainView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkCameraPermission()
        bind()
        mainView.updateModeSelection(cameraMode: currentMode)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = mainView.previewView.bounds
    }
    
    // 네비게이션 바 hidden: true
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
        if captureSession.isRunning == false {
            DispatchQueue.global(qos: .background).async {
                self.captureSession.startRunning()
            }
        }
    }
    
    // 네비게이션 바 hidden: false
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.isHidden = false
        DispatchQueue.global(qos: .background).async {
            self.captureSession.stopRunning()
        }
    }
}

extension RegisterViewController {
    private func bind() {
        mainView.barcodeButton.rx.tap
            .bind(onNext: { [weak self] in
                self?.switchMode(mode: .barcode)
            })
            .disposed(by: disposeBag)
        mainView.receiptButton.rx.tap
            .bind(onNext: { [weak self] in
                self?.switchMode(mode: .receipt)
            })
            .disposed(by: disposeBag)
        mainView.aiVisionButton.rx.tap
            .bind(onNext: { [weak self] in
                self?.switchMode(mode: .aiVision)
            })
            .disposed(by: disposeBag)
        mainView.manualButton.rx.tap
            .bind(onNext: { [weak self] in
                self?.switchMode(mode: .manual)
            })
            .disposed(by: disposeBag)
        mainView.flipButton.rx.tap
            .bind(onNext: { [weak self] in
                self?.flipCamera()
            })
            .disposed(by: disposeBag)
        
        //        registerView.captureButton.rx.tap
        //            .bind(onNext: { [weak self] in
        //            })
        //            .disposed(by: disposeBag)
    }
    
    private func switchMode(mode: CameraMode) {
        currentMode = mode
        mainView.updateModeSelection(cameraMode: mode)
    }
}

//MARK: - 카메라 권한에 따라 case 분리
extension RegisterViewController {
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
}

//MARK: - 카메라 권한 요청
extension RegisterViewController {
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
}

extension RegisterViewController {
    
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
    
    // 카메라 전환
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
