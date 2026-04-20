//
//  LoginView.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/20/26.
//

import UIKit
import SnapKit
import Then
import AuthenticationServices

final class LoginView: UIView {
    
    private let mainContainer = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 80
    }
    
    private let subContainer = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 12
    }
    
    private let logoImageView = UIImageView().then {
        $0.image = .loginLogo
        $0.contentMode = .scaleAspectFit
    }
    
    private let subTitleLabel = UILabel().then {
        $0.text = "내 손안의 작은 우리집"
        $0.font = LabelConfiguration.titleSemi20.font
        $0.textColor = .black
        $0.textAlignment = .center
    }
    
    let appleLoginButton = ASAuthorizationAppleIDButton(
        authorizationButtonType: .signIn,
        authorizationButtonStyle: .black
    )
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LoginView {
    private func setLayout() {
        backgroundColor = .white
        [logoImageView, subTitleLabel].forEach { subContainer.addArrangedSubview($0) }
        [subContainer, appleLoginButton].forEach { mainContainer.addArrangedSubview($0) }
        
        addSubview(mainContainer)
        
        mainContainer.snp.makeConstraints {
            $0.centerX.centerY.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        subContainer.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
        }
        
        appleLoginButton.snp.makeConstraints {
            $0.height.equalTo(54)
        }
    }
}
