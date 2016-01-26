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

  @IBOutlet weak var actionView: UIView!
  @IBOutlet weak var hitboxView: UIView!
  @IBOutlet weak var nextButton: UIButton!
  @IBOutlet weak var playButton: UIButton!
  @IBOutlet weak var previousButton: UIButton!
  @IBOutlet weak var trackArtImageView: UIImageView!
  @IBOutlet weak var trackBackgroundArtImageView: UIImageView!
  @IBOutlet weak var trackDurationLabel: UILabel!
  @IBOutlet weak var trackProgressLabel: UILabel!
  @IBOutlet weak var trackTimelineView: UIView!
  @IBOutlet weak var trackTimelineProgressView: UIView!
  @IBOutlet weak var trackTimelineScrubberView: UIView!
  @IBOutlet weak var trackTitleLabel: UILabel!

  @IBOutlet weak var trackArtImageViewLeadingConstraint: NSLayoutConstraint!
  @IBOutlet weak var trackArtImageViewTrailingConstraint: NSLayoutConstraint!
  @IBOutlet weak var trackTimelineProgressTrailingConstraint: NSLayoutConstraint!

  weak var delegate: TrackPageViewController!
  var isPlaying = false
  var wasPlaying = false
  var shouldAutoPlay = false
  var player: AVPlayer!
  var trackData: JSON!
  var trackProgress: CMTime!
  var trackTimeObserver: AnyObject?

  var index: Int {
    return Global.tracks.indexOf({ $0["id"].numberValue == self.trackData["id"].numberValue })!
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
    let seconds = trackData["duration"].doubleValue / 1000
    trackDurationLabel.text = timestamp(seconds)
    trackProgressLabel.text = "0:00"
    trackTitleLabel.text = trackData["title"].stringValue

    trackTimelineView.layer.cornerRadius = trackTimelineView.bounds.height / 2

    nextButton.layer.borderColor = UIColor(white: 1, alpha: 0.5).CGColor
    nextButton.layer.borderWidth = 1
    nextButton.layer.cornerRadius = nextButton.bounds.width / 2
    nextButton.imageView?.contentMode = .ScaleAspectFit
    nextButton.setImage(nextButton.imageView?.image?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
    nextButton.tintColor = UIColor.whiteColor()
    if index >= Global.tracks.count - 1 {
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

    let hitboxTapGesture = UITapGestureRecognizer(target: self, action: "hitboxTapped:")
    hitboxView.addGestureRecognizer(hitboxTapGesture)

    let timelinePanGesture = UIPanGestureRecognizer(target: self, action: "timelinePanned:")
    timelinePanGesture.maximumNumberOfTouches = 1
    trackTimelineScrubberView.addGestureRecognizer(timelinePanGesture)

    NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerFinished:", name: AVPlayerItemDidPlayToEndTimeNotification, object: playerItem)
  }

  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)

    if shouldAutoPlay {
      shouldAutoPlay = false
      playButtonTapped(playButton)
    }
  }

  override func viewDidDisappear(animated: Bool) {
    super.viewDidDisappear(animated)

    if isPlaying {
      playButtonTapped(playButton)
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    if view.frame.width >= view.frame.height {
      let targetHeight = view.frame.height / 2
      let targetPadding = (view.frame.width - targetHeight - 50) / 2
      trackArtImageViewLeadingConstraint.constant = targetPadding
      trackArtImageViewTrailingConstraint.constant = targetPadding
    } else {
      let padding: CGFloat = UIDevice.currentDevice().userInterfaceIdiom == .Pad ? 40 : 20
      trackArtImageViewLeadingConstraint.constant = padding
      trackArtImageViewTrailingConstraint.constant = padding
    }
  }

  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
    if let observer = trackTimeObserver {
      player.removeTimeObserver(observer)
      trackTimeObserver = nil
    }
  }

  func timestamp(seconds: Double) -> String {
    let minutes = Int(floor(seconds / 60))
    let seconds = Int(floor(seconds - Double(minutes * 60)))
    var timestamp = "\(minutes):"
    timestamp += seconds >= 10 ? "\(seconds)" : "0\(seconds)"
    return timestamp
  }

  func playerFinished(notification: NSNotification) {
    playButtonTapped(playButton)
    let time = CMTime(seconds: 0, preferredTimescale: player.currentTime().timescale)
    player.seekToTime(time)
    trackProgress = time
    trackProgressLabel.text = timestamp(0)
    trackTimelineProgressTrailingConstraint.constant = trackTimelineView.frame.width
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
//      playButton.setImage(UIImage(named: "play")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
      playButton.contentEdgeInsets = UIEdgeInsets(top: 30, left: 33, bottom: 30, right: 27)
    } else {
      isPlaying = true
      if trackProgress.seconds == 0 {
        player.play()
      } else {
        player.seekToTime(trackProgress, completionHandler: { (completed) -> Void in
          self.player.play()
//          self.playButton.setImage(UIImage(named: "pause")?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
          self.playButton.contentEdgeInsets = UIEdgeInsets(top: 30, left: 30, bottom: 30, right: 30)
        })
      }
      trackTimeObserver = player.addPeriodicTimeObserverForInterval(CMTimeMake(1, 10), queue: dispatch_get_main_queue(), usingBlock: { (time) -> Void in
        self.trackProgressLabel.text = self.timestamp(self.player.currentTime().seconds)
        let percent = CGFloat(self.player.currentTime().seconds / (self.trackData["duration"].doubleValue / 1000))
        let threshold = self.view.frame.width - 40
        self.trackTimelineProgressTrailingConstraint.constant = threshold - threshold * percent
        self.view.layoutIfNeeded()
      })
    }
  }

  @IBAction func nextButtonTapped(sender: UIButton) {
    delegate.goToNextPage()
  }

  @IBAction func previousButtonTapper(sender: UIButton) {
    if player.currentTime().seconds >= 10 {
      let time = CMTime(seconds: 0, preferredTimescale: player.currentTime().timescale)
      player.seekToTime(time)
      if !isPlaying {
        trackProgress = time
        trackProgressLabel.text = timestamp(0)
        trackTimelineProgressTrailingConstraint.constant = trackTimelineView.frame.width
      }
    } else {
      delegate.goToPreviousPage()
    }
  }

  func hitboxTapped(gesture: UITapGestureRecognizer) {
    playButtonTapped(playButton)

    if isPlaying {
      UIView.animateWithDuration(0.2, animations: { () -> Void in
        self.actionView.alpha = 0
      })
    } else {
      UIView.animateWithDuration(0.2, animations: { () -> Void in
        self.actionView.alpha = 1
      })
    }
  }

  func timelinePanned(gesture: UIPanGestureRecognizer) {
    let translation = gesture.translationInView(view)
    let dx = translation.x
    gesture.setTranslation(CGPointZero, inView: view)

    switch gesture.state {
    case .Began:
      if isPlaying {
        wasPlaying = true
        player.pause()
      }
      break

    case .Changed:
      let newConstant = trackTimelineProgressTrailingConstraint.constant - dx
      if newConstant <= 0 {
        trackTimelineProgressTrailingConstraint.constant = 0
      } else if newConstant >= trackTimelineView.frame.width {
        trackTimelineProgressTrailingConstraint.constant = trackTimelineView.frame.width
      } else {
        trackTimelineProgressTrailingConstraint.constant = newConstant
      }
      let percent = Double((trackTimelineView.frame.width - trackTimelineProgressTrailingConstraint.constant) / trackTimelineView.frame.width)
      let seconds = (self.trackData["duration"].doubleValue / 1000) * percent
      trackProgressLabel.text = timestamp(seconds)
      break

    case .Ended:
      let percent = Double((trackTimelineView.frame.width - trackTimelineProgressTrailingConstraint.constant) / trackTimelineView.frame.width)
      let seconds = (self.trackData["duration"].doubleValue / 1000) * percent
      trackProgressLabel.text = timestamp(seconds)
      let time = CMTime(seconds: seconds, preferredTimescale: player.currentTime().timescale)
      trackProgress = time
      player.seekToTime(time)
      if wasPlaying {
        isPlaying = true
        player.play()
      }
      wasPlaying = false
      break

    default:
      break
    }
  }

}
