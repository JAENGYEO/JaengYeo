//
//  DatePickerBottomSheetView.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/13/26.
//

import UIKit
import SnapKit
import Then

// MARK: - Calendar Cell

final class DatePickerCalendarCell: UICollectionViewCell {
    static let identifier = "DatePickerCalendarCell"

    private let dayLabel = UILabel().then {
        $0.textAlignment = .center
        $0.font = .systemFont(ofSize: 14, weight: .regular)
        $0.textColor = .gray800
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(dayLabel)
        contentView.clipsToBounds = true
        dayLabel.snp.makeConstraints { $0.center.equalToSuperview() }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layer.cornerRadius = contentView.bounds.width / 2
    }

    func configure(day: Int?, isSelected: Bool) {
        guard let day else {
            dayLabel.text = ""
            contentView.backgroundColor = .clear
            contentView.layer.borderWidth = 0
            return
        }
        dayLabel.text = "\(day)"
        dayLabel.font = .systemFont(ofSize: 14, weight: isSelected ? .medium : .regular)
        dayLabel.textColor = isSelected ? .accent : .gray800
        contentView.backgroundColor = isSelected ? UIColor(named: "primary50") : .clear
        contentView.layer.borderWidth = isSelected ? 1 : 0
        contentView.layer.borderColor = UIColor(named: "Primary100")?.cgColor
    }
}

// MARK: - Bottom Sheet View

final class DatePickerBottomSheetView: UIView {

    let dimmingView = UIView().then {
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        $0.alpha = 0
    }

    let contentView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 16
        $0.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        $0.clipsToBounds = true
    }

    private let handleView = UIView().then {
        $0.backgroundColor = .gray300
        $0.layer.cornerRadius = 2.5
    }

    // MARK: 캘린더 컨테이너

    let calendarContainerView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 12
        $0.clipsToBounds = true
    }

    // MARK: 월/년 헤더

    let monthYearLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16, weight: .semibold)
        $0.textColor = .gray800
    }

    let prevButton = UIButton().then {
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        $0.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        $0.tintColor = .accent
    }

    let nextButton = UIButton().then {
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        $0.setImage(UIImage(systemName: "chevron.right", withConfiguration: config), for: .normal)
        $0.tintColor = .accent
    }

    // MARK: 요일 헤더

    private let weekdayStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.distribution = .fillEqually
    }

    private let weekdays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

    // MARK: 날짜 그리드

    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 0
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isScrollEnabled = false
        cv.backgroundColor = .clear
        cv.register(DatePickerCalendarCell.self, forCellWithReuseIdentifier: DatePickerCalendarCell.identifier)
        return cv
    }()

    // MARK: 확인 버튼

    let confirmButton = UIButton().then {
        $0.setTitle("완료", for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        $0.backgroundColor = .accent
        $0.layer.cornerRadius = 12
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupWeekdayHeader()
        setLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupWeekdayHeader() {
        weekdays.forEach { day in
            let label = UILabel().then {
                $0.text = day
                $0.font = .systemFont(ofSize: 12, weight: .regular)
                $0.textColor = .gray300
                $0.textAlignment = .center
            }
            weekdayStackView.addArrangedSubview(label)
        }
    }

    private func setLayout() {
        [dimmingView, contentView].forEach { addSubview($0) }
        [handleView, calendarContainerView, confirmButton].forEach { contentView.addSubview($0) }
        [monthYearLabel, prevButton, nextButton, weekdayStackView, collectionView].forEach {
            calendarContainerView.addSubview($0)
        }

        dimmingView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        contentView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
        }
        handleView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.centerX.equalToSuperview()
            $0.width.equalTo(40)
            $0.height.equalTo(5)
        }
        calendarContainerView.snp.makeConstraints {
            $0.top.equalTo(handleView.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        monthYearLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(20)
            $0.leading.equalToSuperview().offset(20)
        }
        nextButton.snp.makeConstraints {
            $0.centerY.equalTo(monthYearLabel)
            $0.trailing.equalToSuperview().offset(-20)
            $0.size.equalTo(24)
        }
        prevButton.snp.makeConstraints {
            $0.centerY.equalTo(monthYearLabel)
            $0.trailing.equalTo(nextButton.snp.leading).offset(-20)
            $0.size.equalTo(24)
        }
        weekdayStackView.snp.makeConstraints {
            $0.top.equalTo(monthYearLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(20)
        }
        collectionView.snp.makeConstraints {
            $0.top.equalTo(weekdayStackView.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(232)  // 6행 고정: 6*32 + 5*8
            $0.bottom.equalToSuperview().offset(-12)
        }
        confirmButton.snp.makeConstraints {
            $0.top.equalTo(calendarContainerView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(48)
            $0.bottom.equalTo(safeAreaLayoutGuide).offset(-16)
        }
    }
}
