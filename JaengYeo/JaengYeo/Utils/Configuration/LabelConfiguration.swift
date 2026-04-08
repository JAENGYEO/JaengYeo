//
//  LabelConfiguration.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/7/26.
//

import UIKit


/// UILabel 텍스트 스타일  구조체
struct LabelConfiguration {
    /// 폰트
    let font: UIFont
    /// 폰트 컬러
    let color: UIColor
    /// 라인갯수
    let lines: Int
    /// 텍스트 자간 값
    let kern: CGFloat
    
    /// 색상 변경 메소드
    func updatingColor(color: UIColor) -> LabelConfiguration {
        .init(
            font: font,
            color: color,
            lines: lines,
            kern: kern
        )
    }
}

//MARK: StyleLabelProtocol
protocol ConfigurableLabel: AnyObject {
    var labelConfiguration: LabelConfiguration? { get set }
    func reapplyConfiguration()
}


// MARK: - Title
extension LabelConfiguration {
    static let titleBold28 = LabelConfiguration(
        font: .systemFont(ofSize: 28, weight: .bold),
        color: .gray800,
        lines: 0,
        kern: -0.15
    )
    
    static let titleBold24 = LabelConfiguration(
        font: .systemFont(ofSize: 28, weight: .bold),
        color: .gray800,
        lines: 0,
        kern: -0.15
    )
 
    static let titleBold20 = LabelConfiguration(
        font: .systemFont(ofSize: 28, weight: .bold),
        color: .gray800,
        lines: 0,
        kern: -0.15
    )
 
    static let titleSemi20 = LabelConfiguration(
        font: .systemFont(ofSize: 20, weight: .semibold),
        color: .gray800,
        lines: 0,
        kern: -0.15
    )

    static let titleSemi18 = LabelConfiguration(
        font: .systemFont(ofSize: 18, weight: .semibold),
        color: .gray800,
        lines: 0,
        kern: -0.15
    )

    static let titleSemi16 = LabelConfiguration(
        font: .systemFont(ofSize: 16, weight: .semibold),
        color: .gray800,
        lines: 0,
        kern: -0.15
    )
}


//MARK: - Body
extension LabelConfiguration {
    static let bodyMedium14 = LabelConfiguration(
        font: .systemFont(ofSize: 14, weight: .medium),
        color: .gray800,
        lines: 0,
        kern: -0.15
    )
    
    static let bodyMedium12 = LabelConfiguration(
        font: .systemFont(ofSize: 12, weight: .medium),
        color: .gray800,
        lines: 0,
        kern: -0.15
    )
 
    static let body14 = LabelConfiguration(
        font: .systemFont(ofSize: 14, weight: .regular),
        color: .gray800,
        lines: 0,
        kern: -0.15
    )
 
    static let body12 = LabelConfiguration(
        font: .systemFont(ofSize: 12, weight: .regular),
        color: .gray800,
        lines: 0,
        kern: -0.15
    )
}
