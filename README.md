# VPLastfm

VPLastfm is a Swift framework for Last.fm developer API.

### Using

Before using VPLastfm in your project you need to set up [api key and shared secret](https://www.last.fm/api/account/create)


```swift
VPLastFMAPIClient.shared.setUp(withApiKey: "your api key", sharedSecret: "yor shared secret")
```
Then you can using Last.fm API simple like this:

```swift
VPLastFMTag.getTopTags(completion: {tags in
            //Do what you want with tags
        })
```
