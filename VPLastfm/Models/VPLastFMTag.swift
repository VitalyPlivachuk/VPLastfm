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
    
    public static func getTag(byName name:String, completion: @escaping (VPLastFMTag?, Error?)->()){
        let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Tag.getInfo.rawValue)
        let tagQuery = URLQueryItem(name: "tag", value: name)
        do{
            let url = try VPLastFMAPIClient.shared.createURL(with: methodQuery,tagQuery)
            VPLastFMAPIClient.shared.getModel(VPLastFMTag.self, url: url, path: ["tag"], arrayName: nil) { result, error  in
                completion(result, error)
            }
        } catch let error{
            completion(nil,error)
        }
    }
    
    public func getSimilar(completion:@escaping ([VPLastFMTag]?, Error?)->()) {
        let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Tag.getSimilar.rawValue)
        let tagQuery = URLQueryItem(name: "tag", value: self.name)
        do{
            let url = try VPLastFMAPIClient.shared.createURL(with: methodQuery,tagQuery)
            VPLastFMAPIClient.shared.getModel([VPLastFMTag].self, url: url, path: ["similartags"], arrayName: "tag") { result, error  in
                completion(result, error)
            }
        } catch let error{
            completion(nil,error)
        }
    }
    
    public func getTopAlbums(completion:@escaping ([VPLastFMAlbum]?,Error?)->()) {
        let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Tag.getTopAlbums.rawValue)
        let tagQuery = URLQueryItem(name: "tag", value: self.name)
        do{
            let url = try VPLastFMAPIClient.shared.createURL(with: methodQuery,tagQuery)
            VPLastFMAPIClient.shared.getModel([VPLastFMAlbum].self, url: url, path: ["albums"], arrayName: "album") { result, error  in
                completion(result, error)
            }
        } catch let error{
            completion(nil,error)
        }
    }
    
    public func getTopArtists(limit:Int = 50, completion:@escaping ([VPLastFMArtist]?,Error?)->()) {
        let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Tag.getTopArtists.rawValue)
        let tagQuery = URLQueryItem(name: "tag", value: self.name)
        do{
            let url = try VPLastFMAPIClient.shared.createURL(with: methodQuery,tagQuery)
            VPLastFMAPIClient.shared.getModel([VPLastFMArtist].self, url: url, path: ["topartists"], arrayName: "artist") { result, error  in
                completion(result, error)
            }
        } catch let error{
            completion(nil,error)
        }
    }
    
    public func getTopTracks(limit:Int = 50, completion:@escaping ([VPLastFMTrack]?,Error?)->()) {
        let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Tag.getTopTracks.rawValue)
        let tagQuery = URLQueryItem(name: "tag", value: self.name)
        let limitQuery = URLQueryItem(name: "limit", value: String(limit))
        do{
            let url = try VPLastFMAPIClient.shared.createURL(with: methodQuery,tagQuery,limitQuery)
            VPLastFMAPIClient.shared.getModel([VPLastFMTrack].self, url: url, path: ["tracks"], arrayName: "track") { result, error  in
                completion(result, error)
            }
        } catch let error{
            completion(nil,error)
        }
    }
    
    public static func getTopTags(completion:@escaping ([VPLastFMTag]?,Error?)->()) {
        let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Tag.getTopTags.rawValue)
        do{
            let url = try VPLastFMAPIClient.shared.createURL(with: methodQuery)
            VPLastFMAPIClient.shared.getModel([VPLastFMTag].self, url: url, path: ["toptags"], arrayName: "tag") { result, error  in
                completion(result, error)
            }
        } catch let error{
            completion(nil,error)
        }
    }
    
}
