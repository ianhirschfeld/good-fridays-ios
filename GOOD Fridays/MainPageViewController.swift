//
//  MainPageViewController.swift
//  GOOD Fridays
//
//  Created by Ian Hirschfeld on 1/20/16.
//  Copyright © 2016 The Soap Collective. All rights reserved.
//

import Alamofire
import UIKit
import SwiftyJSON

class MainPageViewController: UIPageViewController {

  var data: JSON!

  override func viewDidLoad() {
    super.viewDidLoad()

    delegate = self
    dataSource = self

    let env = NSProcessInfo.processInfo().environment
    let baseUrl = env["API_BASE_URL"] != nil ? env["API_BASE_URL"]! : "https://good-fridays.herokuapp.com"
    print("Using: \(baseUrl)")
    Alamofire.request(.GET, "\(baseUrl)/tracks.json").validate().responseJSON { response in
      switch response.result {
      case .Success:
        if let value = response.result.value {
          self.data = JSON(value)
          self.reloadData()
        }
      case .Failure(let error):
        print(error)
      }
    }
  }

  func reloadData() {
    if let startingTrackViewController = viewControllerAtIndex(0) {
      setViewControllers([startingTrackViewController], direction: .Reverse, animated: false, completion: nil)
    }
  }

  func viewControllerAtIndex(index: Int) -> TrackViewController? {
    if index < 0 || index >= data.count { return nil }
    let trackViewController = storyboard?.instantiateViewControllerWithIdentifier("TrackViewController") as! TrackViewController
    trackViewController.delegate = self
    trackViewController.trackData = data[index]
    return trackViewController
  }

  func goToNextPage() {
    guard let currentViewController = viewControllers?[0] as? TrackViewController else { return }
    guard let index = data.arrayValue.indexOf({ $0["id"].numberValue == currentViewController.trackData["id"].numberValue }) else { return }
    guard let viewController = viewControllerAtIndex(index + 1) else { return }
    setViewControllers([viewController], direction: .Forward, animated: true, completion: nil)
  }

  func goToPreviousPage() {
    guard let currentViewController = viewControllers?[0] as? TrackViewController else { return }
    guard let index = data.arrayValue.indexOf({ $0["id"].numberValue == currentViewController.trackData["id"].numberValue }) else { return }
    guard let viewController = viewControllerAtIndex(index - 1) else { return }
    setViewControllers([viewController], direction: .Reverse, animated: true, completion: nil)
  }

}

extension MainPageViewController: UIPageViewControllerDelegate {}

extension MainPageViewController: UIPageViewControllerDataSource {

  func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
    let currentViewController = viewController as! TrackViewController
    guard let index = data.arrayValue.indexOf({ $0["id"].numberValue == currentViewController.trackData["id"].numberValue }) else { return nil }
    return viewControllerAtIndex(index - 1)
  }

  func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
    let currentViewController = viewController as! TrackViewController
    guard let index = data.arrayValue.indexOf({ $0["id"].numberValue == currentViewController.trackData["id"].numberValue }) else { return nil }
    return viewControllerAtIndex(index + 1)
  }

}
