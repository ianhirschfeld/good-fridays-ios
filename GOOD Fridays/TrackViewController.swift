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
  @IBOutlet weak var trackArtImageView: UIImageView!
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
  var playerTimeObserver: AnyObject?
  var shouldContinuePlaying = false
  var track: JSON!

  var index: Int {
    return Global.tracks.indexOf({ $0["id"].numberValue == self.track["id"].numberValue })!
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    trackSourceLabel.text = "Source: \(track["source"].stringValue)"
    trackUploaderLabel.text = "Uploader: \(track["uploader"].stringValue)"

    let artworkUrl = NSURL(string: track["artwork_url"].stringValue)!
    trackArtImageView.af_setImageWithURL(artworkUrl, placeholderImage: nil, filter: nil, imageTransition: .CrossDissolve(0.3)) { (response) -> Void in
      self.trackArtImageView.layer.shadowColor = UIColor(red: 18.0/255.0, green: 18.0/255.0, blue: 18.0/255.0, alpha: 1).CGColor
      self.trackArtImageView.layer.shadowOpacity = 0.8
      self.trackArtImageView.layer.shadowRadius = 10
    }
    let backgroundArtworkFilter = BlurFilter(blurRadius: 20)
    trackBackgroundArtImageView.af_setImageWithURL(artworkUrl, placeholderImage: nil, filter: backgroundArtworkFilter, imageTransition: .CrossDissolve(0.3))
    let seconds = track["duration"].doubleValue / 1000
    trackDurationLabel.text = timestamp(seconds)
    trackProgressLabel.text = "0:00"
    trackTitleLabel.text = track["title"].stringValue

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
    if !track["streamable"].boolValue {
      playButton.enabled = false
      playButton.alpha = 0.3
    }

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

    if track["streamable"].boolValue {
      playerItem = Global.playerItems[index]
      Global.player.replaceCurrentItemWithPlayerItem(playerItem)

      if Global.shouldAutoPlay || Global.isPlaying {
        Global.shouldAutoPlay = false
        playTrack()
      } else {
        setTimelineAttributes()
      }
    }

    toggleActionView()

    NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerItemFinished:", name: AVPlayerItemDidPlayToEndTimeNotification, object: playerItem)

    NSNotificationCenter.defaultCenter().addObserver(self, selector: "pauseTrackCommand:", name: Global.PauseTrackNotification, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "playTrackCommand:", name: Global.PlayTrackCommandNotification, object: nil)
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

  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)

    if let observer = playerTimeObserver {
      Global.player.removeTimeObserver(observer)
      playerTimeObserver = nil
    }
  }

  override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
    coordinator.animateAlongsideTransition(nil) { (UIViewControllerTransitionCoordinatorContext) -> Void in
      if !Global.isPlaying {
        self.setTimelineAttributes()
      }
    }
  }

  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
    if let observer = playerTimeObserver {
      Global.player.removeTimeObserver(observer)
      playerTimeObserver = nil
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
      let time = CMTime(seconds: 0, preferredTimescale: playerItem.currentTime().timescale)
      Global.player.seekToTime(time)
      if !Global.isPlaying {
        trackProgressLabel.text = timestamp(0)
        trackTimelineProgressTrailingConstraint.constant = trackTimelineView.frame.width
      }
    } else {
      delegate.goToPreviousPage()
    }
  }

  func playerItemFinished(notification: NSNotification) {
    if index < Global.playerItems.count - 1 {
      togglePlayTrack()
      let time = CMTime(seconds: 0, preferredTimescale: playerItem.currentTime().timescale)
      playerItem.seekToTime(time)
      Global.shouldAutoPlay = true
      delegate.goToNextPage()
    } else {
      togglePlayTrack()
      for item in Global.playerItems {
        let time = CMTime(seconds: 0, preferredTimescale: item.currentTime().timescale)
        item.seekToTime(time)
      }
      dismissViewControllerAnimated(true, completion: nil)
    }
  }

  func pauseTrackCommand(notification: NSNotification) {
    if Global.isPlaying {
      pauseTrack()
    }
  }

  func playTrackCommand(notification: NSNotification) {
    if !Global.isPlaying {
      playTrack()
    }
  }

  func playTrack() {
    Global.isPlaying = true
    if playerItem.currentTime().seconds == 0 {
      Global.player.play()
    } else {
      Global.player.seekToTime(playerItem.currentTime(), completionHandler: { (completed) -> Void in
        Global.player.play()
      })
    }
    playerTimeObserver = Global.player.addPeriodicTimeObserverForInterval(CMTimeMake(1, 10), queue: dispatch_get_main_queue(), usingBlock: { [unowned self] (time) -> Void in
      self.setTimelineAttributes()
    })
    setNowPlayingInfo()
  }

  func pauseTrack() {
    Global.isPlaying = false
    Global.player.pause()
    if let observer = playerTimeObserver {
      Global.player.removeTimeObserver(observer)
      playerTimeObserver = nil
    }
    setNowPlayingInfo()
  }

  func setNowPlayingInfo() {
    var seconds = playerItem == nil ? 0 : playerItem.currentTime().seconds
    if seconds < 0 {
      seconds = 0
    }
    MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = [
      MPMediaItemPropertyTitle: track["title"].stringValue,
      MPMediaItemPropertyArtist: track["artist"].stringValue,
      MPMediaItemPropertyArtwork: MPMediaItemArtwork(image: trackArtImageView.image!),
      MPMediaItemPropertyPlaybackDuration: track["duration"].doubleValue / 1000,
      MPNowPlayingInfoPropertyPlaybackRate: Global.isPlaying ? 1 : 0,
      MPNowPlayingInfoPropertyElapsedPlaybackTime: seconds,
    ]
  }

  func togglePlayTrack() {
    Global.isPlaying ? pauseTrack() : playTrack()
  }

  func toggleActionView() {
    let alpha: CGFloat = Global.isPlaying && track["streamable"].boolValue ? 0 : 1
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
      if Global.isPlaying {
        Global.isPlaying = false
        shouldContinuePlaying = true
        Global.player.pause()
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
      let time = CMTime(seconds: seconds, preferredTimescale: playerItem.currentTime().timescale)
      Global.player.seekToTime(time)
      if shouldContinuePlaying {
        Global.isPlaying = true
        Global.player.play()
      }
      shouldContinuePlaying = false
      setNowPlayingInfo()
      break

    default:
      break
    }
  }

  func setTimelineAttributes() {
    var seconds = playerItem == nil ? 0 : playerItem.currentTime().seconds
    if seconds < 0 {
      seconds = 0
    }
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