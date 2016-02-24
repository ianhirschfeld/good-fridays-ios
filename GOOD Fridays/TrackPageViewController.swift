//
//  TrackPageViewController.swift
//  GOOD Fridays
//
//  Created by Ian Hirschfeld on 1/20/16.
//  Copyright © 2016 The Soap Collective. All rights reserved.
//

import Alamofire
import UIKit
import SwiftyJSON

class TrackPageViewController: UIPageViewController {

  var startingIndex: Int?

  override func viewDidLoad() {
    super.viewDidLoad()

    delegate = self
    dataSource = self

    let index = startingIndex != nil ? startingIndex! : 0
    if let startingTrackViewController = viewControllerAtIndex(index) {
      Global.trackManager.currentIndex = index
      Global.trackManager.play()
      setViewControllers([startingTrackViewController], direction: .Reverse, animated: false, completion: nil)
    }

    let swipeGesture = UISwipeGestureRecognizer(target: self, action: "viewSwiped:")
    swipeGesture.direction = .Down
    view.addGestureRecognizer(swipeGesture)
  }

  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "playlistOver:", name: Global.PlaylistOverNotification, object: nil)
  }

  override func viewDidDisappear(animated: Bool) {
    super.viewDidDisappear(animated)
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }

  func viewControllerAtIndex(index: Int) -> TrackViewController? {
    if index < 0 || index >= Global.trackManager.tracks.count { return nil }
    let trackViewController = storyboard?.instantiateViewControllerWithIdentifier("TrackViewController") as! TrackViewController
    trackViewController.delegate = self
    trackViewController.track = Global.trackManager.tracks[index]
    trackViewController.playerItem = Global.trackManager.playerItems[index]
    return trackViewController
  }

  func goToNextPage() {
    guard let currentViewController = viewControllers?[0] as? TrackViewController else { return }
    guard let index = Global.trackManager.getTrackIndex(currentViewController.track) else { return }
    guard let viewController = viewControllerAtIndex(index + 1) else { return }
    setViewControllers([viewController], direction: .Forward, animated: true, completion: nil)
  }

  func goToPreviousPage() {
    guard let currentViewController = viewControllers?[0] as? TrackViewController else { return }
    guard let index = Global.trackManager.getTrackIndex(currentViewController.track) else { return }
    guard let viewController = viewControllerAtIndex(index - 1) else { return }
    setViewControllers([viewController], direction: .Reverse, animated: true, completion: nil)
  }

  func viewSwiped(gesture: UISwipeGestureRecognizer) {
    dismissViewControllerAnimated(true, completion: nil)
  }

  func playlistOver(notification: NSNotification) {
    dismissViewControllerAnimated(true, completion: nil)
  }

}

extension TrackPageViewController: UIPageViewControllerDelegate {}

extension TrackPageViewController: UIPageViewControllerDataSource {

  func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
    let currentViewController = viewController as! TrackViewController
    guard let index = Global.trackManager.getTrackIndex(currentViewController.track) else { return nil }
    return viewControllerAtIndex(index - 1)
  }

  func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
    let currentViewController = viewController as! TrackViewController
    guard let index = Global.trackManager.getTrackIndex(currentViewController.track) else { return nil }
    return viewControllerAtIndex(index + 1)
  }

}
