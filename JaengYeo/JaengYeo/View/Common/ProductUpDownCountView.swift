//
//  ProductUpDownCountView.swift
//  JaengYeo
//
//  Created by Hanjuheon on 4/22/26.
//

import RxCocoa
import RxRelay
import RxSwift
import SnapKit
import Then
import UIKit

final class ProductUpDownCountView: UIView {

    //MARK: - Properties
    private let disposeBag = DisposeBag()
    private let addButtonTapRelay = PublishRelay<Void>()
    private let deleteButtonTapRelay = PublishRelay<Void>()
    private var repeatTimer: Timer?

    //MARK: - Components
    private let upButton = UIButton()
    private let downButton = UIButton()

    private let upImageView = UIImageView().then {
        $0.image = UIImage(named: "addCircle")
        $0.contentMode = .scaleAspectFit
        $0.isUserInteractionEnabled = false
    }

    private let downImageView = UIImageView().then {
        $0.image = UIImage(named: "deleteCircle")
        $0.contentMode = .scaleAspectFit
        $0.isUserInteractionEnabled = false
    }

    private let countLabel = StyledLabel(config: .titleSemi18).then {
        $0.text = "0"
        $0.numberOfLines = 1
    }

    //MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
        configureAction()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        stopRepeating()
    }
}

//MARK: - Public
extension ProductUpDownCountView {
    /// 수량 추가 버튼 선택 이벤트
    var addButtonTap: Observable<Void> {
        addButtonTapRelay.asObservable()
    }

    /// 수량 차감 버튼 선택 이벤트
    var deleteButtonTap: Observable<Void> {
        deleteButtonTapRelay.asObservable()
    }

    /// 수량 표시 업데이트
    func updateUI(count: Int?) {
        countLabel.text = count.map { String($0) } ?? "0"
    }
}

//MARK: - Configure Action
private extension ProductUpDownCountView {
    /// 버튼 이벤트 설정
    func configureAction() {
        upButton.rx.tap
            .bind(to: addButtonTapRelay)
            .disposed(by: disposeBag)

        downButton.rx.tap
            .bind(to: deleteButtonTapRelay)
            .disposed(by: disposeBag)

        bindLongPress(
            button: upButton,
            relay: addButtonTapRelay
        )
        bindLongPress(
            button: downButton,
            relay: deleteButtonTapRelay
        )
    }

    /// 롱프레스 이벤트 바인딩
    func bindLongPress(
        button: UIButton,
        relay: PublishRelay<Void>
    ) {
        let longPress = UILongPressGestureRecognizer()
        longPress.minimumPressDuration = 0.35
        button.addGestureRecognizer(longPress)

        longPress.rx.event
            .bind(onNext: { [weak self] gesture in
                switch gesture.state {
                case .began:
                    self?.startRepeating(relay: relay)
                case .ended, .cancelled, .failed:
                    self?.stopRepeating()
                default:
                    break
                }
            })
            .disposed(by: disposeBag)
    }

    /// 반복 이벤트 시작
    func startRepeating(relay: PublishRelay<Void>) {
        stopRepeating()
        relay.accept(())

        repeatTimer = Timer.scheduledTimer(
            withTimeInterval: 0.07,
            repeats: true
        ) { _ in
            relay.accept(())
        }
    }

    /// 반복 이벤트 종료
    func stopRepeating() {
        repeatTimer?.invalidate()
        repeatTimer = nil
    }
}

//MARK: - Configure UI
private extension ProductUpDownCountView {
    /// UI 설정
    func configureUI() {
        addSubview(upButton)
        addSubview(downButton)
        addSubview(countLabel)

        upButton.addSubview(upImageView)
        downButton.addSubview(downImageView)

        downButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.leading.equalToSuperview()
            $0.size.equalTo(38)
        }

        countLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
        }

        upButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.trailing.equalToSuperview()
            $0.size.equalTo(38)
        }

        upImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(22)
        }

        downImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.size.equalTo(22)
        }
    }
}
