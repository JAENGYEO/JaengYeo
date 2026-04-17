//
//  BaseNavigationController.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/17/26.
//

import UIKit

final class BaseNavigationController: UINavigationController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return topViewController?.preferredStatusBarStyle ?? .darkContent
    }
}
