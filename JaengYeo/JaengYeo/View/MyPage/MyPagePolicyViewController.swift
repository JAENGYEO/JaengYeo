//
//  MyPagePolicyViewController.swift
//  JaengYeo
//
//  Created by Codex on 4/20/26.
//

import RxCocoa
import RxSwift
import SnapKit
import Then
import UIKit

final class MyPagePolicyViewController: BaseViewController {

    //MARK: - ViewModel
    private let viewModel: MyPagePolicyViewModel

    //MARK: - Properties
    private let disposeBag = DisposeBag()

    //MARK: - Components
    private let scrollView = UIScrollView().then {
        $0.backgroundColor = .white
        $0.showsVerticalScrollIndicator = false
    }

    private let contentView = UIView().then {
        $0.backgroundColor = .white
    }

    private let titleLabel = StyledLabel(config: .titleSemi18).then {
        $0.textAlignment = .center
        $0.updateColor(.gray800)
    }

    private let bodyLabel = StyledLabel(config: .bodyMedium14).then {
        $0.numberOfLines = 0
        $0.updateColor(.gray500)
    }

    private let closeButton = UIButton(type: .custom).then {
        $0.setImage(UIImage(named: "closeIcon"), for: .normal)
        $0.tintColor = .gray800
    }

    //MARK: - Init
    init(viewModel: MyPagePolicyViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
    }
}

//MARK: - Binding
extension MyPagePolicyViewController {
    func bind() {
        let input = MyPagePolicyViewModel.Input(
            viewDidLoad: Observable.just(())
        )

        let output = viewModel.transform(input)

        /// 개인정보 처리방침 내용 바인딩
        output.content
            .bind(onNext: { [weak self] content in
                self?.titleLabel.text = content.title
                self?.bodyLabel.attributedText = self?.makeBodyAttributedText(
                    content
                )
            })
            .disposed(by: disposeBag)

        closeButton.rx.tap
            .bind(onNext: { [weak self] in
                self?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
    }
}

//MARK: - Configure
extension MyPagePolicyViewController {
    /// UI 설정
    func configureUI() {
        view.backgroundColor = .white

        view.addSubview(closeButton)
        view.addSubview(titleLabel)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(bodyLabel)

        closeButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            $0.leading.equalToSuperview().offset(16)
            $0.size.equalTo(24)
        }

        titleLabel.snp.makeConstraints {
            $0.centerY.equalTo(closeButton)
            $0.leading.equalTo(closeButton.snp.trailing).offset(16)
            $0.trailing.equalToSuperview().inset(56)
        }

        scrollView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(28)
            $0.leading.trailing.bottom.equalToSuperview()
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView)
        }

        bodyLabel.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.bottom.equalToSuperview().inset(24)
        }
    }
    
    /// 본문 강조 텍스트 생성
    func makeBodyAttributedText(
        _ content: MyPagePolicyContent
    ) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4

        let attributedString = NSMutableAttributedString(
            string: content.body,
            attributes: [
                .font: LabelConfiguration.bodyMedium14.font,
                .foregroundColor: UIColor.gray500,
                .paragraphStyle: paragraphStyle,
            ]
        )

        content.highlightedTexts.forEach {
            let range = (content.body as NSString).range(of: $0)
            guard range.location != NSNotFound else { return }

            attributedString.addAttributes(
                [
                    .font: LabelConfiguration.titleSemi18.font,
                    .foregroundColor: UIColor.gray800,
                ],
                range: range
            )
        }

        return attributedString
    }
}

#Preview {
    MyPagePolicyViewController(
        viewModel: MyPagePolicyViewModel()
    )
}
