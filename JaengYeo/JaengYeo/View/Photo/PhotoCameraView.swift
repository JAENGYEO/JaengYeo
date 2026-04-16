//
//  PhotoCameraView.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/16/26.
//

import UIKit
import SnapKit
import Then

final class PhotoCameraView: UIView {
    
    let topContainerView = UIView().then {
        $0.backgroundColor = .black
    }
    
    let previewView = UIView().then {
        $0.backgroundColor = .systemGray
        $0.clipsToBounds = true
    }
    
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
    
    let closeButton = UIButton().then {
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        $0.setImage(UIImage(systemName: "xmark.circle", withConfiguration: symbolConfig), for: .normal)
        $0.tintColor = .white
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
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

extension PhotoCameraView {
    private func setLayout() {
        backgroundColor = .black
        
        [topContainerView, previewView, bottomControlView].forEach { addSubview($0) }
        [captureRingView, flipButton, closeButton].forEach { bottomControlView.addSubview($0) }
        captureRingView.addSubview(captureButton)
        
        topContainerView.snp.makeConstraints {
            $0.top.equalTo(safeAreaLayoutGuide).offset(24)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(58)
        }
        
        previewView.snp.makeConstraints {
            $0.top.equalTo(topContainerView.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(bottomControlView.snp.top)
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
        
        closeButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(32)
            $0.centerY.equalTo(captureRingView)
        }
    }
}

extension PhotoCameraView {
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
