//
//  AppleMusicJAMWidgetBundle.swift
//  AppleMusicJAMWidget
//
//  Created by Apple Music JAM.
//

import WidgetKit
import SwiftUI

/// Widget bundle that registers all widgets and Live Activities for the app.
@main
struct AppleMusicJAMWidgetBundle: WidgetBundle {
    var body: some Widget {
        MusicLiveActivity()
    }
}
