//
//  JaengYeoWidgetBundle.swift
//  JaengYeoWidget
//
//  Created by 손영빈 on 4/28/26.
//

import WidgetKit
import SwiftUI

@main
struct JaengYeoWidgetBundle: WidgetBundle {
    var body: some Widget {
        CameraShortcutWidget()
        QuantityWidget()
    }
}
