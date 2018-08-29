//
//  LastFMLoginManager.swift
//  lastfm
//
//  Created by Vitaly Plivachuk on 12/13/17.
//  Copyright © 2017 Vitaly Plivachuk. All rights reserved.
//

import Foundation

public class VPLastFMLoginManager {
	
	public static var user: VPLastFMUser?{
		didSet{
			NotificationCenter.default.post(name: .userLoginInfoChanged, object: nil)
		}
	}
    
    static var authData: (username:String,key:String)?{
        set{
            UserDefaults.standard.set(newValue?.username, forKey: "Last.fm Username")
            UserDefaults.standard.set(newValue?.key, forKey: "Last.fm Key")
        }
        get{
            guard let username = UserDefaults.standard.string(forKey: "Last.fm Username") else {return nil}
            guard let key = UserDefaults.standard.string(forKey: "Last.fm Key") else {return nil}
            return (username,key)
        }
    }
	
	enum LastFMLoginManagerError: Error {
		case loginError
	}
    
    public static func auth(username:String, password:String, completion: @escaping ((username:String,key:String)?)->()) {
        
        let apiSigComponents = [
            "method" : VPLastFMAPIClient.APIMethods.Auth.getMobileSession.rawValue,
            "password" : password,
            "username" : username
        ]
        let apiSig = try! VPLastFMAPIClient.shared.createApiSigString(with: apiSigComponents)
        
        let methodQuery = URLQueryItem(name: "method", value: VPLastFMAPIClient.APIMethods.Auth.getMobileSession.rawValue)
        let usernameQuery = URLQueryItem(name: "username", value: username)
        let passwordQuery = URLQueryItem(name: "password", value: password)
        let apiSigQuery = URLQueryItem(name: "api_sig", value: apiSig)
		
		guard let url = try? VPLastFMAPIClient.shared.createURL(with: methodQuery, usernameQuery, passwordQuery, apiSigQuery) else {completion(nil);return}
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            do{
				guard error == nil else {throw error!}
                guard let data = data else {throw LastFMLoginManagerError.loginError}
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] else {throw LastFMLoginManagerError.loginError}
                guard let session = json["session"] as? [String:AnyObject] else {throw LastFMLoginManagerError.loginError}
                guard let key = session["key"] as? String else {throw LastFMLoginManagerError.loginError}
                guard let name = session["name"] as? String else {throw LastFMLoginManagerError.loginError}
                completion((name, key))
            } catch let error {
                print(error.localizedDescription)
                completion(nil)
            }
            }.resume()
    }
}

extension Notification.Name{
	public static let userLoginInfoChanged = Notification.Name("userLoginInfoChanged")
}
