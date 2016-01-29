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

  static var defaults = NSUserDefaults.standardUserDefaults()

  static var player = AVPlayer()
  static var playerItems = [AVPlayerItem]()
  static var tracks = [JSON]()

  static var isPlaying = false
  static var shouldAutoPlay = false

}
