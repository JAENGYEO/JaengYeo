//
//  StyledLabel.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/7/26.
//

import UIKit

/// 스타일 라벨 컴포넌트
final class StyledLabel: UILabel, ConfigurableLabel {
    
    // MARK: - Properites
    /// Label Configuration
    var labelConfiguration: LabelConfiguration? {
        didSet {
            reapplyConfiguration()
        }
    }
    
    /// Label Text
    override var text: String? {
        didSet {
            reapplyConfiguration()
        }
    }
    
    // MARK: - Init
    convenience init(config: LabelConfiguration) {
        self.init()
        self.labelConfiguration = config
    }
}

// MARK: - ConfigurableLabel setting
extension StyledLabel{
    /// Text Configuration 설정 메소드
    func reapplyConfiguration() {
        guard let config = labelConfiguration else { return }
        
        font = config.font
        textColor = config.color
        numberOfLines = config.lines
        
        guard let text, !text.isEmpty else {
            attributedText = nil
            return
        }
        
        attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: config.font,
                .foregroundColor: config.color,
                .kern: config.kern
            ]
        )
    }
    
    /// Update Configuration Color 메소드
    func updateColor(_ color: UIColor) {
        guard let config = labelConfiguration else { return }
        labelConfiguration = config.updatingColor(color: color)
    }
}
