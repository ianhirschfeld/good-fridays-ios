//
//  Global.swift
//  GOOD Fridays
//
//  Created by Ian Hirschfeld on 1/25/16.
//  Copyright © 2016 The Soap Collective. All rights reserved.
//

import AVFoundation
import SwiftyJSON
import UIKit

struct Global {

  static let HasAskedForNotificationsKey = "HasAskedForNotificationsKey"

  static let NextNotification = "NextNotification"
  static let PauseNotification = "PauseNotification"
  static let PlayerItemTickNotification = "PlayerItemTickNotification"
  static let PlayNotification = "PlayNotification"
  static let PreviousNotification = "PreviousNotification"

  static var defaults = NSUserDefaults.standardUserDefaults()
  static var trackManager = TrackManager()

}
