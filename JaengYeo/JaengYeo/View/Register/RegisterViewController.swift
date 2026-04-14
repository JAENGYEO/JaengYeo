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

protocol RegisterViewControllerDelegate: AnyObject {
    func pushItemListView(items: [RegisterFormData], pageTitle: String, showInfoLabel: Bool)
}

final class RegisterViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    
    weak var delegate: RegisterViewControllerDelegate?
    
    private let viewModel: RegisterViewModel
    private let aiCapturedSubject = PublishSubject<Data>()
    private let receiptCapturedSubject = PublishSubject<UIImage>()
    
    private let mainView = RegisterView()
    
    private let captureSession = AVCaptureSession() // 카메라 입출력 연결
    private var previewLayer: AVCaptureVideoPreviewLayer? // 카메라 화면 레이어
    private var currentCameraPosition: AVCaptureDevice.Position = .back
    private let photoOutput = AVCapturePhotoOutput() // 출력 객체
    
    private var currentMode: CameraMode = .barcode
    
    init(viewModel: RegisterViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
                self?.delegate?.pushItemListView(items: [], pageTitle: "직접 입력", showInfoLabel: false)
            })
            .disposed(by: disposeBag)
        mainView.flipButton.rx.tap
            .bind(onNext: { [weak self] in
                self?.flipCamera()
            })
            .disposed(by: disposeBag)
        
        mainView.captureButton.rx.tap
            .bind(onNext: { [weak self] in
                self?.handleCaptureButtonTapped()
            })
            .disposed(by: disposeBag)
        
        //TODO: AI Response 로직 구현 필요 -> RegisterFormView 생성 이후 작업
        let input = RegisterViewModel.Input(
            aiCaptured: aiCapturedSubject,
            receiptCaptured: receiptCapturedSubject
        )
        let output = viewModel.transform(input)
        
        output.aiResponseData
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] items in
                guard let self else { return }
                switch items.count {
                case 0:
                    self.showErrorAlert(title: "인식 실패", message: "인식된 항목이 없습니다.")
                default:
                    self.delegate?.pushItemListView(items: items, pageTitle: "AI 인식 결과", showInfoLabel: true)
                }
            })
            .disposed(by: disposeBag)
        
        output.isLoading
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] isLoading in
                isLoading ? self?.mainView.startScanAnimation() : self?.mainView.stopScanAnimation()
                self?.mainView.captureButton.isEnabled = !isLoading
            })
            .disposed(by: disposeBag)
        
        output.error
            .observe(on: MainScheduler.instance)
            .bind(onNext: { [weak self] error in
                self?.showErrorAlert(title: "오류", message: error)
            })
            .disposed(by: disposeBag)
        
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

extension RegisterViewController {
    private func handleCaptureButtonTapped() { //TODO: case에 따라 분리처리 필요
        guard currentMode == .aiVision || currentMode == .receipt else { return }
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension RegisterViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        
        switch currentMode {
        case .receipt:
            let resizedImage = image.resized(maxDimension: 1024)
            receiptCapturedSubject.onNext(resizedImage)
        case .aiVision:
            guard let compressedData = image.resized(maxDimension: 512).jpegData(compressionQuality: 0.6) else { return }
            aiCapturedSubject.onNext(compressedData)
        default:
            break
        }
    }
}

extension RegisterViewController {
    private func showErrorAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}
