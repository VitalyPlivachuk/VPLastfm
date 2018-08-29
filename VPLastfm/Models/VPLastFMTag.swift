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
		
        VPLastFMAPIClient.shared.getModel(VPLastFMTag.self, url: url, path: ["tag"], arrayName: nil) { result in
            completion(result)
        }
	}
	
	public func getSimilar(completion:@escaping ([VPLastFMTag])->()) {
		let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Tag.getSimilar.rawValue)
		let tagQuery = URLQueryItem(name: "tag", value: self.name)
		guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,tagQuery) else {completion([]); return}
		
        VPLastFMAPIClient.shared.getModel([VPLastFMTag].self, url: url, path: ["similartags"], arrayName: "tag") { result in
            completion(result ?? [])
        }
	}
	
	public func getTopAlbums(completion:@escaping ([VPLastFMAlbum])->()) {
		let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Tag.getTopAlbums.rawValue)
		let tagQuery = URLQueryItem(name: "tag", value: self.name)
		guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,tagQuery) else {completion([]); return}
		
        VPLastFMAPIClient.shared.getModel([VPLastFMAlbum].self, url: url, path: ["albums"], arrayName: "album") { result in
            completion(result ?? [])
        }
	}
	
	public func getTopArtists(limit:Int = 50, completion:@escaping ([VPLastFMArtist])->()) {
		let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Tag.getTopArtists.rawValue)
		let tagQuery = URLQueryItem(name: "tag", value: self.name)
		guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,tagQuery) else {completion([]); return}
        
        VPLastFMAPIClient.shared.getModel([VPLastFMArtist].self, url: url, path: ["topartists"], arrayName: "artist") { result in
            completion(result ?? [])
        }
	}
	
	public func getTopTracks(limit:Int = 50, completion:@escaping ([VPLastFMTrack])->()) {
		let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Tag.getTopTracks.rawValue)
		let tagQuery = URLQueryItem(name: "tag", value: self.name)
		let limitQuery = URLQueryItem(name: "limit", value: String(limit))
		guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,tagQuery,limitQuery) else {completion([]); return}
		
        VPLastFMAPIClient.shared.getModel([VPLastFMTrack].self, url: url, path: ["tracks"], arrayName: "track") { result in
            completion(result ?? [])
        }
	}
	
	public static func getTopTags(completion:@escaping ([VPLastFMTag])->()) {
		let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Tag.getTopTags.rawValue)
		guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery) else {completion([]); return}
        
        VPLastFMAPIClient.shared.getModel([VPLastFMTag].self, url: url, path: ["toptags"], arrayName: "tag") { result in
            completion(result ?? [])
        }
	}
	
}
