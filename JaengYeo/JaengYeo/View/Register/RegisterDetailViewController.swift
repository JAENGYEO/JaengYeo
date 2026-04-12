//
//  RegisterDetailViewController.swift
//  JaengYeo
//
//  Created by 손영빈 on 4/12/26.
//

import UIKit

class RegisterDetailViewController: UIViewController {
    
    private var item: RegisterFormData
    
    init(item: RegisterFormData) {
        self.item = item
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
