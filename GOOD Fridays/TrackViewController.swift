//
//  TrackViewController.swift
//  GOOD Fridays
//
//  Created by Ian Hirschfeld on 1/20/16.
//  Copyright © 2016 The Soap Collective. All rights reserved.
//

import AlamofireImage
import AVFoundation
import UIKit
import SwiftyJSON

class TrackViewController: UIViewController {

  @IBOutlet weak var nextButton: UIButton!
  @IBOutlet weak var playButton: UIButton!
  @IBOutlet weak var previousButton: UIButton!
  @IBOutlet weak var trackArtImageView: UIImageView!
  @IBOutlet weak var trackBackgroundArtImageView: UIImageView!
  @IBOutlet weak var trackDurationLabel: UILabel!
  @IBOutlet weak var trackProgressLabel: UILabel!
  @IBOutlet weak var trackTimelineView: UIView!
  @IBOutlet weak var trackTimelineProgressView: UIView!
  @IBOutlet weak var trackTitleLabel: UILabel!

  @IBOutlet weak var trackTimelineProgressTrailingConstraint: NSLayoutConstraint!

  weak var delegate: MainPageViewController!
  var isPlaying = false
  var player: AVPlayer!
  var trackData: JSON!
  var trackProgress: CMTime!
  var trackTimeObserver: AnyObject?

  var index: Int {
    return delegate.data.arrayValue.indexOf({ $0["id"].numberValue == self.trackData["id"].numberValue })!
  }

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
    let seconds: Int = trackData["duration"].intValue / 1000
    let minutes: Int = seconds / 60
    trackDurationLabel.text = "\(minutes):\(seconds - minutes * 60)"
    trackProgressLabel.text = "0:00"
    trackTitleLabel.text = trackData["title"].stringValue

    trackTimelineView.layer.cornerRadius = trackTimelineView.bounds.height / 2

    nextButton.layer.borderColor = UIColor(white: 1, alpha: 0.5).CGColor
    nextButton.layer.borderWidth = 1
    nextButton.layer.cornerRadius = nextButton.bounds.width / 2
    nextButton.imageView?.contentMode = .ScaleAspectFit
    nextButton.setImage(nextButton.imageView?.image?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
    nextButton.tintColor = UIColor.whiteColor()
    if index >= delegate.data.arrayValue.count - 1 {
      nextButton.enabled = false
      nextButton.alpha = 0.3
    }

    playButton.layer.borderColor = UIColor(white: 1, alpha: 0.5).CGColor
    playButton.layer.borderWidth = 2
    playButton.layer.cornerRadius = playButton.bounds.width / 2
    playButton.imageView?.contentMode = .ScaleAspectFit
    playButton.setImage(playButton.imageView?.image?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
    playButton.tintColor = UIColor.whiteColor()

    previousButton.layer.borderColor = UIColor(white: 1, alpha: 0.5).CGColor
    previousButton.layer.borderWidth = 1
    previousButton.layer.cornerRadius = previousButton.bounds.width / 2
    previousButton.imageView?.contentMode = .ScaleAspectFit
    previousButton.setImage(previousButton.imageView?.image?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
    previousButton.tintColor = UIColor.whiteColor()
    previousButton.imageView?.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
    if index <= 0 {
      previousButton.enabled = false
      previousButton.alpha = 0.3
    }

    trackTimelineProgressTrailingConstraint.constant = view.frame.width - 40
    view.layoutIfNeeded()

    let trackUrl = NSURL(string: trackData["stream_url"].stringValue)!
    let playerItem = AVPlayerItem(URL: trackUrl)
    player = AVPlayer(playerItem: playerItem)
    trackProgress = player.currentTime()
  }

  override func viewDidDisappear(animated: Bool) {
    super.viewDidDisappear(animated)

    if isPlaying {
      playButtonTapped(playButton)
    }
  }

  // MARK: Player Controls
  @IBAction func playButtonTapped(sender: UIButton) {
    if isPlaying {
      isPlaying = false
      player.pause()
      if let observer = trackTimeObserver {
        player.removeTimeObserver(observer)
        trackTimeObserver = nil
      }
      trackProgress = player.currentTime()
      playButton.setImage(UIImage(named: "play")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
      playButton.contentEdgeInsets = UIEdgeInsets(top: 30, left: 33, bottom: 30, right: 27)
    } else {
      isPlaying = true
      player.seekToTime(trackProgress, completionHandler: { (completed) -> Void in
        self.player.play()
        self.playButton.setImage(UIImage(named: "pause")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        self.playButton.contentEdgeInsets = UIEdgeInsets(top: 30, left: 30, bottom: 30, right: 30)
      })
      trackTimeObserver = player.addPeriodicTimeObserverForInterval(CMTimeMake(1, 10), queue: dispatch_get_main_queue(), usingBlock: { (time) -> Void in
        let minutes: Int = Int(self.player.currentTime().seconds) / 60
        self.trackProgressLabel.text = "\(minutes):\(Int(self.player.currentTime().seconds) - minutes * 60)"
        let percent = CGFloat(self.player.currentTime().seconds / (self.trackData["duration"].doubleValue / 1000))
        let threshold = self.view.frame.width - 40
        self.trackTimelineProgressTrailingConstraint.constant = threshold - threshold * percent
        self.view.layoutIfNeeded()
      })
    }
  }

  @IBAction func nextButtonTapped(sender: UIButton) {
  }

  @IBAction func previousButtonTapper(sender: UIButton) {
  }

}
