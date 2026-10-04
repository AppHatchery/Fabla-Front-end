//
//  DiaryTimerActivityBundle.swift
//  DiaryTimerActivity
//

import WidgetKit
import SwiftUI

@main
struct DiaryTimerActivityBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.1, *) {
            DiaryTimerActivityLiveActivity()
        }
    }
}
