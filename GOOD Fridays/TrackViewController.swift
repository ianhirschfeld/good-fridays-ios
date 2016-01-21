//
//  TrackViewController.swift
//  GOOD Fridays
//
//  Created by Ian Hirschfeld on 1/20/16.
//  Copyright © 2016 The Soap Collective. All rights reserved.
//

import AlamofireImage
import UIKit
import SwiftyJSON

class TrackViewController: UIViewController {

  @IBOutlet weak var trackArtImageView: UIImageView!
  @IBOutlet weak var trackBackgroundArtImageView: UIImageView!
  @IBOutlet weak var trackTitleLabel: UILabel!

  var trackData: JSON!

  override func viewDidLoad() {
    super.viewDidLoad()

    let artworkUrl = NSURL(string: trackData["artwork_url"].stringValue)!
    let backgroundArtworkFilter = BlurFilter(blurRadius: 20)
    trackArtImageView.af_setImageWithURL(artworkUrl, placeholderImage: nil, filter: nil, imageTransition: .CrossDissolve(0.3)) { (response) -> Void in
      self.trackArtImageView.layer.shadowColor = UIColor(red: 18.0/255.0, green: 18.0/255.0, blue: 18.0/255.0, alpha: 1).CGColor
      self.trackArtImageView.layer.shadowOpacity = 0.8
      self.trackArtImageView.layer.shadowRadius = 10
    }
    trackBackgroundArtImageView.af_setImageWithURL(artworkUrl, placeholderImage: nil, filter: backgroundArtworkFilter, imageTransition: .CrossDissolve(0.3))
    trackTitleLabel.text = trackData["title"].stringValue
  }

}
