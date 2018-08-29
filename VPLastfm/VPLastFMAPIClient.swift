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
    
    public enum VPLastFMAPIClientError:Error, LocalizedError {
        case parse
        case urlCreation
        case apiKey
        case sharedSecret
        
        public var errorDescription: String?{
            switch self {
            case .parse:
                return "JSON Parsing error"
            case .urlCreation:
                return "URL creating error"
            case .apiKey:
                return "Need to set API key"
            case .sharedSecret:
                return "Need to set shared secret"
            }
        }
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
	
    func createURL(with queryItems:URLQueryItem?...) throws ->(URL) {
        guard let apiKey = apiKey else {throw VPLastFMAPIClientError.apiKey}
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
        guard let url = urlComponents.url else {throw VPLastFMAPIClientError.urlCreation}
        return url
	}
	
    func createApiSigString(with components:[String:String?]) throws ->(String){
        guard let apiKey = apiKey else {throw VPLastFMAPIClientError.apiKey}
        guard let sharedSecret = sharedSecret else {throw VPLastFMAPIClientError.sharedSecret}
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
    
    func getModel<T:Decodable>(_ t:T.Type, url:URL, path:[String]?, arrayName:String?, completion:@escaping (T?, Error?)->()) {
        URLSession.shared.dataTask(with: url, completionHandler: {(data, response, error) in
            do{
                guard let data = data else {throw VPLastFMAPIClientError.parse}
                guard var json = try! JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] else {throw VPLastFMAPIClientError.parse}
                
                if let errorCode = json["error"] as? Int{
                    let error: Error = LastFMError(rawValue: errorCode) ?? VPLastFMAPIClientError.parse
                    throw error
                }
                
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
                completion(result, nil)
            } catch let error{
                completion(nil, error)
            }
        }).resume()
    }
}

enum LastFMError: Int, Error, LocalizedError{
    case notExist = 1
    case invalidService
    case invalidMethod
    case authenticationFailed
    case invalidFormat
    case invalidParameters
    case invalidResourceSpecified
    case operationFailed
    case invalidSessionKey
    case invalidApiKey
    case serviceOffline
    case subscribersOnly
    case invalidMethodSignatureSupplied
    case unauthorizedToken
    case thisItemIsNotAvailableForStreaming
    case theServiceIsTemporarilyUnavailable
    case userRequiresToBeLoggedIn
    case trialExpired
    case thisErrorDoesNotExist
    case notEnoughContent
    case notEnoughMembers
    case notEnoughFans
    case notEnoughNeighbours
    case noPeakRadio
    case radioNotFound
    case apiKeySuspended
    case deprecated
    case rateLimitExceded
    
    var errorDescription: String? {
        return LastFMErrorDescription[self.rawValue] ?? "Unknown"
    }
}

let LastFMErrorDescription: [Int:String] = [
    1 : "This error does not exist",
    2 : "Invalid service -This service does not exist",
    3 : "Invalid Method - No method with that name in this package",
    4 : "Authentication Failed - You do not have permissions to access the service",
    5 : "Invalid format - This service doesn't exist in that format",
    6 : "Invalid parameters - Your request is missing a required parameter",
    7 : "Invalid resource specified",
    8 : "Operation failed - Most likely the backend service failed. Please try again.",
    9 : "Invalid session key - Please re-authenticate",
    10 : "Invalid API key - You must be granted a valid key by last.fm",
    11 : "Service Offline - This service is temporarily offline. Try again later.",
    12 : "Subscribers Only - This station is only available to paid last.fm subscribers",
    13 : "Invalid method signature supplied",
    14 : "Unauthorized Token - This token has not been authorized",
    15 : "This item is not available for streaming.",
    16 : "The service is temporarily unavailable, please try again.",
    17 : "Login: User requires to be logged in",
    18 : "Trial Expired - This user has no free radio plays left. Subscription required.",
    19 : "This error does not exist",
    20 : "Not Enough Content - There is not enough content to play this station",
    21 : "Not Enough Members - This group does not have enough members for radio",
    22 : "Not Enough Fans - This artist does not have enough fans for for radio",
    23 : "Not Enough Neighbours - There are not enough neighbours for radio",
    24 : "No Peak Radio - This user is not allowed to listen to radio during peak usage",
    25 : "Radio Not Found - Radio station not found",
    26 : "API Key Suspended - This application is not allowed to make requests to the web services",
    27 : "Deprecated - This type of request is no longer supported",
    29 : "Rate Limit Exceded - Your IP has made too many requests in a short period, exceeding our API guidelines"
]
