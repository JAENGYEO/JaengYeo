//
//  ButtonConfiguration.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/7/26.
//
import UIKit

/// Button Ttitle Configuration 구조체
struct ButtonTitleConfiguration {
    let font: UIFont
    let normalColor: UIColor
    let highlightedColor: UIColor
    let disabledColor: UIColor
    let kern: CGFloat
    
    /// 색상 변환 메소드
    func updatingColor(
           normalColor: UIColor? = nil,
           highlightedColor: UIColor? = nil,
           disabledColor: UIColor? = nil
       ) -> ButtonTitleConfiguration {
           .init(
               font: font,
               normalColor: normalColor ?? self.normalColor,
               highlightedColor: highlightedColor ?? self.highlightedColor,
               disabledColor: disabledColor ?? self.disabledColor,
               kern: kern
           )
       }
}

/// Button Appearance Configuration 구조체
struct ButtonAppearanceConfiguration {
    let backgroundColor: UIColor
    let highlightedBackgroundColor: UIColor
    let disabledBackgroundColor: UIColor
    let cornerRadius: CGFloat
    let borderWidth: CGFloat
    let borderColor: UIColor
    
    /// 색상 변환 메소드
    func updatingColor(
        backgroundColor: UIColor? = nil,
        highlightedBackgroundColor: UIColor? = nil,
        disabledBackgroundColor: UIColor? = nil
    ) -> ButtonAppearanceConfiguration {
        .init(backgroundColor: backgroundColor ?? self.backgroundColor,
              highlightedBackgroundColor: highlightedBackgroundColor ?? self.highlightedBackgroundColor,
              disabledBackgroundColor: disabledBackgroundColor ?? self.disabledBackgroundColor,
              cornerRadius: cornerRadius,
              borderWidth: borderWidth,
              borderColor: borderColor
        )
    }
}

protocol ConfigurableButton {
    var titleConfiguration: ButtonTitleConfiguration? { get set }
    var appearanceConfiguration: ButtonAppearanceConfiguration? { get set }
}

// MARK: - Setting ButtonTitleConfiguration
extension ButtonTitleConfiguration {
    /// 메인 컬러 텍스트 설정
    static let textPrimary = ButtonTitleConfiguration(
        font: .systemFont(ofSize: 14, weight: .bold),
        normalColor: .accent,
        highlightedColor: .white,
        disabledColor: .gray500,
        kern: -0.15
    )
}


//MARK: - Setting ButtonAppearanceConfiguration
extension ButtonAppearanceConfiguration {
    /// 타이틀만 표출되는 디자인
    static let textOnly = ButtonAppearanceConfiguration(
        backgroundColor: UIColor.clear,
        highlightedBackgroundColor: UIColor.clear,
        disabledBackgroundColor: UIColor.clear,
        cornerRadius: 0,
        borderWidth: 0,
        borderColor: .clear
    )
}
