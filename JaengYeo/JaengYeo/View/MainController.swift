//
//  MainController.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/6/26.
//

import UIKit

class MainController: UITabBarController {
    
    //MARK: - Properties
    var onCartTabSelected: (() -> Void)?
    
    init(
        homeNavigationController: UINavigationController,
        registerNavigationController: UINavigationController,
        stockNavigationController: UINavigationController,
        cartNavigationController: UINavigationController
    ) {
        super.init(nibName: nil, bundle: nil)
        viewControllers = [
            homeNavigationController,
            registerNavigationController,
            stockNavigationController,
            cartNavigationController
        ]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        delegate = self
        setupTabBar()
    }
}

extension MainController {
    private func setupTabBar() {
        //TODO: TabBar 색상 및 스타일 설정 필요
        tabBar.tintColor = .gray800
    }
}

extension MainController: UITabBarControllerDelegate {
    func tabBarController(
        _ tabBarController: UITabBarController,
        shouldSelect viewController: UIViewController
    ) -> Bool {
        guard let index = viewControllers?.firstIndex(of: viewController) else {
            return true
        }

        if index == 3 {
            onCartTabSelected?()
            return false
        }

        return true
    }
}
