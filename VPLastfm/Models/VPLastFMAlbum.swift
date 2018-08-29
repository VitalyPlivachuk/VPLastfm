//
//  LastFMAlbum.swift
//  lastfm
//
//  Created by Vitaly Plivachuk on 11/29/17.
//  Copyright © 2017 Vitaly Plivachuk. All rights reserved.
//

import Foundation

final public class VPLastFMAlbum: Codable, VPLastFMModel {

    public let name: String
    public let mbid: String?
	public let url: URL?
    public let image: VPLastFMImage?
	public let artist: VPLastFMArtist?
	public let tracks: [VPLastFMTrack]?
	public let tags: Tags?
	public let wiki: Bio?
	private let text: String?
	private let title: String?
	
	public init (name: String,mbid: String?,url: URL?,image: VPLastFMImage?,artist: VPLastFMArtist?,tracks: [VPLastFMTrack]?,tags: Tags?,wiki: Bio?){
		self.name = name
		self.mbid = mbid
		self.url = url
		self.image = image
		self.artist = artist
		self.tracks = tracks
		self.tags = tags
		self.wiki = wiki
		self.text = nil
		self.title = nil
	}
	
    convenience public init(from decoder: Decoder) throws{
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		let name: String
		do {
			name = try container.decode(String.self, forKey: .name)
		} catch _ {
			do {
				name = try container.decode(String.self, forKey: .text)
			} catch let error {
				print(error.localizedDescription)
				name = try container.decode(String.self, forKey: .title)
			}
			
		}
		
		let mbid: String? = try container.decodeIfPresent(String.self, forKey: .mbid)
		let url: URL? = try container.decodeIfPresent(URL.self, forKey: .url)
		var image: VPLastFMImage? = try container.decodeIfPresent(VPLastFMImage.self, forKey: .image)
		if image?.small == nil && image?.medium == nil && image?.large == nil && image?.extraLarge == nil {
			image = nil
		}
//		let tracks = try container.decodeIfPresent(Track.self, forKey: .tracks)
		
		let tracks: [VPLastFMTrack]?
		
		do {
			let tracksContainer = try container.nestedContainer(keyedBy: TrackArrayCodingKeys.self, forKey: .tracks)
			tracks = try tracksContainer.decodeIfPresent([VPLastFMTrack].self, forKey: .track)
		} catch {
			tracks = nil
		}
		
		
		let artist: VPLastFMArtist?
		do {
			artist = try container.decode(VPLastFMArtist.self, forKey: .artist)
		} catch {
			if let _artist = tracks?[safe:0]?.artist {
				artist = _artist
			} else {
				if let _artist = try container.decodeIfPresent(String.self, forKey: .artist){
					artist = VPLastFMArtist(name: _artist,
										  mbid: nil,
										  url: nil,
										  image: nil,
										  stats: nil,
										  tags: nil,
										  bio: nil,
										  similar: nil)
				} else {
					artist = nil
				}
			}
		}
		let tags = try container.decodeIfPresent(Tags.self, forKey: .tags)
		let wiki = try container.decodeIfPresent(Bio.self, forKey: .wiki)
		self.init(name: name,
				  mbid: mbid,
				  url: url,
				  image: image,
				  artist: artist,
				  tracks: tracks,
				  tags: tags,
				  wiki: wiki)
	}
	
	public struct Tags: Codable {
		let tag: [VPLastFMTag]
	}
	
	public enum LastFMAlbumError: Error {
		case parse
		case url
	}
	
	public struct Bio: Codable {
		let summary: String?
		let content: String?
	}
	
	enum CodingKeys: String, CodingKey {
		case text = "#text"
		case name
		case mbid
		case url
		case image
		case artist
		case tracks
		case tags
		case wiki
		case title
	}
	
	public static func getAlbum(byName name:String, artist:String, completion: @escaping (VPLastFMAlbum?)->()){
		let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Album.getInfo.rawValue)
		let albumQuery = URLQueryItem(name: "album", value: name)
		let artistQuery = URLQueryItem(name: "artist", value: artist)
		
		guard let url = VPLastFMAPIClient.shared.createURL(with: methodQuery,albumQuery,artistQuery) else {completion(nil); return}
        
        VPLastFMAPIClient.shared.getModel(VPLastFMAlbum.self, url: url, path: ["album"], arrayName: nil) { result in
            completion(result)
        }
	}
	
	public func fillInfo(completion:@escaping (VPLastFMAlbum?)->()) {
		VPLastFMAlbum.getAlbum(byName: self.name, artist: (self.artist?.name)!) {album in
			album?.tracks?.forEach{$0.album = self}
			completion(album)
		}
	}
}

extension VPLastFMAlbum: Equatable{
    public static func ==(lhs: VPLastFMAlbum, rhs: VPLastFMAlbum) -> Bool {
		return lhs.name == rhs.name
	}
}

