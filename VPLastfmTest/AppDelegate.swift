//
//  AppDelegate.swift
//  VPLastfmTest
//
//  Created by Vitaly Plivachuk on 8/28/18.
//  Copyright © 2018 Vitaly Plivachuk. All rights reserved.
//

import UIKit
import VPLastfm

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        VPLastFMAPIClient.shared.setUp(withApiKey: nil,
                                       sharedSecret: nil) //Need to set your Last.fm API key
        apiTest()
        return true
    }
    
    func apiTest(){
        VPLastFMTrack.getTrack(byName: "One", artist: "Metallica") { track in
            print("\n*******VPLastFMTrack.getTrack*********")
            print("\(track!.artist.name) - \(track!.name)")
            
            track?.getSimilar(limit: 5, completion: { tracks in
                print("\n*******VPLastFMTrack.getSimilar*********")
                tracks.forEach{
                    print("\($0.artist.name) - \($0.name)")
                }
            })
            
            track?.getTopTags(limit: 5, completion: { tags in
                print("\n*******VPLastFMTrack.getTopTags*********")
                tags.forEach{
                    print("\($0.name)")
                }
            })
        }
        
        VPLastFMTrack.getTop(limit: 15) {tracks in
            print("\n*******VPLastFMTrack.getTop*********")
            tracks.forEach{
                print("\($0.artist.name) - \($0.name)")
            }
        }
        
        VPLastFMTrack.search(name: "Nin", artist: nil) { tracks in
            print("\n*******VPLastFMTrack.Search*********")
            tracks.forEach{
                print("\($0.artist.name) - \($0.name)")
            }
        }
        
        VPLastFMUser.getUser(byName: "vetal_floyd") { user in
            print("\n*******VPLastFMUser.getUser*********")
            print(user!.name)
            
            user?.getArtistTracks(artist: "metallica", completion: { tracks in
                print("\n*******VPLastFMUser.getArtistTracks*********")
                tracks.forEach{
                    print("\($0.artist.name) - \($0.name)")
                }
            })
            
            user?.getLovedTracks(completion: {tracks in
                print("\n*******VPLastFMUser.getLovedTracks*********")
                tracks.forEach{
                    print("\($0.artist.name) - \($0.name)")
                }
            })
            
            user?.getRecentTracks(from: Date.init(timeIntervalSince1970: 3333), to: Date(), completion: { tracks in
                print("\n*******VPLastFMUser.getRecentTracks*********")
                tracks.forEach{
                    print("\($0.artist.name) - \($0.name)")
                }
            })
            
            user?.getTopAlbums(completion: { albums in
                print("\n*******VPLastFMUser.getTopAlbums*********")
                albums.forEach{
                    print("\($0.artist?.name) - \($0.name)")
                }
            })
            
            user?.getTopArtists(completion: { artists in
                print("\n*******VPLastFMUser.getTopArtists*********")
                artists.forEach{
                    print("\($0.name)")
                }
            })
            
            user?.getTopTracks(completion: { tracks in
                print("\n*******VPLastFMUser.getTopTracks*********")
                tracks.forEach{
                    print("\($0.artist.name) - \($0.name)")
                }
            })
            
        }
        
        VPLastFMTag.getTag(byName: "rock") { tag in
            print("\n*******VPLastFMTag.getTag*********")
            print(tag!.name)
            
            tag?.getSimilar(completion: { tags in
                print("\n*******VPLastFMTag.getSimilar*********")
                tags.forEach{
                    print("\($0.name)")
                }
            })
            
            tag?.getTopAlbums(completion: { albums in
                print("\n*******VPLastFMTag.getTopAlbums*********")
                albums.forEach{
                    print("\($0.artist?.name) - \($0.name)")
                }
            })
            
            tag?.getTopArtists(limit: 5, completion: { artists in
                print("\n*******VPLastFMTag.getTopArtists*********")
                artists.forEach{
                    print("\($0.name)")
                }
            })
            
            tag?.getTopTracks(limit: 5, completion: { tracks in
                print("\n*******VPLastFMTag.getTopTracks*********")
                tracks.forEach{
                    print("\($0.artist.name) - \($0.name)")
                }
            })
        }
        VPLastFMTag.getTopTags(completion: { tags in
            print("\n*******VPLastFMTag.getTopTags*********")
            tags.forEach{
                print("\($0.name)")
            }
        })
        
        VPLastFMArtist.getArtist(byName: "Metallica") { artist in
            print("\n*******VPLastFMArtist.getArtist*********")
            print("\(artist!.name)")
            
            artist?.getSimilar(limit: 5, completion: { artists in
                print("\n*******VPLastFMArtist.getSimilar*********")
                artists.forEach{
                    print("\($0.name)")
                }
            })
            
            artist?.getTopAlbums(completion: { albums in
                print("\n*******VPLastFMArtist.getTopAlbums*********")
                albums.forEach{
                    print("\($0.artist?.name) - \($0.name)")
                }
            })
            
            artist?.getTopTags(completion: { tags in
                print("\n*******VPLastFMArtist.getTopTags*********")
                tags.forEach{
                    print("\($0.name)")
                }
            })
            
            artist?.getTopTracks(limit: 5, completion: { tracks in
                print("\n*******VPLastFMArtist.getTopTracks*********")
                tracks.forEach{
                    print("\($0.artist.name) - \($0.name)")
                }
            })
        }
        
        VPLastFMArtist.getTop(limit: 5) { artists in
            print("\n*******VPLastFMArtist.getTop*********")
            artists.forEach{
                print("\($0.name)")
            }
        }
        
        VPLastFMArtist.search(artists: "Nine") { artists in
            print("\n*******VPLastFMArtist.search*********")
            artists.forEach{
                print("\($0.name)")
            }
        }
        
        VPLastFMAlbum.getAlbum(byName: "Help", artist: "Beatles") { album in
            print("\n*******VPLastFMAlbum.getAlbum*********")
            print(album?.name)
            album?.tracks?.forEach{
                print("\($0.artist.name) - \($0.name)")
            }
        }
    }
}

