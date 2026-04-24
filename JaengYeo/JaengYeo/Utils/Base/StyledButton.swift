//
//  StyledButton.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/7/26.
//

import UIKit

/// 스타일 버튼 컴포넌트
final class StyledButton: UIButton, ConfigurableButton {
    
    // MARK: - Properites
    /// 타이틀 스타일
    var titleConfiguration: ButtonTitleConfiguration? {
        didSet { applyConfiguration() }
    }
    ///  외형 스타일
    var appearanceConfiguration: ButtonAppearanceConfiguration? {
        didSet { applyConfiguration() }
    }
    
    override var isSelected: Bool {
        didSet {
            applyBackgroundColor()
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            applyBackgroundColor()
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            applyBackgroundColor()
        }
    }
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    convenience init(
        title: String,
        titleConfiguration: ButtonTitleConfiguration,
        appearanceConfiguration: ButtonAppearanceConfiguration
    ) {
        self.init(frame: .zero)
        self.titleConfiguration = titleConfiguration
        self.appearanceConfiguration = appearanceConfiguration
        setTitle(title, for: .normal)
        applyConfiguration()
    }
}

//MARK: - ConfigurableButton Setting
extension StyledButton {
    func updateTitle(_ title: String) {
        setTitle(title, for: .normal)
        
        guard let titleConfiguration else { return }
        applyAttributedTitle(config: titleConfiguration)
    }
    
    /// 버튼 스타일 외형 초기 설정
    private func applyConfiguration() {
        guard let titleConfiguration, let appearanceConfiguration else { return }
        
        layer.cornerRadius = appearanceConfiguration.cornerRadius
        layer.borderWidth = appearanceConfiguration.borderWidth
        layer.borderColor = appearanceConfiguration.borderColor.cgColor
        clipsToBounds = true
        
        applyAttributedTitle(config: titleConfiguration)
        applyBackgroundColor()
    }
    
    /// 버튼 타이틀 스타일 초기 설정
    private func applyAttributedTitle(config: ButtonTitleConfiguration) {
        let title = title(for: .normal) ?? ""
        
        let normalAttributedTitle = NSAttributedString(
            string: title,
            attributes: [
                .font: config.font,
                .foregroundColor: config.normalColor
            ]
        )
        
        let selectedAttributedTitle = NSAttributedString(
            string: title,
            attributes: [
                .font: config.font,
                .foregroundColor: config.selectedColor
            ]
        )
        
        let disabledAttributedTitle = NSAttributedString(
            string: title,
            attributes: [
                .font: config.font,
                .foregroundColor: config.disabledColor
            ]
        )
        
        setAttributedTitle(normalAttributedTitle, for: .normal)
        setAttributedTitle(selectedAttributedTitle, for: .selected)
        setAttributedTitle(disabledAttributedTitle, for: .disabled)
    }
    
    /// 버튼 액션에 따른 색상 변경 메소드
    private func applyBackgroundColor() {
        guard let appearanceConfiguration else { return }
        
        if !isEnabled {
            backgroundColor = appearanceConfiguration.disabledBackgroundColor
            return
        }
        
        if isHighlighted {
            backgroundColor = appearanceConfiguration.highlightedBackgroundColor
            return
        }
        
        if isSelected {
            backgroundColor = appearanceConfiguration.selectedBackgroundColor
            layer.borderColor = appearanceConfiguration.highlightedBackgroundColor.cgColor
            return
        }
        
        backgroundColor = appearanceConfiguration.backgroundColor
        layer.borderColor = appearanceConfiguration.borderColor.cgColor
    }
}
