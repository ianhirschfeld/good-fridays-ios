//
//  ParallaxImageView.swift
//  GOOD Fridays
//
//  Created by Ian Hirschfeld on 2/25/16.
//  Copyright © 2016 The Soap Collective. All rights reserved.
//

import UIKit

class ParallaxImageView: UIImageView {

  // ==================================================
  // PROPERTIES
  // ==================================================

  var motionGroup: UIMotionEffectGroup?

  // ==================================================
  // METHODS
  // ==================================================

  func addParallax(offset: CGFloat) {
    if motionGroup != nil { return }

    let verticalMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.y", type: UIInterpolatingMotionEffectType.TiltAlongVerticalAxis)
    verticalMotionEffect.minimumRelativeValue = offset
    verticalMotionEffect.maximumRelativeValue = -offset

    let horizontalMotionEffect = UIInterpolatingMotionEffect(keyPath: "center.x", type: UIInterpolatingMotionEffectType.TiltAlongHorizontalAxis)
    horizontalMotionEffect.minimumRelativeValue = offset
    horizontalMotionEffect.maximumRelativeValue = -offset

    motionGroup = UIMotionEffectGroup()
    motionGroup!.motionEffects = [horizontalMotionEffect, verticalMotionEffect]

    addMotionEffect(motionGroup!)
  }

  func removeParallax() {
    if motionGroup != nil {
      removeMotionEffect(motionGroup!)
      motionGroup = nil
    }
  }

}
