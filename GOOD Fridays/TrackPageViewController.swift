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
      setViewControllers([startingTrackViewController], direction: .Reverse, animated: false, completion: nil)
    }
  }

  func viewControllerAtIndex(index: Int) -> TrackViewController? {
    if index < 0 || index >= Global.tracks.count { return nil }
    let trackViewController = storyboard?.instantiateViewControllerWithIdentifier("TrackViewController") as! TrackViewController
    trackViewController.delegate = self
    trackViewController.trackData = Global.tracks[index]
    return trackViewController
  }

  func goToNextPage() {
    guard let currentViewController = viewControllers?[0] as? TrackViewController else { return }
    guard let index = Global.tracks.indexOf({ $0["id"].numberValue == currentViewController.trackData["id"].numberValue }) else { return }
    guard let viewController = viewControllerAtIndex(index + 1) else { return }
    setViewControllers([viewController], direction: .Forward, animated: true, completion: nil)
  }

  func goToPreviousPage() {
    guard let currentViewController = viewControllers?[0] as? TrackViewController else { return }
    guard let index = Global.tracks.indexOf({ $0["id"].numberValue == currentViewController.trackData["id"].numberValue }) else { return }
    guard let viewController = viewControllerAtIndex(index - 1) else { return }
    setViewControllers([viewController], direction: .Reverse, animated: true, completion: nil)
  }

}

extension TrackPageViewController: UIPageViewControllerDelegate {}

extension TrackPageViewController: UIPageViewControllerDataSource {

  func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
    let currentViewController = viewController as! TrackViewController
    guard let index = Global.tracks.indexOf({ $0["id"].numberValue == currentViewController.trackData["id"].numberValue }) else { return nil }
    return viewControllerAtIndex(index - 1)
  }

  func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
    let currentViewController = viewController as! TrackViewController
    guard let index = Global.tracks.indexOf({ $0["id"].numberValue == currentViewController.trackData["id"].numberValue }) else { return nil }
    return viewControllerAtIndex(index + 1)
  }

}
