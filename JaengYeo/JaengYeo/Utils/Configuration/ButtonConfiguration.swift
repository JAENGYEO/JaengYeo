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
    let selectedColor: UIColor
    let disabledColor: UIColor
    let kern: CGFloat
    
    /// 색상 변환 메소드
    func updatingColor(
           normalColor: UIColor? = nil,
           selectedColor: UIColor? = nil,
           disabledColor: UIColor? = nil
       ) -> ButtonTitleConfiguration {
           .init(
               font: font,
               normalColor: normalColor ?? self.normalColor,
               selectedColor: selectedColor ?? self.selectedColor,
               disabledColor: disabledColor ?? self.disabledColor,
               kern: kern
           )
       }
}

/// Button Appearance Configuration 구조체
struct ButtonAppearanceConfiguration {
    let backgroundColor: UIColor
    let selectedBackgroundColor: UIColor
    let highlightedBackgroundColor: UIColor
    let disabledBackgroundColor: UIColor
    let cornerRadius: CGFloat
    let borderWidth: CGFloat
    let borderColor: UIColor
    
    /// 색상 변환 메소드
    func updatingColor(
        backgroundColor: UIColor? = nil,
        selectedBackgroundColor: UIColor? = nil,
        highlightedBackgroundColor: UIColor? = nil,
        disabledBackgroundColor: UIColor? = nil,
    ) -> ButtonAppearanceConfiguration {
        .init(backgroundColor: backgroundColor ?? self.backgroundColor,
              selectedBackgroundColor: selectedBackgroundColor ?? self.selectedBackgroundColor,
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
    static let textTitle = ButtonTitleConfiguration(
        font: .systemFont(ofSize: 14, weight: .bold),
        normalColor: .accent,
        selectedColor: .white,
        disabledColor: .gray500,
        kern: -0.15
    )
    
    static let textTitle12 = ButtonTitleConfiguration (
        font: .systemFont(ofSize: 12, weight: .regular),
        normalColor: .accent,
        selectedColor: .white,
        disabledColor: .gray500,
        kern: -0.15
    )
    
    static let textGrayTitle12 = ButtonTitleConfiguration (
        font: .systemFont(ofSize: 12, weight: .regular),
        normalColor: .gray800,
        selectedColor: .white,
        disabledColor: .gray800,
        kern: -0.15

    )
    
    static let defaultTitle = ButtonTitleConfiguration (
        font: .systemFont(ofSize: 14, weight: .medium),
        normalColor: .white,
        selectedColor: .white,
        disabledColor: .gray500,
        kern: -0.15
    )
    
    /// 메인 컬러 텍스트 설정
    static let textEdgeTitle = ButtonTitleConfiguration (
        font: .systemFont(ofSize: 14, weight: .bold),
        normalColor: .gray500,
        selectedColor: .accent,
        disabledColor: .white,
        kern: -0.15
    )
    
    static let redTitle = ButtonTitleConfiguration (
        font: .systemFont(ofSize: 14, weight: .medium),
        normalColor: .primaryRed,
        selectedColor: .white,
        disabledColor: .gray500,
        kern: -0.15
    )
    
    static let categoryTitle = ButtonTitleConfiguration (
        font: .systemFont(ofSize: 12, weight: .regular),
        normalColor: .gray800,
        selectedColor: .white,
        disabledColor: .white,
        kern: -0.15
    )
}


//MARK: - Setting ButtonAppearanceConfiguration
extension ButtonAppearanceConfiguration {
    /// 타이틀만 표출되는 디자인
    static let textAppearance = ButtonAppearanceConfiguration(
        backgroundColor: UIColor.clear,
        selectedBackgroundColor: UIColor.clear,
        highlightedBackgroundColor: UIColor.clear,
        disabledBackgroundColor: UIColor.clear,
        cornerRadius: 0,
        borderWidth: 0,
        borderColor: UIColor.clear
    )
    
    static let defaultAppearance = ButtonAppearanceConfiguration(
        backgroundColor: .accent,
        selectedBackgroundColor: .accent,
        highlightedBackgroundColor: .primary700,
        disabledBackgroundColor: UIColor.clear,
        cornerRadius: 12,
        borderWidth: 0,
        borderColor: UIColor.clear

    )
    
    static let textEdgeAppearance = ButtonAppearanceConfiguration(
        backgroundColor: .white,
        selectedBackgroundColor: .white,
        highlightedBackgroundColor: .accent,
        disabledBackgroundColor: UIColor.clear,
        cornerRadius: 12,
        borderWidth: 2,
        borderColor: .gray300
    )
    
    static let redAppearance = ButtonAppearanceConfiguration(
        backgroundColor: .primaryLightRed,
        selectedBackgroundColor: .primary700,
        highlightedBackgroundColor: UIColor.clear,
        disabledBackgroundColor: UIColor.clear,
        cornerRadius: 12,
        borderWidth: 0,
        borderColor: UIColor.clear
    )
    
    static let categoryAppearance = ButtonAppearanceConfiguration(
        backgroundColor: .white,
        selectedBackgroundColor: .accent,
        highlightedBackgroundColor: .primary300,
        disabledBackgroundColor: .primary300,
        cornerRadius: 15,
        borderWidth: 1,
        borderColor: .gray100
    )
}
