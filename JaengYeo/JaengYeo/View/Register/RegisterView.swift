//
//  RegisterView.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/8/26.
//

import UIKit
import SnapKit
import Then

//TODO: Icon 수정 필요! 테스트용도로 만든 화면이라 SF Symbols로 연결
final class RegisterView: UIView {
    
    // 상단 Container
    let modeContainerView = UIView().then {
        $0.backgroundColor = .black
    }
    
    // 버튼 스택뷰, 각 버튼들
    let modeStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.distribution = .fillEqually
        $0.spacing = 4
    }
    let barcodeButton = UIButton()
    let receiptButton = UIButton()
    let aiVisionButton = UIButton()
    let manualButton = UIButton()
    
    // 카메라 화면 preview
    let previewView = UIView().then {
        $0.backgroundColor = .systemGray
        $0.clipsToBounds = true
    }
    
    let scanLineView = UIView().then {
        $0.isHidden = true
    }
    
    // 하단 Container
    let bottomControlView = UIView().then {
        $0.backgroundColor = .black
    }
    
    private var gradientRingLayer: CAGradientLayer?
    
    // 촬영버튼 View -> Ring용
    let captureRingView = UIView().then {
        $0.backgroundColor = .clear
    }
    
    // 촬영버튼
    let captureButton = UIButton().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 30
    }
    
    // 전환버튼
    let flipButton = UIButton().then {
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        $0.setImage(UIImage(systemName: "camera.rotate", withConfiguration: symbolConfig), for: .normal)
        $0.tintColor = .white
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configModeButton(button: barcodeButton, symbol: "barcode.viewfinder", title: "바코드")
        configModeButton(button: receiptButton, symbol: "doc.text.viewfinder", title: "영수증")
        configModeButton(button: aiVisionButton, symbol: "sparkles", title: "AI인식")
        configModeButton(button: manualButton, symbol: "square.and.pencil", title: "직접입력")
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setGradientRing(view: captureRingView)
    }
}

extension RegisterView {
    private func setLayout() {
        backgroundColor = .black
        
        [modeContainerView, previewView, bottomControlView].forEach { addSubview($0) }
        modeContainerView.addSubview(modeStackView)
        previewView.addSubview(scanLineView)
        [barcodeButton, receiptButton, aiVisionButton, manualButton].forEach { modeStackView.addArrangedSubview($0) }
        [captureRingView, flipButton].forEach { bottomControlView.addSubview($0) }
        captureRingView.addSubview(captureButton)
        
        modeContainerView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(24)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(58)
        }
        
        modeStackView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        previewView.snp.makeConstraints {
            $0.top.equalTo(modeContainerView.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(bottomControlView.snp.top)
        }
        
        scanLineView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.top.equalToSuperview()
            $0.height.equalTo(2)
        }
        
        bottomControlView.snp.makeConstraints {
            $0.top.equalTo(captureRingView.snp.top).offset(-24)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
        captureRingView.snp.makeConstraints {
            $0.size.equalTo(76)
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(safeAreaLayoutGuide).offset(-24)
        }
        
        captureButton.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(60)
        }
        
        flipButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-32)
            $0.centerY.equalTo(captureRingView)
        }
    }
}


extension RegisterView {
    
    // 버튼 속성 정의 메서드
    private func configModeButton(button: UIButton, symbol: String, title: String) {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: symbol)
        config.title = title
        config.imagePlacement = .top
        config.imagePadding = 4
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0)
        config.baseForegroundColor = .white
        config.background.backgroundColor = .clear
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attribute in
            var out = attribute
            out.font = LabelConfiguration.body14.font
            return out
        }
        button.configuration = config
        button.layer.cornerRadius = 8
        button.configurationUpdateHandler = { button in
            var config = button.configuration ?? .plain()
            config.background.backgroundColor = .clear
            config.baseForegroundColor = button.isSelected ? .black : .white
            button.backgroundColor = button.isSelected ? .white : .clear
            button.configuration = config
        }
    }
    
    // Ring 그라데이션 적용
    private func setGradientRing(view: UIView) {
        guard gradientRingLayer == nil else { return }
        guard view.bounds != .zero else { return }
        let primary100 = UIColor(named: "Primary100") ?? .systemBlue
        let primary600 = UIColor(named: "Primary600") ?? .systemBlue
        
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [primary100.cgColor, primary600.cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        
        let shape = CAShapeLayer()
        shape.lineWidth = 4
        shape.path = UIBezierPath(ovalIn: view.bounds.insetBy(dx: 2, dy: 2)).cgPath
        shape.strokeColor = UIColor.black.cgColor
        shape.fillColor = UIColor.clear.cgColor
        gradient.mask = shape
        
        view.layer.addSublayer(gradient)
        gradientRingLayer = gradient
    }
}

extension RegisterView {
    
    // 버튼 선택 시 모드 전환용 메서드
    func updateModeSelection(cameraMode: CameraMode) {
        let allButtons: [(UIButton, CameraMode)] = [
            (barcodeButton, .barcode),
            (receiptButton, .receipt),
            (aiVisionButton, .aiVision),
            (manualButton, .manual)
        ]
        allButtons.forEach { button, mode in
            button.isSelected = (mode == cameraMode)
        }
    }
}

//TODO: 영수증, AI인식 시 사용할 애니메이션 (몇회 반복, 속도 정해지지 않음. 그라데이션 적용 안됨)
extension RegisterView {
    func startScanAnimation() {
        scanLineView.isHidden = false
        previewView.bringSubviewToFront(scanLineView)
        
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(x: 0, y:0, width: UIScreen.main.bounds.width, height: 2)
        gradient.colors = [
            UIColor.clear.cgColor,
            UIColor(named: "Primary300")?.cgColor ?? UIColor.systemBlue.cgColor,
            UIColor.clear.cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        scanLineView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        scanLineView.layer.addSublayer(gradient)
        
        UIView.animate(
            withDuration: 1.8, delay: 0,
            options: [.repeat, .autoreverse, .curveEaseInOut],
            animations: {
                self.scanLineView.transform = CGAffineTransform(
                    translationX: 0, y: self.previewView.bounds.height
                )
            }
        )
    }
    
    func stopScanAnimation() {
        scanLineView.isHidden = true
        scanLineView.layer.removeAllAnimations()
        scanLineView.transform = .identity
    }
}
