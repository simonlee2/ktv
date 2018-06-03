//
//  ViewController.swift
//  Cashbox
//
//  Created by Shao-Ping Lee on 3/6/18.
//  Copyright © 2018 Simon Lee. All rights reserved.
//

import UIKit
import Kanna
import Spartan

class ViewController: UIViewController {
    
    // Spotify Auth
    var auth = SPTAuth.defaultInstance()!
    var session:SPTSession!
    var player: SPTAudioStreamingController?
    var loginURL: URL?
    
    // pager
    var playlistListPager: PagingObject<SimplifiedPlaylist>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSpotify()
        spotifyLogin()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateAfterFirstLogin), name: nil, object: nil)
        
        let searchParam = SearchParameter(langCode: 1, artist: "", chkTitle: 1, title: "台北的天空")
        search(parameter: searchParam) { (results) in
            print(results)
        }
    }
    
    func setupSpotify() {
        SPTAuth.defaultInstance().clientID = "2c834a5a2a3949f6a3ea4176cb016b26"
        SPTAuth.defaultInstance().redirectURL = URL(string: "Cashbox://returnAfterLogin")
        SPTAuth.defaultInstance().requestedScopes = [SPTAuthStreamingScope, SPTAuthUserReadPrivateScope, SPTAuthPlaylistModifyPublicScope, SPTAuthPlaylistModifyPrivateScope]
        loginURL = SPTAuth.defaultInstance().spotifyAppAuthenticationURL()
    }
    
    @objc func updateAfterFirstLogin() {
        guard let sessionData = UserDefaults.standard.object(forKey: "SpotifySession") as? Data else { return }
        
        guard let firstTimeSesion = NSKeyedUnarchiver.unarchiveObject(with: sessionData) as? SPTSession else { return }
        
        self.session = firstTimeSesion
        
        
        
//        initializePlayer(authSession: self.session)
    }
    
    func initializePlayer(authSession: SPTSession) {
        guard self.player == nil else { return }
        
        guard let player = SPTAudioStreamingController.sharedInstance() else { return }
        self.player = player
        player.playbackDelegate = self
        player.delegate = self
        do {
            try player.start(withClientId: auth.clientID)
        } catch let error {
            print(error)
        }
        
        self.player?.login(withAccessToken: authSession.accessToken)
    }
    
    func spotifyLogin() {
        guard let loginURL = loginURL else { return }
        if UIApplication.shared.canOpenURL(loginURL) {
            UIApplication.shared.open(loginURL, options: [:])
            
            if auth.canHandle(auth.redirectURL) {
                
            }
        }
    }
    
    func search(parameter: SearchParameter, completion: @escaping ([SearchResult]) -> Void) {
        let formString = "LangCode=\(parameter.langCode)&Artist=\(parameter.artist)&Chk_Title=\(parameter.chkTitle)&Title=\(parameter.title)"
        let postData = NSData(data: formString.data(using: .utf8)!)
        
        let request = NSMutableURLRequest(url: NSURL(string: "http://www.cashboxparty.com/mysong/mysong_search_r.asp")! as URL,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10.0)
        request.httpMethod = "POST"
        request.httpBody = postData as Data
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                completion([])
            } else {
                if let data = data, let html = String(data: data, encoding: .utf8) {
                    let results = self.parseResponse(html: html)
                    completion(results)
                }
            }
        })
        
        dataTask.resume()
    }
    
    func parseResponse(html: String) -> [SearchResult] {
        guard let doc = try? Kanna.HTML(html: html, encoding: .utf8) else { return [] }
        let chartset = CharacterSet(charactersIn: " \r\t\n")
        var results = [SearchResult]()
        for (index, row) in doc.css("form table")[1].css("tr").enumerated() {
            guard index != 0 else { continue }
            let resultArray = row.css("td").compactMap { column in
                return column.content?.trimmingCharacters(in: chartset)
            }.filter({$0 != ""})
            
            let artists = resultArray[3].split(separator: "、").map({String($0)})
            let result = SearchResult(language: resultArray[1], artist: artists, title: resultArray[2], identifier: resultArray[0])
            results.append(result)
        }
        
        return results
    }
    
    func loadPlaylists(completion: @escaping (PagingObject<SimplifiedPlaylist>) -> Void) {
        _ = Spartan.getMyPlaylists(success: { (pagingObject) in
            completion(pagingObject)
        }, failure: { (error) in
            print("Error loading playlists: \(error)")
        })
    }
}

extension ViewController: SPTAudioStreamingDelegate {
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        print("logged in")
        loadPlaylists { (pagingObject) in
            self.playlistListPager = pagingObject
            pagingObject.items.map({ (playlist) -> String in
                playlist.name
            }).forEach({print($0)})
        }
    }
}

extension ViewController: SPTAudioStreamingPlaybackDelegate {
    
}

struct SearchParameter {
    let langCode: Int
    let artist: String
    let chkTitle: Int
    let title: String
}

struct SearchResult {
    let language: String
    let artist: [String]
    let title: String
    let identifier: String
}

