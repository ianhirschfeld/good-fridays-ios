//
//  TrackViewController.swift
//  GOOD Fridays
//
//  Created by Ian Hirschfeld on 1/20/16.
//  Copyright © 2016 The Soap Collective. All rights reserved.
//

import AlamofireImage
import AVFoundation
import MediaPlayer
import UIKit
import SwiftyJSON
import TTTAttributedLabel

class TrackViewController: UIViewController {

  @IBOutlet weak var actionView: UIView!
  @IBOutlet weak var hitboxView: UIView!
  @IBOutlet weak var nextButton: UIButton!
  @IBOutlet weak var playButton: UIButton!
  @IBOutlet weak var previousButton: UIButton!
  @IBOutlet weak var trackArtImageView: ParallaxImageView!
  @IBOutlet weak var trackArtistLabel: UILabel!
  @IBOutlet weak var trackBackgroundArtImageView: UIImageView!
  @IBOutlet weak var trackDurationLabel: UILabel!
  @IBOutlet weak var trackNotStreamableLabel: TTTAttributedLabel!
  @IBOutlet weak var trackProgressLabel: UILabel!
  @IBOutlet weak var trackSourceLabel: UILabel!
  @IBOutlet weak var trackTimelineView: UIView!
  @IBOutlet weak var trackTimelineProgressView: UIView!
  @IBOutlet weak var trackTimelineScrubberView: UIView!
  @IBOutlet weak var trackTitleLabel: UILabel!
  @IBOutlet weak var trackUploaderLabel: UILabel!

  @IBOutlet weak var trackArtImageViewLeadingConstraint: NSLayoutConstraint!
  @IBOutlet weak var trackArtImageViewTrailingConstraint: NSLayoutConstraint!
  @IBOutlet weak var trackTimelineProgressTrailingConstraint: NSLayoutConstraint!

  weak var delegate: TrackPageViewController!
  var playerItem: AVPlayerItem!
  var shouldContinuePlaying = false
  var track: JSON!

  var index: Int {
    return Global.trackManager.getTrackIndex(track)!
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let artworkUrl = NSURL(string: track["artwork_url"].stringValue)!
    trackArtImageView.af_setImageWithURL(artworkUrl, placeholderImage: nil, filter: nil, imageTransition: .CrossDissolve(0.3)) { (response) -> Void in
      self.trackArtImageView.layer.shadowColor = UIColor(red: 18.0/255.0, green: 18.0/255.0, blue: 18.0/255.0, alpha: 1).CGColor
      self.trackArtImageView.layer.shadowOpacity = 0.8
      self.trackArtImageView.layer.shadowRadius = 10
    }
    let backgroundArtworkFilter = BlurFilter(blurRadius: 20)
    trackBackgroundArtImageView.af_setImageWithURL(artworkUrl, placeholderImage: nil, filter: backgroundArtworkFilter, imageTransition: .CrossDissolve(0.3))

    trackSourceLabel.text = "Source: \(track["source"].stringValue)"
    trackUploaderLabel.text = "Uploader: \(track["uploader"].stringValue)"
    trackTitleLabel.text = track["title"].stringValue
    trackArtistLabel.text = track["artist"].stringValue
    trackProgressLabel.text = "0:00"
    let seconds = track["duration"].doubleValue / 1000
    trackDurationLabel.text = timestamp(seconds)

    if index >= Global.trackManager.tracks.count - 1 {
      nextButton.enabled = false
      nextButton.alpha = 0.3
    }

    if !track["streamable"].boolValue {
      playButton.enabled = false
      playButton.alpha = 0.3
    }

    previousButton.imageView?.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
    if index <= 0 {
      previousButton.enabled = false
      previousButton.alpha = 0.3
    }

    trackTimelineView.layer.cornerRadius = trackTimelineView.bounds.height / 2

    trackTimelineProgressTrailingConstraint.constant = view.frame.width - 40
    view.layoutIfNeeded()

    if track["streamable"].boolValue {
      let hitboxTapGesture = UITapGestureRecognizer(target: self, action: "hitboxTapped:")
      hitboxView.addGestureRecognizer(hitboxTapGesture)

      let timelinePanGesture = UIPanGestureRecognizer(target: self, action: "timelinePanned:")
      timelinePanGesture.maximumNumberOfTouches = 1
      trackTimelineScrubberView.addGestureRecognizer(timelinePanGesture)
    } else {
      trackNotStreamableLabel.hidden = false
      trackNotStreamableLabel.linkAttributes = [
        kCTForegroundColorAttributeName: UIColor.whiteColor(),
        kCTUnderlineStyleAttributeName: NSNumber(int: CTUnderlineStyle.Single.rawValue)
      ]
      trackNotStreamableLabel.activeLinkAttributes = [
        kCTForegroundColorAttributeName: UIColor(white: 1, alpha: 0.3),
        kCTUnderlineStyleAttributeName: NSNumber(int: CTUnderlineStyle.Single.rawValue)
      ]
      trackNotStreamableLabel.delegate = self
      if let permalinkUrl = NSURL(string: track["permalink_url"].stringValue) {
        if let text = trackNotStreamableLabel.text {
          if let startRange = text.rangeOfString("Tap here") {
            let location = text.startIndex.distanceTo(startRange.startIndex)
            trackNotStreamableLabel.addLinkToURL(permalinkUrl, withRange: NSRange(location: location, length: 8))
          }
        }
      }
    }
  }

  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)

    if Global.trackManager.currentTrack() != track && track["streamable"].boolValue {
      shouldContinuePlaying = Global.trackManager.isPlaying
      Global.trackManager.pause()
      Global.trackManager.currentIndex = index
      if shouldContinuePlaying {
        shouldContinuePlaying = false
        Global.trackManager.play()
      }
    }

    toggleActionView()

    trackArtImageView.addParallax(-30)

    NSNotificationCenter.defaultCenter().addObserver(self, selector: "next:", name: Global.NextNotification, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "togglePlayPause:", name: Global.PauseNotification, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "togglePlayPause:", name: Global.PlayNotification, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerItemTick:", name: Global.PlayerItemTickNotification, object: playerItem)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "previous:", name: Global.PreviousNotification, object: nil)
  }

  override func viewDidDisappear(animated: Bool) {
    super.viewDidDisappear(animated)
    trackArtImageView.removeParallax()
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    if view.frame.width >= view.frame.height {
      let targetHeight = view.frame.height / 2
      let targetPadding = (view.frame.width - targetHeight - 40) / 2
      trackArtImageViewLeadingConstraint.constant = targetPadding
      trackArtImageViewTrailingConstraint.constant = targetPadding
    } else {
      let padding: CGFloat = UIDevice.currentDevice().userInterfaceIdiom == .Pad ? 40 : 20
      trackArtImageViewLeadingConstraint.constant = padding
      trackArtImageViewTrailingConstraint.constant = padding
    }
    view.layoutIfNeeded()
  }

  override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
    coordinator.animateAlongsideTransition(nil) { (UIViewControllerTransitionCoordinatorContext) -> Void in
      if !Global.trackManager.isPlaying {
        self.setTimelineAttributes()
      }
    }
  }

  @IBAction func playButtonTapped(sender: UIButton) {
    togglePlayTrack()
  }

  @IBAction func nextButtonTapped(sender: UIButton) {
    delegate.goToNextPage()
  }

  @IBAction func previousButtonTapper(sender: UIButton) {
    if playerItem.currentTime().seconds >= 10 {
      Global.trackManager.seekTo(0)
      if !Global.trackManager.isPlaying {
        trackProgressLabel.text = timestamp(0)
        trackTimelineProgressTrailingConstraint.constant = trackTimelineView.frame.width
      }
    } else {
      delegate.goToPreviousPage()
    }
  }

  func next(notification: NSNotification) {
    if Global.trackManager.currentIndex > index {
      delegate.goToNextPage()
    }
  }

  func playerItemTick(notification: NSNotification) {
    setTimelineAttributes()
  }

  func previous(notification: NSNotification) {
    if Global.trackManager.currentIndex < index {
      delegate.goToPreviousPage()
    }
  }

  func togglePlayPause(notification: NSNotification) {
    if Global.trackManager.currentTrack() == track {
      toggleActionView()
    }
  }

  func togglePlayTrack() {
    Global.trackManager.togglePlayPause()
  }

  func toggleActionView() {
    let alpha: CGFloat = Global.trackManager.isPlaying && track["streamable"].boolValue ? 0 : 1
    UIView.animateWithDuration(0.2, delay: 0, options: .BeginFromCurrentState, animations: { () -> Void in
      self.actionView.alpha = alpha
    }, completion: nil)
  }

  func hitboxTapped(gesture: UITapGestureRecognizer) {
    togglePlayTrack()
    toggleActionView()
  }

  func timelinePanned(gesture: UIPanGestureRecognizer) {
    let translation = gesture.translationInView(view)
    let dx = translation.x
    gesture.setTranslation(CGPointZero, inView: view)

    switch gesture.state {
    case .Began:
      if Global.trackManager.isPlaying {
        Global.trackManager.pause()
        shouldContinuePlaying = true
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
      let seconds = scrubSeconds()
      trackProgressLabel.text = timestamp(seconds)
      break

    case .Ended:
      let seconds = scrubSeconds()
      trackProgressLabel.text = timestamp(seconds)
      Global.trackManager.seekTo(seconds)
      if shouldContinuePlaying {
        // Delay needed to let the AVPlayerItem properly seek before resuming play.
        NSTimer.scheduledTimerWithTimeInterval(0.2, target: Global.trackManager, selector: "play", userInfo: nil, repeats: false)
      }
      shouldContinuePlaying = false
      break

    default:
      break
    }
  }

  func setTimelineAttributes() {
    let seconds = playerItem.currentTime().seconds < 0 ? 0 : playerItem.currentTime().seconds
    let percent = CGFloat(seconds / (track["duration"].doubleValue / 1000))
    let threshold = view.frame.width - 40
    trackProgressLabel.text = timestamp(seconds)
    trackTimelineProgressTrailingConstraint.constant = threshold - threshold * percent
    view.layoutIfNeeded()
  }

  func scrubSeconds() -> Double {
    let percent = Double((trackTimelineView.frame.width - trackTimelineProgressTrailingConstraint.constant) / trackTimelineView.frame.width)
    return (self.track["duration"].doubleValue / 1000) * percent
  }

  func timestamp(seconds: Double) -> String {
    let minutes = Int(floor(seconds / 60))
    let seconds = Int(floor(seconds - Double(minutes * 60)))

    if minutes < 0 || seconds < 0 {
      return "0:00"
    }

    var timestamp = "\(minutes):"
    timestamp += seconds >= 10 ? "\(seconds)" : "0\(seconds)"
    return timestamp
  }

}

extension TrackViewController: TTTAttributedLabelDelegate {

  func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
    if UIApplication.sharedApplication().canOpenURL(url) {
      UIApplication.sharedApplication().openURL(url)
    }
  }

}