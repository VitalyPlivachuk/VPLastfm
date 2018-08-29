//
//  LastFMAPIClient.swift
//  lastfm
//
//  Created by Vitaly Plivachuk on 11/29/17.
//  Copyright © 2017 Vitaly Plivachuk. All rights reserved.
//

import Foundation
import CommonCrypto

public class VPLastFMAPIClient {
    private var apiKey: String?
	private var sharedSecret: String?
	private let apiHost = "ws.audioscrobbler.com"
	private let apiVersion = "2.0"
	
    static public let shared = VPLastFMAPIClient()
    
    private init(){}
    
    public func setUp(withApiKey: String?, sharedSecret: String?){
        self.apiKey = withApiKey
        self.sharedSecret = sharedSecret
    }
    
    enum VPLastFMAPIClientError:Error {
        case parse
    }
    
	public enum APIMethods {
		enum Album : String {
			case addTags = "album.addTags"
			case getInfo = "album.getInfo"
			case getTags = "album.getTags"
			case getTopTags = "album.getTopTags"
			case removeTag = "album.removeTag"
			case search = "album.search"
		}
		
		enum Track : String {
			case addTags = "track.addTags"
			case getCorrection = "track.getCorrection"
			case getInfo = "track.getInfo"
			case getSimilar = "track.getSimilar"
			case getTags = "track.getTags"
			case getTopTags = "track.getTopTags"
			case love = "track.love"
			case removeTag = "track.removeTag"
			case scrobble = "track.scrobble"
			case search = "track.search"
			case unlove = "track.unlove"
			case updateNowPlaying = "track.updateNowPlaying"
		}
		
		enum Artist : String {
			case addTags = "artist.addTags"
			case getCorrection = "artist.getCorrection"
			case getInfo = "artist.getInfo"
			case getSimilar = "artist.getSimilar"
			case getTags = "artist.getTags"
			case getTopAlbums = "artist.getTopAlbums"
			case getTopTags = "artist.getTopTags"
			case getTopTracks = "artist.getTopTracks"
			case removeTag = "artist.removeTag"
			case search = "artist.search"
		}
		
		enum Tag : String {
			case getInfo = "tag.getInfo"
			case getSimilar = "tag.getSimilar"
			case getTopAlbums = "tag.getTopAlbums"
			case getTopArtists = "tag.getTopArtists"
			case getTopTags = "tag.getTopTags"
			case getTopTracks = "tag.getTopTracks"
			case getWeeklyChartList = "tag.getWeeklyChartList"
		}
		
		enum Auth : String {
			case getMobileSession = "auth.getMobileSession"
			case getSession = "auth.getSession"
			case getToken = "auth.getToken"
		}
		
		enum Chart : String {
			case getTopArtists = "chart.getTopArtists"
			case getTopTags = "chart.getTopTags"
			case getTopTracks = "chart.getTopTracks"
		}
		
		enum User : String {
			case getArtistTracks = "user.getArtistTracks"
			case getFriends = "user.getFriends"
			case getInfo = "user.getInfo"
			case getLovedTracks = "user.getLovedTracks"
			case getPersonalTags = "user.getPersonalTags"
			case getRecentTracks = "user.getRecentTracks"
			case getTopAlbums = "user.getTopAlbums"
			case getTopArtists = "user.getTopArtists"
			case getTopTags = "user.getTopTags"
			case getTopTracks = "user.getTopTracks"
			case getWeeklyAlbumChart = "user.getWeeklyAlbumChart"
			case getWeeklyArtistChart = "user.getWeeklyArtistChart"
			case getWeeklyChartList = "user.getWeeklyChartList"
			case getWeeklyTrackChart = "user.getWeeklyTrackChart"
		}
	}
	
	public enum Periods : String {
		case overall = "overall"
		case week = "7day"
		case oneMonth = "1month"
		case threeMonth = "3month"
		case halfYear = "6month"
		case oneYear = "12month"
	}
	
    func createURL(with queryItems:URLQueryItem?...) ->(URL?){
        guard let apiKey = apiKey else {print("API Key not setted up"); return nil}
		var _queryItems: [URLQueryItem] = []
		for item in queryItems {
			if let item = item {
				_queryItems.append(item)
			}
		}
		var urlComponents = URLComponents()
		urlComponents.scheme = "https"
		urlComponents.host = apiHost
		urlComponents.path = "/\(apiVersion)"
		let apiKeyQuery = URLQueryItem(name: "api_key", value: apiKey)
		let formatQuery = URLQueryItem(name: "format", value: "json")
        _queryItems.append(apiKeyQuery)
        _queryItems.sort{ $0.name < $1.name}
        _queryItems.append(formatQuery)
		urlComponents.queryItems = _queryItems
//        urlComponents.queryItems?.append(contentsOf: [apiKeyQuery,formatQuery])
		return urlComponents.url
	}
	
    func createApiSigString(with components:[String:String?])->(String){
        guard let apiKey = apiKey, let sharedSecret = sharedSecret else {print("API Key, or shared secret not setted up"); return ""}
        var components: [String:String] = {
            var tempComponents: [String:String] = [:]
            for key in components.keys{
                if let value = components[key]{
                    tempComponents[key] = value
                }
            }
            return tempComponents
        }()
		components["api_key"] = apiKey
        components["sk"] = VPLastFMLoginManager.authData?.key
		let sortedApiSigComponents = Array(components.keys).sorted(by: <)
		var apiSig = ""
		for key in sortedApiSigComponents{
//            let percentEncodedValue = components[key]?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
//            apiSig.append("\(key)\(percentEncodedValue!)")
            apiSig += "\(key)\(components[key]!)"
		}
		apiSig.append(sharedSecret)
		let apiSigMD5hex = apiSig.getMD5hex()
		return apiSigMD5hex
	}
    
    func getModel<T:Decodable>(_ t:T.Type, url:URL, path:[String]?, arrayName:String?, completion:@escaping (T?)->()) {
        URLSession.shared.dataTask(with: url, completionHandler: {(data, response, error) in
            do{
                guard let data = data else {throw VPLastFMAPIClientError.parse}
                guard var json = try! JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] else {throw VPLastFMAPIClientError.parse}
                
                try? path?.forEach{
                    guard let underRoot = json[$0] as? [String:AnyObject] else {throw VPLastFMAPIClientError.parse}
                    json = underRoot
                }
                
                let array: [[String:AnyObject]]?
                if let arrayName = arrayName{
                    array = json[arrayName] as? [[String:AnyObject]]
                } else {array = nil}
                
                let cleanJSON = try JSONSerialization.data(withJSONObject: array ?? json, options: [])
                
                let result = try JSONDecoder().decode(T.self, from: cleanJSON)
                completion(result)
            } catch _{
                completion(nil)
            }
        }).resume()
    }
}
