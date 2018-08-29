//
//  LastFMTrack.swift
//  lastfm
//
//  Created by Vitaly Plivachuk on 11/29/17.
//  Copyright © 2017 Vitaly Plivachuk. All rights reserved.
//

import Foundation

final public class VPLastFMTrack: Codable, VPLastFMModel {
    
    public let name: String
    public let mbid: String?
    public let url: URL?
    public let artist: VPLastFMArtist
    public let toptags: Tags?
    public let wiki: Bio?
    public var album: VPLastFMAlbum?
    public let image: VPLastFMImage?
    
    
    public struct Tags: Codable {
        let tag: [VPLastFMTag]
    }
    
    public struct Bio: Codable {
        let summary: String?
        let content: String?
    }
    
    public init (name: String,mbid: String?,url: URL?,image:VPLastFMImage?, album:VPLastFMAlbum?, artist: VPLastFMArtist,tags: Tags?,wiki: Bio?){
        self.name = name
        self.mbid = mbid
        self.url = url
        self.artist = artist
        self.toptags = tags
        self.wiki = wiki
        self.album = album
        self.image = image
    }
    
    convenience public init(from decoder: Decoder) throws{
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let name = try container.decode(String.self, forKey: .name)
        let mbid: String? = try container.decodeIfPresent(String.self, forKey: .mbid)
        let url: URL? = try container.decodeIfPresent(URL.self, forKey: .url)
        var image: VPLastFMImage? = try container.decodeIfPresent(VPLastFMImage.self, forKey: .image)
        if image?.small == nil && image?.medium == nil && image?.large == nil && image?.extraLarge == nil {
            image = nil
        }
        
        
        let artist: VPLastFMArtist
        do {
            artist = try container.decode(VPLastFMArtist.self, forKey: .artist)
        } catch {
            let artistName = try container.decode(String.self, forKey: .artist)
            artist = VPLastFMArtist(name: artistName,
                                  mbid: nil,
                                  url: nil,
                                  image: nil,
                                  stats: nil,
                                  tags: nil,
                                  bio: nil,
                                  similar:nil)
        }
        
        
        let album = try container.decodeIfPresent(VPLastFMAlbum.self, forKey: .album)
        let tags = try container.decodeIfPresent(Tags.self, forKey: .toptags)
        let wiki = try container.decodeIfPresent(Bio.self, forKey: .wiki)
        self.init(name: name,
                  mbid: mbid,
                  url: url,
                  image: image,
                  album: album,
                  artist: artist,
                  tags: tags,
                  wiki: wiki)
    }
    
    public enum LastFMTrackError: Error {
        case parse
        case url
    }
    
    
    
    public static func getCorrection(for name: String, andArtist artist:String, completion:@escaping (String?,String?)->()){
        let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Track.getCorrection.rawValue)
        let artistQuery = URLQueryItem(name: "artist", value: artist)
        let trackQuery = URLQueryItem(name: "track", value: name)
        guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,artistQuery, trackQuery) else {completion(nil,nil); return}
        
        URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            do{
                guard let data = data else {throw LastFMTrackError.parse}
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] else {throw LastFMTrackError.parse}
                guard let corrections = json["corrections"] as? [String:AnyObject] else {throw LastFMTrackError.parse}
                guard let correction = corrections["correction"] as? [String:AnyObject] else {throw LastFMTrackError.parse}
                guard let track = correction["track"] as? [String:AnyObject] else {throw LastFMTrackError.parse}
                guard let name = track["name"] as? String else {throw LastFMTrackError.parse}
                guard let artist = track["artist"] as? [String:AnyObject] else {throw LastFMTrackError.parse}
                guard let artistName = artist["name"] as? String else {throw LastFMTrackError.parse}
                completion(artistName,name)
            } catch _{
                completion(nil,nil)
            }
        }).resume()
    }
    
    public static func getTrack(byName name:String, artist:String, completion: @escaping (VPLastFMTrack?)->()){
        let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Track.getInfo.rawValue)
        let trackQuery = URLQueryItem(name: "track", value: name)
        let artistQuery = URLQueryItem(name: "artist", value: artist)
        guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,trackQuery,artistQuery) else {completion(nil); return}
        
        VPLastFMAPIClient.shared.getModel(VPLastFMTrack.self, url: url, path: ["track"], arrayName: nil) { result in
            completion(result)
        }
    }
    
    public func getSimilar(limit:Int,completion:@escaping ([VPLastFMTrack])->()) {
        let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Track.getSimilar.rawValue)
        let limitQuery = URLQueryItem(name: "limit", value: String(limit))
        let artistQuery = URLQueryItem(name: "artist", value: self.artist.name)
        let trackQuery = URLQueryItem(name: "track", value: self.name)
        
        guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,limitQuery,artistQuery,trackQuery) else {completion([]); return}
        
        VPLastFMAPIClient.shared.getModel([VPLastFMTrack].self, url: url, path: ["similartracks"], arrayName: "track") { result in
            completion(result ?? [])
        }
    }
    
    public func getSimilarByTags(limit:Int, completion:@escaping ([VPLastFMTrack])->()){
        var result: [VPLastFMTrack] = []
        self.artist.getSimilar(limit: Int(limit/3), extended: true) { similarArtists in
            let dg = DispatchGroup()
            for artist in similarArtists{
                dg.enter()
                artist.getTopTracks(limit: 3, completion: { tracks in
                    result.append(contentsOf: tracks)
                    dg.leave()
                })
            }
            dg.notify(queue: .main, execute: {
                var filteredResult = result.uniqueElements
                filteredResult.shuffle()
                completion(filteredResult)
            })
        }
    }
    
    
    public static func getTop(limit:Int = 50, completion: @escaping ([VPLastFMTrack])->()) {
        let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Chart.getTopTracks.rawValue)
        let limitQuery = URLQueryItem(name: "limit", value: String(limit))
        guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,limitQuery) else {completion([]); return}
        
        VPLastFMAPIClient.shared.getModel([VPLastFMTrack].self, url: url, path: ["tracks"], arrayName: "track") { result in
            completion(result ?? [])
        }
    }
    
    public func getTopTags(limit:Int = 10, completion:@escaping ([VPLastFMTag])->()) {
        let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Track.getTopTags.rawValue)
        let artistQuery = URLQueryItem(name: "artist", value: self.artist.name)
        let trackQuery = URLQueryItem(name: "track", value: self.name)
        let limitQuery = URLQueryItem(name: "limit", value: String(limit))
        guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,artistQuery,trackQuery,limitQuery) else {completion([]); return}
        
        VPLastFMAPIClient.shared.getModel([VPLastFMTag].self, url: url, path: ["toptags"], arrayName: "tag") { result in
            completion(result ?? [])
        }
    }
    
    public func love(completion: @escaping (Bool)->()) {
        
        let apiSigComponents = [
            "method" : VPLastFMAPIClient.APIMethods.Track.love.rawValue,
            "artist" : self.artist.name,
            "track" : self.name,
            "sk" : VPLastFMLoginManager.authData!.key
        ]
        
        let apiSig = VPLastFMAPIClient.shared.createApiSigString(with: apiSigComponents)
        
        let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Track.love.rawValue)
        let artistQuery = URLQueryItem(name: "artist", value: self.artist.name)
        let trackQuery = URLQueryItem(name: "track", value: self.name)
        let apiSigQuery = URLQueryItem(name: "api_sig", value: apiSig)
        let skQuery = URLQueryItem(name: "sk", value: VPLastFMLoginManager.authData?.key)
        
        var request = URLRequest(url: VPLastFMAPIClient.shared.createURL(with: methodQuery, artistQuery, trackQuery, apiSigQuery,skQuery)!)
        request.httpMethod = "POST"
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            do{
                guard let data = data else {
                    completion(false)
                    return
                }
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] else {
                    completion(false)
                    return
                }
                
                if json.isEmpty{
                    completion(true)
                } else {
                    completion(false)
                }
            } catch let error {
                print(error.localizedDescription)
                completion(false)
            }
            }.resume()
    }
    
    public func unlove(completion: @escaping (Bool)->()) {
        
        let apiSigComponents = [
            "method" : VPLastFMAPIClient.APIMethods.Track.unlove.rawValue,
            "artist" : self.artist.name,
            "track" : self.name,
            "sk" : VPLastFMLoginManager.authData!.key
        ]
        
        let apiSig = VPLastFMAPIClient.shared.createApiSigString(with: apiSigComponents)
        
        let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Track.unlove.rawValue)
        let artistQuery = URLQueryItem(name: "artist", value: self.artist.name)
        let trackQuery = URLQueryItem(name: "track", value: self.name)
        let apiSigQuery = URLQueryItem(name: "api_sig", value: apiSig)
        let skQuery = URLQueryItem(name: "sk", value: VPLastFMLoginManager.authData?.key)
        
        var request = URLRequest(url: VPLastFMAPIClient.shared.createURL(with: methodQuery, artistQuery, trackQuery, apiSigQuery,skQuery)!)
        request.httpMethod = "POST"
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            do{
                guard let data = data else {
                    completion(false)
                    return
                }
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] else {
                    completion(false)
                    return
                }
                
                if json.isEmpty{
                    completion(true)
                } else {
                    completion(false)
                }
            } catch let error {
                print(error.localizedDescription)
                completion(false)
            }
            }.resume()
    }
    
    
    public func fillInfo( completion: @escaping ()->()) {
        if self.album == nil{
            VPLastFMTrack.getTrack(byName: self.name, artist: self.artist.name) {[weak self] result in
                self?.album = result?.album
                completion()
            }
        }
    }
    
    
    public func scrobble(completion: @escaping (Bool)->()) {
        guard let key = VPLastFMLoginManager.authData?.key else {completion(false); return}
        let timestamp = Int(Date().timeIntervalSince1970)
        let apiSigComponents = [
            "method" : VPLastFMAPIClient.APIMethods.Track.scrobble.rawValue,
            "artist" : self.artist.name,
            "track" : self.name,
            "sk" : key,
            "timestamp" : String(timestamp),
            "mbid" : self.mbid
        ]
        
        let apiSig = VPLastFMAPIClient.shared.createApiSigString(with: apiSigComponents)
        
        let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Track.scrobble.rawValue)
        let artistQuery = URLQueryItem(name: "artist", value: self.artist.name)
        let trackQuery = URLQueryItem(name: "track", value: self.name)
        let apiSigQuery = URLQueryItem(name: "api_sig", value: apiSig)
        let timestampQuery = URLQueryItem(name: "timestamp", value: String(timestamp))
        let skQuery = URLQueryItem(name: "sk", value: VPLastFMLoginManager.authData?.key)
        let mbidQuery = self.mbid != nil ? URLQueryItem(name: "mbid", value: self.mbid!) : nil
        
        var request = URLRequest(url: VPLastFMAPIClient.shared.createURL(with: methodQuery, artistQuery, trackQuery, apiSigQuery,skQuery,timestampQuery,mbidQuery)!)
        request.httpMethod = "POST"
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            do{
                guard let data = data else {
                    completion(false)
                    return
                }
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] else {
                    completion(false)
                    return
                }
                
                if json.isEmpty{
                    completion(true)
                } else {
                    completion(false)
                }
            } catch let error {
                print(error.localizedDescription)
                completion(false)
            }
            }.resume()
    }
    
    public func updateNowPlaying (completion: @escaping (Bool)->()) {
        let apiSigComponents = [
            "method" : VPLastFMAPIClient.APIMethods.Track.updateNowPlaying.rawValue,
            "artist" : self.artist.name,
            "track" : self.name,
            "sk" : VPLastFMLoginManager.authData!.key,
            ]
        
        let apiSig = VPLastFMAPIClient.shared.createApiSigString(with: apiSigComponents)
        
        let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Track.updateNowPlaying.rawValue)
        let artistQuery = URLQueryItem(name: "artist", value: self.artist.name)
        let trackQuery = URLQueryItem(name: "track", value: self.name)
        let apiSigQuery = URLQueryItem(name: "api_sig", value: apiSig)
        let skQuery = URLQueryItem(name: "sk", value: VPLastFMLoginManager.authData?.key)
        
        var request = URLRequest(url: VPLastFMAPIClient.shared.createURL(with: methodQuery, artistQuery, trackQuery, apiSigQuery,skQuery)!)
        request.httpMethod = "POST"
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            do{
                guard let data = data else {
                    completion(false)
                    return
                }
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] else {
                    completion(false)
                    return
                }
                
                if json.isEmpty{
                    completion(true)
                } else {
                    completion(false)
                }
            } catch let error {
                print(error.localizedDescription)
                completion(false)
            }
            }.resume()
    }
    
    
    public static func search(name:String, artist: String?, completion: @escaping ([VPLastFMTrack])->()) {
        let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Track.search.rawValue)
        let trackQuery = URLQueryItem(name: "track", value: name)
        let artistQuery = URLQueryItem(name: "artist", value: artist)
        guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,trackQuery,artistQuery) else {completion([]); return}
        
        VPLastFMAPIClient.shared.getModel([VPLastFMTrack].self, url: url, path: ["results","trackmatches"], arrayName: "track") { result in
            completion(result ?? [])
        }
    }
}

extension VPLastFMTrack: Hashable{
    public var hashValue: Int {
        return name.hashValue ^ artist.name.hashValue &* 16777619
    }
}

enum TrackArrayCodingKeys: String, CodingKey {
    case track
}
extension VPLastFMTrack: Equatable{
    public static func ==(lhs: VPLastFMTrack, rhs: VPLastFMTrack) -> Bool {
        return (lhs.name == rhs.name) && (lhs.artist.name == rhs.artist.name)
    }
}

