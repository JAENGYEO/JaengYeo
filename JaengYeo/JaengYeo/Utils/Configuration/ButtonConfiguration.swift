//
//  ButtonConfiguration.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/7/26.
//
import UIKit

struct ButtonTitleConfiguration {
    let font: UIFont
    let normalColor: UIColor
    let highlightedColor: UIColor
    let disabledColor: UIColor
    let kern: CGFloat
    
    func updatingColor(
           color: UIColor? = nil,
           highlightedColor: UIColor? = nil,
           disabledColor: UIColor? = nil
       ) -> ButtonTitleConfiguration {
           .init(
               font: font,
               normalColor: color ?? self.normalColor,
               highlightedColor: highlightedColor ?? self.highlightedColor,
               disabledColor: disabledColor ?? self.disabledColor,
               kern: kern
           )
       }
}

struct ButtonAppearanceConfiguration {
    let backgroundColor: UIColor
    let highlightBackgroundColor: UIColor
    let disabledBackgroundColor: UIColor
    let cornerRadius: CGFloat
    let borderWidth: CGFloat
    let borderColor: UIColor
}

struct ButtonConfiguration {
    let titleNormal: ButtonTitleConfiguration
    let appearance: ButtonAppearanceConfiguration
}


// MARK: - Setting ButtonTitleConfiguration
// MARK: - Title
extension ButtonTitleConfiguration {
    static let textPrimary = ButtonTitleConfiguration(
        font: .systemFont(ofSize: 28, weight: .bold),
        normalColor: .accent,
        highlightedColor: .white,
        disabledColor: .gray500,
        kern: -0.15
    )
}


//MARK: - Setting ButtonAppearanceConfiguration
extension ButtonAppearanceConfiguration {
    /// 카테고리
    static let textPrimary = ButtonAppearanceConfiguration(
        backgroundColor: UIColor.clear,
        highlightBackgroundColor: UIColor.clear,
        disabledBackgroundColor: UIColor.clear,
        cornerRadius: 0,
        borderWidth: 0,
        borderColor: .clear
    )
}
