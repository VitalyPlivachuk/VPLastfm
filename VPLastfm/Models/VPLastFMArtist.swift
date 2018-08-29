//
//  LastFMArtist.swift
//  lastfm
//
//  Created by Vitaly Plivachuk on 11/29/17.
//  Copyright © 2017 Vitaly Plivachuk. All rights reserved.
//

import Foundation

final public class VPLastFMArtist: Codable,VPLastFMModel {

    public let name: String
    public let mbid: String?
	public let url: URL?
    public let image: VPLastFMImage?
	public let stats: Stats?
	public let tags: [VPLastFMTag]?
	public let bio: Bio?
	public var similar: [VPLastFMArtist]?
	private let text: String?
	
	
	public struct Stats: Codable {
		let listeners: String?
		let playcount: String?
	}
	
	public struct Bio: Codable {
		init(summary:String, content:String) {
			self.summary = summary
			self.content = content
		}
		let summary: String
		let content: String
	}
	
    
	public init (name: String,mbid: String?,url: URL?,image: VPLastFMImage?, stats: Stats?,tags: [VPLastFMTag]?,bio: Bio?,similar:[VPLastFMArtist]?){
        self.name = name
        self.mbid = mbid
        self.url = url
        self.image = image
        self.stats = stats
        self.tags = tags
        self.bio = bio
		self.text = nil
		self.similar = similar
    }
    
    convenience public init(from decoder: Decoder) throws{
        let container = try decoder.container(keyedBy: CodingKeys.self)
		
		let name: String
		do {
			name = try container.decode(String.self, forKey: .name)
		} catch _ {
			name = try container.decode(String.self, forKey: .text)
//			print(error.localizedDescription)
		}
		
		let similar: [VPLastFMArtist]?
		do {
			let artistsContainer = try container.nestedContainer(keyedBy: ArtistArrayCodingKeys.self, forKey: .similar)
			similar = try artistsContainer.decodeIfPresent([VPLastFMArtist].self, forKey: .artist)
		} catch {
			similar = nil
		}
		
		let tags: [VPLastFMTag]?
		do {
			let tagsContainer = try container.nestedContainer(keyedBy: VPLastFMTag.TagsArrayCodingKeys.self, forKey: .tags)
			tags = try tagsContainer.decodeIfPresent([VPLastFMTag].self, forKey: .tag)
		} catch {
			tags = nil
		}
		
		
        let mbid: String? = try container.decodeIfPresent(String.self, forKey: .mbid)
        let url: URL? = try container.decodeIfPresent(URL.self, forKey: .url)
		var image: VPLastFMImage? = try container.decodeIfPresent(VPLastFMImage.self, forKey: .image)
		if image?.small == nil && image?.medium == nil && image?.large == nil && image?.extraLarge == nil {
			image = nil
		}
        let stats = try container.decodeIfPresent(Stats.self, forKey: .stats)
		
		
		var bio = try container.decodeIfPresent(Bio.self, forKey: .bio)
		
		if let _bio = bio{
			var content = _bio.content
			if let end = content.range(of: "<a href=") {
				content = String(content[..<end.lowerBound])
			}
			if !content.isEmpty && content != " "{
				
				let summary = content.count > 300 ? String(content[..<String.Index.init(encodedOffset: 299)]) : content
				bio = Bio(summary: summary, content: content)
			} else {
				bio = nil
			}
			
		}
		
		
        self.init(name: name,
                  mbid: mbid,
                  url: url,
                  image: image,
                  stats: stats,
                  tags: tags,
                  bio: bio,
				  similar: similar)
    }
	
	enum CodingKeys: String, CodingKey {
		case name
		case mbid
		case url
		case image
		case stats
		case tags
		case bio
		case text = "#text"
		case similar
	}
	
	public enum LastFMArtistError: Error {
		case parse
		case url
	}
	
	enum ArtistArrayCodingKeys: String, CodingKey {
		case artist
	}
	
	public static func getCorrection(for name: String, completion:@escaping (String?)->()){
		let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Artist.getCorrection.rawValue)
		let artistQuery = URLQueryItem(name: "artist", value: name)
		guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,artistQuery) else {completion(nil); return}
		
		URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
			do{
				guard let data = data else {throw LastFMArtistError.parse}
				guard let json = try! JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] else {throw LastFMArtistError.parse}
				guard let corrections = json["corrections"] as? [String:AnyObject] else {throw LastFMArtistError.parse}
				guard let correction = corrections["correction"] as? [String:AnyObject] else {throw LastFMArtistError.parse}
				guard let artist = correction["artist"] as? [String:AnyObject] else {throw LastFMArtistError.parse}
				guard let name = artist["name"] as? String else {throw LastFMArtistError.parse}
				completion(name)
			} catch _{
				completion(nil)
			}
		}).resume()
		
	}
	
	public static func getArtist(byName name:String, completion: @escaping (VPLastFMArtist?)->()){
		let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Artist.getInfo.rawValue)
		let artistQuery = URLQueryItem(name: "artist", value: name)
		guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,artistQuery) else {completion(nil); return}
        
        VPLastFMAPIClient.shared.getModel(VPLastFMArtist.self, url: url, path: ["artist"], arrayName: nil) { result in
            completion(result)
        }
	}
	
    public func getSimilar(limit:Int, completion:@escaping ([VPLastFMArtist])->()) {
		let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Artist.getSimilar.rawValue)
		let limitQuery = URLQueryItem(name: "limit", value: String(limit))
		let artistQuery = URLQueryItem(name: "artist", value: self.name)
		
		guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,limitQuery,artistQuery) else {completion([]); return}
        
        VPLastFMAPIClient.shared.getModel([VPLastFMArtist].self, url: url, path: ["similarartists"], arrayName: "artist") { result in
            completion(result ?? [])
        }
	}
	
	public func getTopAlbums(completion:@escaping ([VPLastFMAlbum])->()) {
		let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Artist.getTopAlbums.rawValue)
		let artistQuery = URLQueryItem(name: "artist", value: self.name)
		guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,artistQuery) else {completion([]); return}
        
        VPLastFMAPIClient.shared.getModel([VPLastFMAlbum].self, url: url, path: ["topalbums"], arrayName: "album") { result in
            completion(result ?? [])
        }
	}
	
	
	public func getTopTags(limit:Int = 10, completion:@escaping ([VPLastFMTag])->()) {
		let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Artist.getTopTags.rawValue)
		let artistQuery = URLQueryItem(name: "artist", value: self.name)
		guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,artistQuery) else {completion([]); return}
        
        VPLastFMAPIClient.shared.getModel([VPLastFMTag].self, url: url, path: ["toptags"], arrayName: "tag") { result in
            completion(result ?? [])
        }
	}
	
	public func getTopTracks(limit:Int = 50, completion:@escaping ([VPLastFMTrack])->()) {
		let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Artist.getTopTracks.rawValue)
		let artistQuery = URLQueryItem(name: "artist", value: self.name)
		let limitQuery = URLQueryItem(name: "limit", value: String(limit))
        
		guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,artistQuery,limitQuery) else {completion([]);return}
        
        VPLastFMAPIClient.shared.getModel([VPLastFMTrack].self, url: url, path: ["toptracks"], arrayName: "track") { result in
            completion(result ?? [])
        }
	}
	
	public func getSimilarByTags(limit:Int, completion:@escaping ([VPLastFMArtist])->()){
		self.getTopTags(limit: 1) { tags in
			let dispatchGroup = DispatchGroup()
			var result:[VPLastFMArtist] = []
			for tag in tags {
				dispatchGroup.enter()
				tag.getTopArtists(limit: Int(limit/tags.count-1), completion: { (artistsByTag) in
					result.append(contentsOf: artistsByTag)
					dispatchGroup.leave()
				})
			}
			dispatchGroup.notify(queue: .main) {[weak self] in
				let filteredResult = result.filter{$0 != self}
				completion(filteredResult)
			}
		}
	}
	
	public static func getTop(limit:Int = 50, completion: @escaping ([VPLastFMArtist])->()) {
		let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Chart.getTopArtists.rawValue)
		let limitQuery = URLQueryItem(name: "limit", value: String(limit))
		guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,limitQuery) else {completion([]); return}
        
        VPLastFMAPIClient.shared.getModel([VPLastFMArtist].self, url: url, path: ["artists"], arrayName: "artist") { result in
            completion(result ?? [])
        }
	}
	
	public static func search(artists name:String, completion: @escaping ([VPLastFMArtist])->()) {
		let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Artist.search.rawValue)
		let trackQuery = URLQueryItem(name: "artist", value: name)
		
		guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,trackQuery) else {completion([]); return}
        
        VPLastFMAPIClient.shared.getModel([VPLastFMArtist].self, url: url, path: ["results","artistmatches"], arrayName: "artist") { result in
            completion(result ?? [])
        }
	}
}

extension VPLastFMArtist: Equatable{
    public static func ==(lhs: VPLastFMArtist, rhs: VPLastFMArtist) -> Bool {
		return (lhs.name == rhs.name)
	}
}
