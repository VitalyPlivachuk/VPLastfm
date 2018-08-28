//
//  LastFMTag.swift
//  lastfm
//
//  Created by Vitaly Plivachuk on 11/30/17.
//  Copyright © 2017 Vitaly Plivachuk. All rights reserved.
//

import Foundation

final public class VPLastFMTag: VPLastFMModel, Codable {
    public var image: VPLastFMImage?{return nil}
    
    public var mbid: String?{return nil}
    
	public let name: String
	public let url: URL?
	public let wiki: Bio?
	
	public struct Bio: Codable{
		let summary: String?
		let content: String?
	}
	
	enum TagsArrayCodingKeys:String, CodingKey {
		case tag
	}
	
	public init(name:String) {
		self.name = name
		self.url = nil
		self.wiki = nil
	}
	
	public enum LastFMTagError: Error {
		case parse
		case url
	}
	
	public static func getTag(byName name:String, completion: @escaping (VPLastFMTag?)->()){
		let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Tag.getInfo.rawValue)
		let tagQuery = URLQueryItem(name: "tag", value: name)
		guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,tagQuery) else {completion(nil); return}
		
		URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
			do{
				guard let data = data else {throw LastFMTagError.parse}
				guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] else {throw LastFMTagError.parse}
				guard let tag = json["tag"] as? [String:AnyObject] else {throw LastFMTagError.parse}
				let decoder = JSONDecoder()
				decoder.dateDecodingStrategy = .iso8601
				let tagJSON = try JSONSerialization.data(withJSONObject: tag, options: [])
				let result = try decoder.decode(VPLastFMTag.self, from: tagJSON)
				completion(result)
			} catch _{
				completion(nil)
			}
		}).resume()
	}
	
	public func getSimilar(completion:@escaping ([VPLastFMTag])->()) {
		let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Tag.getSimilar.rawValue)
		let tagQuery = URLQueryItem(name: "tag", value: self.name)
		guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,tagQuery) else {completion([]); return}
		var results:[VPLastFMTag] = []
		
		URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
			do{
				guard let data = data else {throw LastFMTagError.parse}
				guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] else {throw LastFMTagError.parse}
				guard let similarTracks = json["similartags"] as? [String:AnyObject] else {throw LastFMTagError.parse}
				guard let tags = similarTracks["tag"] as? [[String:AnyObject]] else {throw LastFMTagError.parse}
				for tag in tags{
					let tagJSON = try JSONSerialization.data(withJSONObject: tag, options: [])
					results.append(try JSONDecoder().decode(VPLastFMTag.self, from: tagJSON))
				}
				completion(results)
			} catch _{
				completion([])
			}
		}).resume()
	}
	
	public func getTopAlbums(completion:@escaping ([VPLastFMAlbum])->()) {
		let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Tag.getTopAlbums.rawValue)
		let tagQuery = URLQueryItem(name: "tag", value: self.name)
		var results:[VPLastFMAlbum] = []
		guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,tagQuery) else {completion([]); return}
		
		URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
			do{
				guard let data = data else {throw LastFMTagError.parse}
				guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] else {throw LastFMTagError.parse}
				guard let topAlbums = json["albums"] as? [String:AnyObject] else {throw LastFMTagError.parse}
				guard let albums = topAlbums["album"] as? [[String:AnyObject]] else {throw LastFMTagError.parse}
				for album in albums{
					let albumJSON = try JSONSerialization.data(withJSONObject: album, options: [])
					results.append(try JSONDecoder().decode(VPLastFMAlbum.self, from: albumJSON))
				}
				completion(results)
			} catch _{
				completion([])
			}
		}).resume()
	}
	
	public func getTopArtists(limit:Int = 50, completion:@escaping ([VPLastFMArtist])->()) {
		let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Tag.getTopArtists.rawValue)
		let tagQuery = URLQueryItem(name: "tag", value: self.name)
		var results:[VPLastFMArtist] = []
		guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,tagQuery) else {completion([]); return}
		
		URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
			do{
				guard let data = data else {throw LastFMTagError.parse}
				guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] else {throw LastFMTagError.parse}
				guard let topArtists = json["topartists"] as? [String:AnyObject] else {throw LastFMTagError.parse}
				guard let artists = topArtists["artist"] as? [[String:AnyObject]] else {throw LastFMTagError.parse}
				for (index,artist) in artists.enumerated(){
					if index > limit {break}
					let artistJSON = try JSONSerialization.data(withJSONObject: artist, options: [])
					results.append(try JSONDecoder().decode(VPLastFMArtist.self, from: artistJSON))
				}
				completion(results)
			} catch _{
				completion([])
			}
		}).resume()
	}
	
	public func getTopTracks(limit:Int = 50, completion:@escaping ([VPLastFMTrack])->()) {
		let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Tag.getTopTracks.rawValue)
		let tagQuery = URLQueryItem(name: "tag", value: self.name)
		let limitQuery = URLQueryItem(name: "limit", value: String(limit))
		var results:[VPLastFMTrack] = []
		guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,tagQuery,limitQuery) else {completion([]); return}
		
		URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
			do{
				guard let data = data else {throw LastFMTagError.parse}
				guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] else {throw LastFMTagError.parse}
				guard let topTracks = json["tracks"] as? [String:AnyObject] else {throw LastFMTagError.parse}
				guard let tracks = topTracks["track"] as? [[String:AnyObject]] else {throw LastFMTagError.parse}
				for track in tracks{
					let trackJSON = try JSONSerialization.data(withJSONObject: track, options: [])
					results.append(try JSONDecoder().decode(VPLastFMTrack.self, from: trackJSON))
				}
				completion(results)
			} catch _{
				completion([])
			}
		}).resume()
	}
	
	public static func getTopTags(completion:@escaping ([VPLastFMTag])->()) {
		let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Tag.getTopTags.rawValue)
		var results:[VPLastFMTag] = []
		guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery) else {completion([]); return}
		
		URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
			do{
				guard let data = data else {throw LastFMTagError.parse}
				guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] else {throw LastFMTagError.parse}
				guard let topTags = json["toptags"] as? [String:AnyObject] else {throw LastFMTagError.parse}
				guard let tags = topTags["tag"] as? [[String:AnyObject]] else {throw LastFMTagError.parse}
				for tag in tags{
					let tagJSON = try JSONSerialization.data(withJSONObject: tag, options: [])
					results.append(try JSONDecoder().decode(VPLastFMTag.self, from: tagJSON))
				}
				completion(results)
			} catch _{
				completion([])
			}
		}).resume()
	}
	
}
