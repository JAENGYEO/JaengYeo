//
//  DatePickerBottomSheetViewController.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/13/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

protocol DatePickerBottomSheetViewControllerDelegate: AnyObject {
    func datePickerBottomSheet(_ vc: DatePickerBottomSheetViewController, didSelect date: Date)
}

final class DatePickerBottomSheetViewController: UIViewController {

    weak var delegate: DatePickerBottomSheetViewControllerDelegate?

    private let mainView = DatePickerBottomSheetView()
    private let disposeBag = DisposeBag()

    private let sheetTitle: String
    private var currentDate: Date
    private var selectedDate: Date?

    // MARK: 달력 데이터
    private var calendarDays: [Int?] = []   // nil = 빈 셀 (해당 월 이전/이후)
    private var calendar = Calendar.current

    init(sheetTitle: String, initialDate: Date? = nil) {
        self.sheetTitle = sheetTitle
        self.currentDate = initialDate ?? Date()
        self.selectedDate = initialDate
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = mainView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        mainView.collectionView.dataSource = self
        mainView.collectionView.delegate = self
        refreshCalendar()
        bind()
        addPanGesture()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.layoutIfNeeded()   // 높이 확정 후 애니메이션 시작
        animateIn()
    }
}

// MARK: - Bind
extension DatePickerBottomSheetViewController {
    private func bind() {
        let dimmingTap = UITapGestureRecognizer()
        mainView.dimmingView.addGestureRecognizer(dimmingTap)
        dimmingTap.rx.event
            .bind(onNext: { [weak self] _ in
                guard let self else { return }
                animateOut { self.dismiss(animated: false) }
            })
            .disposed(by: disposeBag)

        mainView.prevButton.rx.tap
            .bind(onNext: { [weak self] in self?.moveMonth(by: -1) })
            .disposed(by: disposeBag)

        mainView.nextButton.rx.tap
            .bind(onNext: { [weak self] in self?.moveMonth(by: 1) })
            .disposed(by: disposeBag)

        mainView.confirmButton.rx.tap
            .bind(onNext: { [weak self] in
                guard let self else { return }
                let date = selectedDate ?? currentDate
                animateOut {
                    self.delegate?.datePickerBottomSheet(self, didSelect: date)
                    self.dismiss(animated: false)
                }
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - Calendar Logic

extension DatePickerBottomSheetViewController {
    private func refreshCalendar() {
        updateMonthYearLabel()
        calendarDays = buildCalendarDays(for: currentDate)
        mainView.collectionView.reloadData()
    }

    private func updateMonthYearLabel() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM"
        mainView.monthYearLabel.text = formatter.string(from: currentDate)
    }

    private func buildCalendarDays(for date: Date) -> [Int?] {
        var components = calendar.dateComponents([.year, .month], from: date)
        guard let firstDay = calendar.date(from: components) else { return Array(repeating: nil, count: 42) }

        let weekday = calendar.component(.weekday, from: firstDay)  // 1=Sun, 7=Sat
        let offset = weekday - 1   // 앞 빈 셀 개수

        components.day = 1
        let range = calendar.range(of: .day, in: .month, for: firstDay)!
        let daysInMonth = range.count

        var days: [Int?] = Array(repeating: nil, count: offset)
        days += (1...daysInMonth).map { Optional($0) }

        // 항상 42셀(6행)로 고정 — 높이 고정을 위해
        days += Array(repeating: nil, count: 42 - days.count)
        return days
    }

    private func moveMonth(by value: Int) {
        guard let newDate = calendar.date(byAdding: .month, value: value, to: currentDate) else { return }
        currentDate = newDate
        refreshCalendar()
    }

    private func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        calendar.isDate(date1, inSameDayAs: date2)
    }

    private func date(for day: Int) -> Date? {
        var components = calendar.dateComponents([.year, .month], from: currentDate)
        components.day = day
        return calendar.date(from: components)
    }
}

// MARK: - UICollectionViewDataSource

extension DatePickerBottomSheetViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return calendarDays.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: DatePickerCalendarCell.identifier,
            for: indexPath
        ) as? DatePickerCalendarCell else { return UICollectionViewCell() }

        let day = calendarDays[indexPath.item]
        var isSelected = false
        if let day, let cellDate = date(for: day), let selected = selectedDate {
            isSelected = isSameDay(cellDate, selected)
        }
        cell.configure(day: day, isSelected: isSelected)
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension DatePickerBottomSheetViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 32, height: 32)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        let spacing = (collectionView.bounds.width - 32 * 7) / 6
        return max(0, spacing)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let day = calendarDays[indexPath.item] else { return }
        selectedDate = date(for: day)
        mainView.collectionView.reloadData()
    }
}

// MARK: - Animation
extension DatePickerBottomSheetViewController {
    private func animateIn() {
        let contentView = mainView.contentView
        contentView.transform = CGAffineTransform(translationX: 0, y: contentView.bounds.height + 300)
        UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseOut) {
            self.mainView.dimmingView.alpha = 1
            contentView.transform = .identity
        }
    }

    private func animateOut(completion: @escaping () -> Void) {
        let contentView = mainView.contentView
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            self.mainView.dimmingView.alpha = 0
            contentView.transform = CGAffineTransform(translationX: 0, y: contentView.bounds.height + 300)
        }, completion: { _ in completion() })
    }
}

// MARK: - Pan Gesture
extension DatePickerBottomSheetViewController {
    private func addPanGesture() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.cancelsTouchesInView = false
        mainView.contentView.addGestureRecognizer(pan)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: mainView.contentView)
        let velocity = gesture.velocity(in: mainView.contentView)
        let contentView = mainView.contentView
        let contentHeight = contentView.bounds.height

        switch gesture.state {
        case .changed:
            let offsetY = max(0, translation.y)
            contentView.transform = CGAffineTransform(translationX: 0, y: offsetY)
            mainView.dimmingView.alpha = max(0, 1 - (offsetY / contentHeight))
        case .ended, .cancelled:
            if translation.y > contentHeight * 0.35 || velocity.y > 800 {
                animateOut { self.dismiss(animated: false) }
            } else {
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
                    contentView.transform = .identity
                    self.mainView.dimmingView.alpha = 1
                }
            }
        default:
            break
        }
    }
}
