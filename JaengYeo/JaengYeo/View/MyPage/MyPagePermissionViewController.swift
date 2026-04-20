//
//  MyPagePermissionViewController.swift
//  JaengYeo
//
//  Created by Codex on 4/20/26.
//


import UIKit
import RxRelay
import RxSwift
import RxCocoa

final class MyPagePermissionViewController: BaseViewController {

    //MARK: - ViewModel
    private let viewModel: MyPagePermissionViewModel

    //MARK: - Properties
    private let disposeBag = DisposeBag()
    private let viewWillAppearRelay = PublishRelay<Void>()

    //MARK: - Components
    private let myPagePermissionView = MyPagePermissionView()

    //MARK: - Init
    init(viewModel: MyPagePermissionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = myPagePermissionView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewWillAppearRelay.accept(())
    }
}

//MARK: - Binding
extension MyPagePermissionViewController {
    func bind() {
        let input = MyPagePermissionViewModel.Input(
            viewDidLoad: Observable.just(()),
            viewWillAppear: Observable.merge(
                viewWillAppearRelay.asObservable(),
                NotificationCenter.default.rx.notification(
                    UIApplication.didBecomeActiveNotification
                )
                .map { _ in }
            ),
            permissionToggled: myPagePermissionView.permissionToggled
        )

        let output = viewModel.transform(input)

        /// 권한 목록 바인딩
        output.permissionItems
            .bind(onNext: { [weak self] items in
                self?.myPagePermissionView.applySnapshot(with: items)
            })
            .disposed(by: disposeBag)

        /// 권한 안내 알림 표시
        output.presentPermissionAlert
            .bind(onNext: { [weak self] content in
                self?.presentPermissionAlert(content)
            })
            .disposed(by: disposeBag)
        
        /// 앱 설정 이동
        output.openSettings
            .bind(onNext: { url in
                UIApplication.shared.open(url)
            })
            .disposed(by: disposeBag)
    }
}

//MARK: - Present
extension MyPagePermissionViewController {
    /// 권한 안내 알림 표시
    func presentPermissionAlert(_ content: MyPagePermissionAlertContent) {
        let alert = UIAlertController(
            title: content.title,
            message: content.message,
            preferredStyle: .alert
        )
        
        alert.addAction(
            UIAlertAction(
                title: "설정으로 이동",
                style: .default
            ) { [weak self] _ in
                self?.openAppSettings()
            }
        )
        alert.addAction(
            UIAlertAction(
                title: "취소",
                style: .cancel
            ) { [weak self] _ in
                self?.viewWillAppearRelay.accept(())
            }
        )
        
        present(alert, animated: true)
    }
    
    /// 앱 설정 열기
    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        UIApplication.shared.open(url)
    }
}

//MARK: - Configure
extension MyPagePermissionViewController {
    /// 네비게이션 바 설정
    func configureNavigationBar() {
        title = "앱 사용 권한 확인"

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .font: LabelConfiguration.titleSemi18.font,
            .foregroundColor: UIColor.gray800
        ]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .gray800
    }
}

#Preview {
    UINavigationController(
        rootViewController: MyPagePermissionViewController(
            viewModel: MyPagePermissionViewModel()
        )
    )
}
