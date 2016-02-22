//
//  TrackCollectionViewController.swift
//  GOOD Fridays
//
//  Created by Ian Hirschfeld on 1/25/16.
//  Copyright © 2016 The Soap Collective. All rights reserved.
//

import Alamofire
import AlamofireImage
import AVFoundation
import Mixpanel
import MediaPlayer
import UIKit
import SwiftyJSON

class TrackCollectionViewController: UIViewController {

  @IBOutlet weak var backgroundImageView: UIImageView!
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var downloadingView: UIView!
  @IBOutlet weak var downloadingIndicatorView: UIActivityIndicatorView!
  @IBOutlet weak var notificationContainerView: UIView!
  @IBOutlet weak var notificationImageView: UIImageView!
  @IBOutlet weak var notificationNoButton: UIButton!
  @IBOutlet weak var notificationYesButton: UIButton!

  let CellMargin: CGFloat = 15
  let CollectionMargin: CGFloat = 20

  var baseUrl: String!
  var shouldDownloadData = false

  override func viewDidLoad() {
    super.viewDidLoad()

    let env = NSProcessInfo.processInfo().environment
    baseUrl = env["API_BASE_URL"] != nil ? env["API_BASE_URL"]! : "https://good-fridays.herokuapp.com"
    print("Using: \(baseUrl)")

    notificationImageView.layer.cornerRadius = 8
    notificationNoButton.layer.borderColor = UIColor(white: 1, alpha: 0.5).CGColor
    notificationNoButton.layer.borderWidth = 1
    notificationNoButton.layer.cornerRadius = 6
    notificationYesButton.layer.borderColor = UIColor(white: 1, alpha: 0.5).CGColor
    notificationYesButton.layer.borderWidth = 1
    notificationYesButton.layer.cornerRadius = 6

    Global.tracks = [JSON]()
    Global.playerItems = [AVPlayerItem]()
    shouldDownloadData = true

    MPRemoteCommandCenter.sharedCommandCenter().nextTrackCommand.addTarget(self, action: "handleNextTrackCommand:")
    MPRemoteCommandCenter.sharedCommandCenter().pauseCommand.addTarget(self, action: "handlePauseCommand:")
    MPRemoteCommandCenter.sharedCommandCenter().playCommand.addTarget(self, action: "handlePlayCommand:")
    MPRemoteCommandCenter.sharedCommandCenter().previousTrackCommand.addTarget(self, action: "handlePreviousTrackCommand:")
  }

  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)

    if shouldDownloadData {
      shouldDownloadData = false
      downloadData()
    } else {
      reloadData()
    }

    NSNotificationCenter.defaultCenter().addObserver(self, selector: "pauseTrackCommand:", name: Global.PauseTrackNotification, object: nil)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "playTrackCommand:", name: Global.PlayTrackCommandNotification, object: nil)
  }

  override func viewDidDisappear(animated: Bool) {
    super.viewDidDisappear(animated)
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }

  override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
    coordinator.animateAlongsideTransition(nil) { (UIViewControllerTransitionCoordinatorContext) -> Void in
      self.collectionView.reloadData()
    }
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "TrackCollectionToTrackPage" {
      let indexPath = sender as! NSIndexPath
      let destinationViewController = segue.destinationViewController as! TrackPageViewController
      destinationViewController.startingIndex = indexPath.row
    }
  }

  @IBAction func notificationsNoTapped(sender: UIButton) {
    Global.defaults.setBool(true, forKey: Global.HasAskedForNotificationsKey)
    UIView.animateWithDuration(0.5, animations: { () -> Void in
      self.notificationContainerView.alpha = 0
    }) { (completed) -> Void in
      self.showCollectionView()
    }
  }

  @IBAction func notificationsYesTapped(sender: UIButton) {
    Global.defaults.setBool(true, forKey: Global.HasAskedForNotificationsKey)
    UIApplication.sharedApplication().delegate?.enableNotifications()
    UIView.animateWithDuration(0.5, animations: { () -> Void in
      self.notificationContainerView.alpha = 0
    }) { (completed) -> Void in
      self.showCollectionView()
    }
  }

  func pauseTrackCommand(notification: NSNotification) {
    if Global.isPlaying {
      Global.isPlaying = false
      Global.player.pause()
      setNowPlayingInfo()
    }
  }

  func playTrackCommand(notification: NSNotification) {
    if !Global.isPlaying {
      if let playerItem = Global.player.currentItem {
        Global.isPlaying = true
        if playerItem.currentTime().seconds == 0 {
          Global.player.play()
        } else {
          Global.player.seekToTime(playerItem.currentTime(), completionHandler: { (completed) -> Void in
            Global.player.play()
          })
        }
        setNowPlayingInfo()
      }
    }
  }

  func setNowPlayingInfo() {
    guard let playerItem = Global.player.currentItem else { return }
    let track = Global.tracks[Global.currentIndex]
    var seconds = playerItem.currentTime().seconds
    if seconds < 0 {
      seconds = 0
    }
    MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = [
      MPMediaItemPropertyTitle: track["title"].stringValue,
      MPMediaItemPropertyArtist: track["artist"].stringValue,
      MPMediaItemPropertyPlaybackDuration: track["duration"].doubleValue / 1000,
      MPNowPlayingInfoPropertyPlaybackRate: Global.isPlaying ? 1 : 0,
      MPNowPlayingInfoPropertyElapsedPlaybackTime: seconds,
    ]
  }

  func downloadData() {
    Alamofire.request(.GET, "\(baseUrl)/tracks_v2.json").validate().responseJSON { [unowned self] response in
      switch response.result {
      case .Success:
        if let value = response.result.value {
          Global.tracks = JSON(value).arrayValue
          for track in Global.tracks {
            let trackUrl = NSURL(string: track["stream_url"].stringValue)!
            let playerItem = AVPlayerItem(URL: trackUrl)
            Global.playerItems.append(playerItem)
          }
          self.startUp()
        }
      case .Failure(let error):
        print(error)
      }
    }
  }

  func reloadData() {
    Alamofire.request(.GET, "\(baseUrl)/tracks_v2.json").validate().responseJSON { [unowned self] response in
      switch response.result {
      case .Success:
        if let value = response.result.value {
          if JSON(value).arrayValue.count != Global.tracks.count {
            Global.player.replaceCurrentItemWithPlayerItem(nil)
            Global.playerItems.removeAll()
            Global.tracks = JSON(value).arrayValue
            for track in Global.tracks {
              let trackUrl = NSURL(string: track["stream_url"].stringValue)!
              let playerItem = AVPlayerItem(URL: trackUrl)
              Global.playerItems.append(playerItem)
            }
            self.collectionView.reloadData()
          }
        }
      case .Failure(let error):
        print(error)
      }
    }
  }

  func startUp() {
    do {
      try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
      do {
        try AVAudioSession.sharedInstance().setActive(true)
      } catch let error as NSError {
        print(error.localizedDescription)
      }
    } catch let error as NSError {
      print(error.localizedDescription)
    }

    let hasAskedForNotifications = Global.defaults.boolForKey(Global.HasAskedForNotificationsKey)
    UIView.animateWithDuration(0.5, animations: { () -> Void in
      self.downloadingView.alpha = 0
    }) { (completed) -> Void in
      self.downloadingIndicatorView.stopAnimating()
      if !hasAskedForNotifications {
        self.showAskForNotifications()
      } else {
        self.showCollectionView()
      }
    }
  }

  func showAskForNotifications() {
    UIView.animateWithDuration(0.5, animations: { () -> Void in
      self.notificationContainerView.alpha = 1
    })
  }

  func showCollectionView() {
    self.collectionView.reloadData()
    UIView.animateWithDuration(0.5, animations: { () -> Void in
      self.collectionView.alpha = 1
    })
  }

  func handleNextTrackCommand(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
    print(event.command)
    return .Success
  }

  func handlePauseCommand(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
    if Global.isPlaying {
      NSNotificationCenter.defaultCenter().postNotificationName(Global.PauseTrackNotification, object: nil)
      return .Success
    } else if #available(iOS 9.1, *) {
        return .NoActionableNowPlayingItem
    }
    return .CommandFailed
  }

  func handlePlayCommand(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
    if !Global.isPlaying {
      NSNotificationCenter.defaultCenter().postNotificationName(Global.PlayTrackCommandNotification, object: nil)
      return .Success
    }
    return .CommandFailed
  }

  func handlePreviousTrackCommand(event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
    print(event.command)
    return .Success
  }

}

extension TrackCollectionViewController: UICollectionViewDelegate {}

extension TrackCollectionViewController: UICollectionViewDelegateFlowLayout {

  func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
    let divisor: CGFloat = view.frame.width > view.frame.height ? 4 : 3
    let cellSize = floor((view.frame.width - (CollectionMargin * 2) - (CellMargin * (divisor - 1))) / divisor)
    return CGSize(width: cellSize, height: cellSize)
  }

}

extension TrackCollectionViewController: UICollectionViewDataSource {

  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return Global.tracks.count
  }

  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier("TrackCollectionViewCell", forIndexPath: indexPath) as! TrackCollectionViewCell
    let track = Global.tracks[indexPath.row]

    if let artworkUrl = NSURL(string: track["artwork_url"].stringValue) {
      cell.trackArtImageView.af_setImageWithURL(artworkUrl, imageTransition: .CrossDissolve(0.3))
    }

    return cell
  }

  func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    performSegueWithIdentifier("TrackCollectionToTrackPage", sender: indexPath)
  }

}

extension TrackCollectionViewController: AVAudioSessionDelegate {

  func beginInterruption() {
    // TODO:
    print("beginInterruption")
  }

  func endInterruption() {
    // TODO:
    print("endInterruption")
  }

}
