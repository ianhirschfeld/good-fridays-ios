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
import UIKit
import SwiftyJSON

class TrackCollectionViewController: UIViewController {

  @IBOutlet weak var backgroundImageView: UIImageView!
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var downloadingView: UIView!
  @IBOutlet weak var downloadingIndicatorView: UIActivityIndicatorView!

  let CellMargin: CGFloat = 15
  let CollectionMargin: CGFloat = 20

  var shouldDownloadData = false

  override func viewDidLoad() {
    super.viewDidLoad()

    Global.tracks = [JSON]()
    Global.playerItems = [AVPlayerItem]()
    shouldDownloadData = true
  }

  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)

    if shouldDownloadData {
      shouldDownloadData = false
      downloadData()
    }
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "TrackCollectionToTrackPage" {
      let indexPath = sender as! NSIndexPath
      let destinationViewController = segue.destinationViewController as! TrackPageViewController
      destinationViewController.startingIndex = indexPath.row
    }
  }

  func downloadData() {
    let env = NSProcessInfo.processInfo().environment
    let baseUrl = env["API_BASE_URL"] != nil ? env["API_BASE_URL"]! : "https://good-fridays.herokuapp.com"

    print("Using: \(baseUrl)")

    Alamofire.request(.GET, "\(baseUrl)/tracks.json").validate().responseJSON { [unowned self] response in
      switch response.result {
      case .Success:
        if let value = response.result.value {
          Global.tracks = JSON(value).arrayValue
          for track in Global.tracks {
            let trackUrl = NSURL(string: track["stream_url"].stringValue)!
            let playerItem = AVPlayerItem(URL: trackUrl)
            Global.playerItems.append(playerItem)
          }
          self.showCollectionView()
        }
      case .Failure(let error):
        print(error)
      }
    }
  }

  func showCollectionView() {
    self.collectionView.reloadData()
    UIView.animateWithDuration(0.5, animations: { () -> Void in
      self.downloadingView.alpha = 0
    }) { (completed) -> Void in
      self.downloadingIndicatorView.stopAnimating()
      UIView.animateWithDuration(0.5, animations: { () -> Void in
        self.collectionView.alpha = 1
      })
    }
  }

}


extension TrackCollectionViewController: UICollectionViewDelegate {}

extension TrackCollectionViewController: UICollectionViewDelegateFlowLayout {

  func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
    let cellSize = (view.frame.width - (CollectionMargin * 2) - (CellMargin * 2)) / 3
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