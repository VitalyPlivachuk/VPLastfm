//
//  LastFMModel.swift
//  lastfm
//
//  Created by Vitaly Plivachuk on 12/25/17.
//  Copyright © 2017 Vitaly Plivachuk. All rights reserved.
//

import Foundation

public protocol VPLastFMModel {
    var image: VPLastFMImage? {get}
    var mbid: String? {get}
    var name: String {get}
}

public class VPLastFMImage: Codable {
    
    public init(small:URL?,medium:URL?,large:URL?,extraLarge:URL?) {
        self.small = small
        self.medium = medium
        self.large = large
        self.extraLarge = extraLarge
    }
    
    convenience required public init(from decoder: Decoder) throws{
        var container = try decoder.unkeyedContainer()
        
        var small:URL?
        var medium:URL?
        var large:URL?
        var extraLarge:URL?
        
        while (!container.isAtEnd) {
            if let img = try container.decodeIfPresent([String:String].self){
                guard let urlString = img["#text"] else {continue}
                guard let sizeString = img["size"] else {continue}
                guard let url = URL(string: urlString) else {continue}
                
                switch sizeString {
                case "small":
                    small = url
                    medium = url
                    large = url
                    extraLarge = url
                case "medium":
                    medium = url
                    large = url
                    extraLarge = url
                case "large":
                    large = url
                    extraLarge = url
                case "extralarge":
                    extraLarge = url
                default:break
                }
            }
        }
        self.init(small: small, medium: medium, large: large, extraLarge: extraLarge)
    }
    
    public let small:URL?
    public let medium:URL?
    public let large:URL?
    public let extraLarge:URL?
    
    public init() {
        self.small = nil//URL(string:"https://source.unsplash.com/random/750x750/?music")
        self.medium = nil//URL(string:"https://source.unsplash.com/random/750x750/?music")
        self.large = nil//URL(string:"https://source.unsplash.com/random/750x750/?music")
        self.extraLarge = nil//URL(string:"https://source.unsplash.com/random/750x750/?music")
    }
    
    public static func getImageURL<U:VPLastFMModel>(lastFMModel:U?) -> VPLastFMImage {
        if let track = lastFMModel as? VPLastFMTrack{
            if let albumCover = track.album?.image {
                return albumCover
            } else if let trackCover = track.image {
                return trackCover
            } else if let artistCover = track.artist.image{
                return artistCover
            } else {
                return VPLastFMImage()
            }
            
        } else if let artist = lastFMModel as? VPLastFMArtist{
            if let artistCover = artist.image{
                return artistCover
            } else {
                return VPLastFMImage()
            }
        } else if let album = lastFMModel as? VPLastFMAlbum{
            if let albumCover = album.image{
                return albumCover
            } else {
                return VPLastFMImage()
            }
        } else {
            return VPLastFMImage()
        }
    }
}
