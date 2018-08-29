//
//  LastFMUser.swift
//  lastfm
//
//  Created by Vitaly Plivachuk on 11/29/17.
//  Copyright © 2017 Vitaly Plivachuk. All rights reserved.
//

import Foundation

final public class VPLastFMUser: Codable {

	public let name: String
	public let realName: String?
	public let url: URL?
	public let image: VPLastFMImage?
	public let country: String?
//	let playcount: String?
    
    
	enum CodingKeys: String, CodingKey {
		case name
		case realName = "realname"
		case image
		case url
		case country
//		case playcount
	}
    
    enum VPLastFMUserError:Error{
        case parse
    }
	
	public static func getUser(byName name:String, completion: @escaping (VPLastFMUser?)->()){
		let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.User.getInfo.rawValue)
		let userQuery = URLQueryItem(name: "user", value: name)
        guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,userQuery) else {completion(nil); return}
        
        VPLastFMAPIClient.shared.getModel(VPLastFMUser.self, url: url, path: ["user"], arrayName: nil) { result in
            completion(result)
        }
	}
	
	public func getArtistTracks(artist:String, completion:@escaping ([VPLastFMTrack])->()) {
		let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.User.getArtistTracks.rawValue)
		let artistQuery = URLQueryItem(name: "artist", value: artist)
		let userQuery = URLQueryItem(name: "user", value: self.name)
		guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,artistQuery,userQuery) else {completion([]); return}
        
        VPLastFMAPIClient.shared.getModel([VPLastFMTrack].self, url: url, path: ["artisttracks"], arrayName: "track") { result in
            completion(result ?? [])
        }
	}
	
	public func getLovedTracks(completion:@escaping ([VPLastFMTrack])->()) {
		let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.User.getLovedTracks.rawValue)
		let userQuery = URLQueryItem(name: "user", value: self.name)
		guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,userQuery) else {completion([]); return}
        
        VPLastFMAPIClient.shared.getModel([VPLastFMTrack].self, url: url, path: ["lovedtracks"], arrayName: "track") { result in
            completion(result ?? [])
        }
	}
	
	public func getRecentTracks(limit:Int = 50, from firstDate:Date?, to secondDate:Date?, completion:@escaping ([VPLastFMTrack])->()) {
		let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.User.getRecentTracks.rawValue)
		let userQuery = URLQueryItem(name: "user", value: self.name)
		let limitQuery = URLQueryItem(name: "limit", value: String(limit))
		let extendedQuery = URLQueryItem(name: "extended", value: "1")
		
		let firstDateQuery: URLQueryItem?
		if let firstDate = firstDate{
			let timestamp = Int(firstDate.timeIntervalSince1970)
			firstDateQuery = URLQueryItem(name: "from", value: String(timestamp))
		} else {
			firstDateQuery = nil
		}
		
		let secondDateQuery: URLQueryItem?
		if let secondDate = secondDate{
			let timestamp = Int(secondDate.timeIntervalSince1970)
			secondDateQuery = URLQueryItem(name: "to", value: String(timestamp))
		} else {
			secondDateQuery = nil
		}
		
		guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,userQuery,limitQuery, extendedQuery, firstDateQuery, secondDateQuery) else {completion([]); return}
        
        VPLastFMAPIClient.shared.getModel([VPLastFMTrack].self, url: url, path: ["recenttracks"], arrayName: "track") { result in
            completion(result ?? [])
        }
	}
	
	public func getTopAlbums(period: VPLastFMAPIClient.Periods = .overall, completion:@escaping ([VPLastFMAlbum])->()) {
		let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.User.getTopAlbums.rawValue)
		let userQuery = URLQueryItem(name: "user", value: self.name)
		let periodQuery = URLQueryItem(name: "period", value: period.rawValue)
		
		guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,userQuery,periodQuery) else {completion([]); return}
        
        VPLastFMAPIClient.shared.getModel([VPLastFMAlbum].self, url: url, path: ["topalbums"], arrayName: "album") { result in
            completion(result ?? [])
        }
	}
	
	public func getTopArtists(limit:Int=50, period: VPLastFMAPIClient.Periods = .overall, completion:@escaping ([VPLastFMArtist])->()) {
		let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.User.getTopArtists.rawValue)
		let userQuery = URLQueryItem(name: "user", value: self.name)
		let periodQuery = URLQueryItem(name: "period", value: period.rawValue)
		let limitQuery = URLQueryItem(name: "limit", value: String(limit))
        
		guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,userQuery,periodQuery,limitQuery) else {completion([]); return}
        
        VPLastFMAPIClient.shared.getModel([VPLastFMArtist].self, url: url, path: ["topartists"], arrayName: "artist") { result in
            completion(result ?? [])
        }
	}
	
	public func getTopTracks(limit:Int=50, period: VPLastFMAPIClient.Periods = .overall, completion:@escaping ([VPLastFMTrack])->()) {
		let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.User.getTopTracks.rawValue)
		let userQuery = URLQueryItem(name: "user", value: self.name)
		let periodQuery = URLQueryItem(name: "period", value: period.rawValue)
		let limitQuery = URLQueryItem(name: "limit", value: String(limit))
		
		guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,userQuery,periodQuery,limitQuery) else {completion([]); return}
        
        VPLastFMAPIClient.shared.getModel([VPLastFMTrack].self, url: url, path: ["toptracks"], arrayName: "track") { result in
            completion(result ?? [])
        }
	}
}
