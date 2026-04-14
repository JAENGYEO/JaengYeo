//
//  CategoryEditViewController.swift
//  JaengYeo
//
//  Created by Codex on 4/14/26.
//

import SnapKit
import Then
import UIKit

final class CategoryEditViewController: UIViewController {

    //MARK: - Components
    private let emptyLabel = StyledLabel(config: .bodyMedium14).then {
        $0.text = "분류 편집 화면"
        $0.textAlignment = .center
        $0.updateColor(.gray500)
    }

    //MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureUI()
    }
}

//MARK: - Configure UI
private extension CategoryEditViewController {
    /// 네비게이션 바 설정
    func configureNavigationBar() {
        title = "분류 편집"
    }

    /// UI 설정
    func configureUI() {
        view.backgroundColor = .gray50

        view.addSubview(emptyLabel)

        emptyLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
}

#Preview {
    UINavigationController(rootViewController: CategoryEditViewController())
}
