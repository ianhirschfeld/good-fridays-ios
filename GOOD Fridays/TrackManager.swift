//
//  TrackManager.swift
//  GOOD Fridays
//
//  Created by Ian Hirschfeld on 2/21/16.
//  Copyright © 2016 The Soap Collective. All rights reserved.
//

import AlamofireImage
import AVFoundation
import MediaPlayer
import UIKit
import SwiftyJSON

class TrackManager {

  var currentIndex = 0
  var isPlaying = false
  var player = AVPlayer()
  var playerItems = [AVPlayerItem]()
  var playerTimeObserver: AnyObject?
  var shouldAutoPlay = false
  var tracks = [JSON]()

  init () {
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerItemFinished:", name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
  }

  func setupPlayerItems() {
    for track in tracks {
      if let trackUrl = NSURL(string: track["stream_url"].stringValue) {
        let playerItem = AVPlayerItem(URL: trackUrl)
        playerItems.append(playerItem)
      }
    }
  }

  func currentPlayerItem() -> AVPlayerItem {
    return playerItems[currentIndex]
  }

  func currentTrack() -> JSON {
    return tracks[currentIndex]
  }

  func getTrackIndex(track: JSON) -> Int? {
    return tracks.indexOf({ $0["id"].numberValue == track["id"].numberValue })
  }

  func setNowPlayingInfo() {
    let playerItem = currentPlayerItem()
    let track = currentTrack()
    let seconds = playerItem.currentTime().seconds < 0 ? 0 : playerItem.currentTime().seconds

    MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = [
      MPMediaItemPropertyTitle: track["title"].stringValue,
      MPMediaItemPropertyArtist: track["artist"].stringValue,
      MPMediaItemPropertyPlaybackDuration: track["duration"].doubleValue / 1000,
      MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1 : 0,
      MPNowPlayingInfoPropertyElapsedPlaybackTime: seconds,
    ]

    if let artworkUrl = NSURL(string: track["artwork_url"].stringValue) {
      let downloader = ImageDownloader()
      let URLRequest = NSURLRequest(URL: artworkUrl)
      downloader.downloadImage(URLRequest: URLRequest) { response in
        if let image = response.result.value {
          MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo?[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: image)
        }
      }
    }
  }

  func removePlayerTimeObserver() {
    if let observer = playerTimeObserver {
      player.removeTimeObserver(observer)
      playerTimeObserver = nil
    }
  }

  func togglePlayPause() {
    isPlaying ? pause() : play()
  }

  func play() {
    let track = currentTrack()
    if !track["streamable"].boolValue { return }

    let playerItem = currentPlayerItem()
    player.replaceCurrentItemWithPlayerItem(playerItem)

    if playerItem.currentTime().seconds == 0 {
      player.play()
    } else {
      player.seekToTime(playerItem.currentTime(), completionHandler: { (completed) -> Void in
        self.player.play()
      })
    }

    isPlaying = true
    playerTimeObserver = player.addPeriodicTimeObserverForInterval(
      CMTimeMake(1, 10),
      queue: dispatch_get_main_queue(),
      usingBlock: { (time) -> Void in
        let seconds = playerItem.currentTime().seconds < 0 ? 0 : playerItem.currentTime().seconds
        NSNotificationCenter.defaultCenter().postNotificationName(
          Global.PlayerItemTickNotification,
          object: playerItem,
          userInfo: ["seconds": seconds]
        )
    })

    setNowPlayingInfo()
    NSNotificationCenter.defaultCenter().postNotificationName(Global.PlayNotification, object: nil)
  }

  func pause() {
    player.pause()
    isPlaying = false
    removePlayerTimeObserver()
    setNowPlayingInfo()
    NSNotificationCenter.defaultCenter().postNotificationName(Global.PauseNotification, object: nil)
  }

  // TODO: Make this take an autoplay bool argument
  func next() {
    pause()
    if currentIndex + 1 <= tracks.count - 1 {
      currentIndex++
      play()
      NSNotificationCenter.defaultCenter().postNotificationName(Global.NextNotification, object: nil)
    }
  }

  // TODO: Make this take an autoplay bool argument
  func previous() {
    pause()
    if currentIndex - 1 >= 0 {
      currentIndex--
      play()
      NSNotificationCenter.defaultCenter().postNotificationName(Global.PreviousNotification, object: nil)
    }
  }

  func seekTo(seconds: Double) {
    let time = CMTime(seconds: seconds, preferredTimescale: currentPlayerItem().currentTime().timescale)
    player.seekToTime(time)
  }

  func stop() {
    player.pause()
    isPlaying = false
    removePlayerTimeObserver()
    player.replaceCurrentItemWithPlayerItem(nil)
    playerItems.removeAll()
    MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = nil
  }

  func playerItemFinished(notification: NSNotification) {
    // TODO: Handle end of track
  }

}
