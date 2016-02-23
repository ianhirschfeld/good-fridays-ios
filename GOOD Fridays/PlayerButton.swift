//
//  PlayerButton.swift
//  GOOD Fridays
//
//  Created by Ian Hirschfeld on 2/22/16.
//  Copyright © 2016 The Soap Collective. All rights reserved.
//

import UIKit

class PlayerButton: UIButton {

  override func awakeFromNib() {
    super.awakeFromNib()

    layer.borderColor = UIColor(white: 1, alpha: 0.5).CGColor
    layer.borderWidth = 1
    layer.cornerRadius = bounds.width / 2
    imageView?.contentMode = .ScaleAspectFit
    setImage(imageView?.image?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
    tintColor = UIColor.whiteColor()
  }

}
