//
//  MainController.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/6/26.
//

import UIKit

class MainController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupTabBar()
    }
}

extension MainController {
    private func setupTabBar() {
        let homeVC = createNC(rootVC: ViewController(), title: "홈", image: "house")
        let registerVC = createNC(rootVC: ViewController(), title: "등록", image: "camera")
        let stockVC = createNC(rootVC: ViewController(), title: "재고", image: "bag")
        //TODO: TabBar 색상 및 스타일 설정 필요
//        tabBar.tintColor =
//        tabBar.unselectedItemTintColor =
        viewControllers = [homeVC, registerVC, stockVC]
    }
    
    private func createNC(rootVC: UIViewController, title: String, image: String) -> UINavigationController {
        let nc = UINavigationController(rootViewController: rootVC)
        nc.tabBarItem.title = title
        nc.tabBarItem.image = UIImage(systemName: image)
        return nc
    }
}
