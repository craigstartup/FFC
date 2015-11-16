import UIKit
import AVFoundation

var dict = ["hi": [4,5,6], "foo": ["hi","foo","you"]]
dict["hi"]?[0]
var test = [21,23,23,4,2,1]
test.removeAtIndex(1)
test.insert(9, atIndex: 1)
var tester: [Int!]
tester = [22,54,21,35,67]
tester[2] = nil
tester
var url = NSURL(fileURLWithPath:  "file:///var/mobile/Containers/Data/Application/82EAFC55-3648-452F-95E7-852B8634A2AC/Documents/sound-November%2014,%202015%20at%2011:23:35%20AM%20PST.caf")
url.standardizedURL

var video = AVAsset(URL: url)
video.tracks
let defaultURL = NSURL(string: "placeholder")
defaultURL?.absoluteString