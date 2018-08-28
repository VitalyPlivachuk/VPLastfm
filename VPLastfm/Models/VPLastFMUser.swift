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
	
	public static func getUser(byName name:String, completion: @escaping (VPLastFMUser?)->()){
		let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.User.getInfo.rawValue)
		let userQuery = URLQueryItem(name: "user", value: name)
		
		if let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,userQuery){
			URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
				do{
					guard error == nil else {completion(nil); return}
					guard let data = data else {completion(nil); return}
					guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] else {completion(nil); return}
					guard let user = json["user"] as? [String:AnyObject] else {completion(nil); return}
					let decoder = JSONDecoder()
					decoder.dateDecodingStrategy = .iso8601
					let userJSON = try JSONSerialization.data(withJSONObject: user, options: [])
					let result = try decoder.decode(VPLastFMUser.self, from: userJSON)
					completion(result)
				} catch _{
					completion(nil); return
				}
			}).resume()
		}
	}
	
	public func getArtistTracks(artist:String, completion:@escaping ([VPLastFMTrack])->()) {
		let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.User.getArtistTracks.rawValue)
		let artistQuery = URLQueryItem(name: "artist", value: artist)
		let userQuery = URLQueryItem(name: "user", value: self.name)
		guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,artistQuery,userQuery) else {completion([]); return}
		
		URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
			var results:[VPLastFMTrack] = []
			guard let data = data else {completion(results); return}
			do{
				guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] else {completion(results); return}
				guard let artistTracks = json["artisttracks"] as? [String:AnyObject] else {completion(results); return}
				guard let tracks = artistTracks["track"] as? [[String:AnyObject]] else {completion(results); return}
				for track in tracks{
					let trackJSON = try JSONSerialization.data(withJSONObject: track, options: [])
					results.append(try JSONDecoder().decode(VPLastFMTrack.self, from: trackJSON))
				}
				completion(results)
			} catch _{
				completion(results)
			}
		}).resume()
		
	}
	
	public func getLovedTracks(completion:@escaping ([VPLastFMTrack])->()) {
		let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.User.getLovedTracks.rawValue)
		let userQuery = URLQueryItem(name: "user", value: self.name)
		guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,userQuery) else {completion([]); return}
		
		URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
			var results:[VPLastFMTrack] = []
			guard let data = data else {completion(results); return}
			do{
				guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] else {completion(results); return}
				guard let lovedTracks = json["lovedtracks"] as? [String:AnyObject] else {completion(results); return}
				guard let tracks = lovedTracks["track"] as? [[String:AnyObject]] else {completion(results); return}
				for track in tracks{
					let trackJSON = try JSONSerialization.data(withJSONObject: track, options: [])
					results.append(try JSONDecoder().decode(VPLastFMTrack.self, from: trackJSON))
				}
				completion(results)
			} catch  _{
				completion(results)
				return
			}
		}).resume()
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
		URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
			guard let data = data else {completion([]); return}
			var results:[VPLastFMTrack] = []
			do{
				guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] else {completion(results); return}
				guard let recentTracks = json["recenttracks"] as? [String:AnyObject] else {completion(results); return}
				guard let tracks = recentTracks["track"] as? [[String:AnyObject]] else {completion(results); return}
				for track in tracks{
					let trackJSON = try JSONSerialization.data(withJSONObject: track, options: [])
					results.append(try JSONDecoder().decode(VPLastFMTrack.self, from: trackJSON))
				}
				completion(results)
			} catch _{
				completion(results)
			}
		}).resume()
		
	}
	
	public func getTopAlbums(period: VPLastFMAPIClient.Periods = .overall, completion:@escaping ([VPLastFMAlbum])->()) {
		let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.User.getTopAlbums.rawValue)
		let userQuery = URLQueryItem(name: "user", value: self.name)
		let periodQuery = URLQueryItem(name: "period", value: period.rawValue)
		
		var results:[VPLastFMAlbum] = []
		
		guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,userQuery,periodQuery) else {completion([]); return}
		URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
			guard let data = data else {completion([]); return}
			do{
				guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] else {completion([]); return}
				guard let topAlbums = json["topalbums"] as? [String:AnyObject] else {completion([]); return}
				guard let albums = topAlbums["album"] as? [[String:AnyObject]] else {completion([]); return}
				for album in albums{
					let albumJSON = try JSONSerialization.data(withJSONObject: album, options: [])
					results.append(try! JSONDecoder().decode(VPLastFMAlbum.self, from: albumJSON))
				}
				completion(results)
			} catch _{
				completion(results)
			}
		}).resume()
		
	}
	
	public func getTopArtists(limit:Int=50, period: VPLastFMAPIClient.Periods = .overall, completion:@escaping ([VPLastFMArtist])->()) {
		let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.User.getTopArtists.rawValue)
		let userQuery = URLQueryItem(name: "user", value: self.name)
		let periodQuery = URLQueryItem(name: "period", value: period.rawValue)
		let limitQuery = URLQueryItem(name: "limit", value: String(limit))
		
		var results:[VPLastFMArtist] = []
		guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,userQuery,periodQuery,limitQuery) else {completion([]); return}
		URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
			guard let data = data else {completion([]); return}
			do{
				guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] else {completion([]); return}
				guard let topArtists = json["topartists"] as? [String:AnyObject] else {completion([]); return}
				guard let artists = topArtists["artist"] as? [[String:AnyObject]] else {completion([]); return}
				for artist in artists{
					let artistJSON = try JSONSerialization.data(withJSONObject: artist, options: [])
					results.append(try! JSONDecoder().decode(VPLastFMArtist.self, from: artistJSON))
				}
				completion(results)
			} catch _{
				completion(results)
			}
		}).resume()
	}
	
	public func getTopTracks(limit:Int=50, period: VPLastFMAPIClient.Periods = .overall, completion:@escaping ([VPLastFMTrack])->()) {
		let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.User.getTopTracks.rawValue)
		let userQuery = URLQueryItem(name: "user", value: self.name)
		let periodQuery = URLQueryItem(name: "period", value: period.rawValue)
		let limitQuery = URLQueryItem(name: "limit", value: String(limit))
		
		var results:[VPLastFMTrack] = []
		guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,userQuery,periodQuery,limitQuery) else {completion([]); return}
		URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
			guard let data = data else {completion([]); return}
			do{
				guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] else {completion([]); return}
				guard let topTracks = json["toptracks"] as? [String:AnyObject] else {completion([]); return}
				guard let tracks = topTracks["track"] as? [[String:AnyObject]] else {completion([]); return}
				for track in tracks{
					let trackJSON = try JSONSerialization.data(withJSONObject: track, options: [])
					results.append(try! JSONDecoder().decode(VPLastFMTrack.self, from: trackJSON))
				}
				completion(results)
			} catch _{
				completion(results)
			}
		}).resume()
	}
	
}
