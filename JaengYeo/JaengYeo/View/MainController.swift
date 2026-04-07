//
//  MainController.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/6/26.
//

import UIKit

class MainController: UITabBarController {
    
    init(
        homeNavigationController: UINavigationController,
        registerNavigationController: UINavigationController,
        stockNavigationController: UINavigationController
    ) {
        super.init(nibName: nil, bundle: nil)
        viewControllers = [
            homeNavigationController,
            registerNavigationController,
            stockNavigationController
        ]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupTabBar()
    }
}

extension MainController {
    private func setupTabBar() {
        //TODO: TabBar 색상 및 스타일 설정 필요
//        tabBar.tintColor =
//        tabBar.unselectedItemTintColor =
    }
}
