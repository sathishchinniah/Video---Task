//
//  ViewController.swift
//  Video Task 2
//
//  Created by Sathish Chinniah on 20/11/15.
//  Copyright © 2015 Sathish Chinniah. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices
import AssetsLibrary
import MediaPlayer
import CoreMedia

class ViewController: UIViewController{
    var Asset1: AVAsset?
    var Asset2: AVAsset?
    var Asset3: AVAsset?
    var audioAsset: AVAsset?
    var loadingAssetOne = false
    
// swt duplicate image for thumbnail image for audio
    @IBOutlet weak var musicImg: UIImageView!

    var videoPlayer = MPMoviePlayerController()
var mediaUI = UIImagePickerController()
    var videoURL = NSURL()


    override func viewDidLoad() {
        super.viewDidLoad()
        musicImg.hidden = true
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func startMediaBrowserFromViewController(viewController: UIViewController!, usingDelegate delegate : protocol<UINavigationControllerDelegate, UIImagePickerControllerDelegate>!) -> Bool {
        
        if UIImagePickerController.isSourceTypeAvailable(.SavedPhotosAlbum) == false {
            return false
        }
        
        let mediaUI = UIImagePickerController()
        mediaUI.sourceType = .SavedPhotosAlbum
      
        
        
        mediaUI.mediaTypes = [kUTTypeMovie as String]
        mediaUI.allowsEditing = true
        mediaUI.delegate = delegate
        presentViewController(mediaUI, animated: true, completion: nil)
        return true
    }
    
    
// after merge all video and audio. the final video will be saved in gallery and also will display like preview
    func exportDidFinish(session: AVAssetExportSession) {
        if session.status == AVAssetExportSessionStatus.Completed {
            let outputURL = session.outputURL
            let library = ALAssetsLibrary()
            if library.videoAtPathIsCompatibleWithSavedPhotosAlbum(outputURL) {
                library.writeVideoAtPathToSavedPhotosAlbum(outputURL,
                    completionBlock: { (assetURL:NSURL!, error:NSError!) -> Void in
                    
                        if error != nil {
                            
                            print("some files went wrong")

                        } else {
                           
                            // get the output url to display the final video in screen
                            self.videoURL = outputURL!
                            
                            self.mediaUI.dismissViewControllerAnimated(true, completion: nil)
                            self.videoPlayer = MPMoviePlayerController()
                            self.videoPlayer.contentURL = self.videoURL
                            
                            
                            self.videoPlayer.controlStyle = .Embedded
                            
                            self.videoPlayer.scalingMode = .AspectFill
                            
                            self.videoPlayer.shouldAutoplay = true
                            
                            self.videoPlayer.backgroundView.backgroundColor = UIColor.clearColor()
                            self.videoPlayer.fullscreen = true
                            self.videoPlayer.view.frame = CGRectMake(38, 442, 220, 106)
                            
                            self.view.addSubview(self.videoPlayer.view)
                            
                            self.videoPlayer.play()
                            self.videoPlayer.prepareToPlay()

                        }

                })
            }
        }
        
    
        Asset1 = nil
        Asset2 = nil
        Asset3 = nil
        audioAsset = nil
    }
    
    
    
    // click first video
    @IBAction func FirstVideo(sender: AnyObject) {
                  loadingAssetOne = true
            startMediaBrowserFromViewController(self, usingDelegate: self)
        
    }
    
// clcik second video
    @IBAction func SecondVideo(sender: AnyObject) {
       
            loadingAssetOne = false
            startMediaBrowserFromViewController(self, usingDelegate: self)
        
    }
   // click audio
    @IBAction func Audio(sender: AnyObject) {
        
        let mediaPickerController = MPMediaPickerController(mediaTypes: .Any)
        mediaPickerController.delegate = self
        mediaPickerController.prompt = "Select Audio"
        presentViewController(mediaPickerController, animated: true, completion: nil)
    }
    
    
    
    
    
    
    
    @IBAction func playPreview(sender: AnyObject) {
        
         startMediaBrowserFromViewController(self, usingDelegate: self)
    }
    
    
    
    
    // orientation for the video
    func orientationFromTransform(transform: CGAffineTransform) -> (orientation: UIImageOrientation, isPortrait: Bool) {
        var assetOrientation = UIImageOrientation.Up
        var isPortrait = false
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .Right
            isPortrait = true
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .Left
            isPortrait = true
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            assetOrientation = .Up
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .Down
        }
        return (assetOrientation, isPortrait)
    }
    
    func videoCompositionInstructionForTrack(track: AVCompositionTrack, asset: AVAsset) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let assetTrack = asset.tracksWithMediaType(AVMediaTypeVideo)[0]
        
        let transform = assetTrack.preferredTransform
        let assetInfo = orientationFromTransform(transform)
        
        var scaleToFitRatio = UIScreen.mainScreen().bounds.width / assetTrack.naturalSize.width
        if assetInfo.isPortrait {
            scaleToFitRatio = UIScreen.mainScreen().bounds.width / assetTrack.naturalSize.height
            let scaleFactor = CGAffineTransformMakeScale(scaleToFitRatio, scaleToFitRatio)
            instruction.setTransform(CGAffineTransformConcat(assetTrack.preferredTransform, scaleFactor),
                atTime: kCMTimeZero)
        } else {
            let scaleFactor = CGAffineTransformMakeScale(scaleToFitRatio, scaleToFitRatio)
            var concat = CGAffineTransformConcat(CGAffineTransformConcat(assetTrack.preferredTransform, scaleFactor), CGAffineTransformMakeTranslation(0, UIScreen.mainScreen().bounds.width / 2))
            if assetInfo.orientation == .Down {
                let fixUpsideDown = CGAffineTransformMakeRotation(CGFloat(M_PI))
                let windowBounds = UIScreen.mainScreen().bounds
                let yFix = assetTrack.naturalSize.height + windowBounds.height
                let centerFix = CGAffineTransformMakeTranslation(assetTrack.naturalSize.width, yFix)
                concat = CGAffineTransformConcat(CGAffineTransformConcat(fixUpsideDown, centerFix), scaleFactor)
            }
            instruction.setTransform(concat, atTime: kCMTimeZero)
        }
        
        return instruction
    }
   // merge all file
    @IBAction func MergeAll(sender: AnyObject) {
        if let firstAsset = Asset1, secondAsset = Asset2 {
     
            let mixComposition = AVMutableComposition()
            
            //load first video
            let firstTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo,
                preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            do {
                try firstTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, firstAsset.duration),
                    ofTrack: firstAsset.tracksWithMediaType(AVMediaTypeVideo)[0] ,
                    atTime: kCMTimeZero)
            } catch _ {
            }
            // load second video
            let secondTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo,
                preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            do {
                try secondTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, secondAsset.duration),
                    ofTrack: secondAsset.tracksWithMediaType(AVMediaTypeVideo)[0] ,
                    atTime: firstAsset.duration)
            } catch _ {
            }
            
            
            let mainInstruction = AVMutableVideoCompositionInstruction()
            mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeAdd(firstAsset.duration, secondAsset.duration))
            
            let firstInstruction = videoCompositionInstructionForTrack(firstTrack, asset: firstAsset)
            firstInstruction.setOpacity(0.0, atTime: firstAsset.duration)
            let secondInstruction = videoCompositionInstructionForTrack(secondTrack, asset: secondAsset)
            
            mainInstruction.layerInstructions = [firstInstruction, secondInstruction]
            let mainComposition = AVMutableVideoComposition()
            mainComposition.instructions = [mainInstruction]
            mainComposition.frameDuration = CMTimeMake(1, 30)
            mainComposition.renderSize = CGSize(width: UIScreen.mainScreen().bounds.width, height: UIScreen.mainScreen().bounds.height)
            
            //load audio
            if let loadedAudioAsset = audioAsset {
                let audioTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: 0)
                do {
                    try audioTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, CMTimeAdd(firstAsset.duration, secondAsset.duration)),
                        ofTrack: loadedAudioAsset.tracksWithMediaType(AVMediaTypeAudio)[0] ,
                        atTime: kCMTimeZero)
                } catch _ {
                }
            }
            
          // save the final video to gallery
            let documentDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = .LongStyle
            dateFormatter.timeStyle = .ShortStyle
            let date = dateFormatter.stringFromDate(NSDate())
            // let savePath = documentDirectory.URLByAppendingPathComponent("mergeVideo-\(date).mov")
            
         let savePath = (documentDirectory as NSString).stringByAppendingPathComponent("final-\(date).mov")
            
            let url = NSURL(fileURLWithPath: savePath)
            
            
            let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality)
            exporter!.outputURL = url
            exporter!.outputFileType = AVFileTypeQuickTimeMovie
            exporter!.shouldOptimizeForNetworkUse = true
            exporter!.videoComposition = mainComposition
            
            exporter!.exportAsynchronouslyWithCompletionHandler() {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.exportDidFinish(exporter!)
                })
            }
        }
    }
    
}

extension ViewController: UIImagePickerControllerDelegate {
    
    
    
    // display the first & second video after it picked from gallery
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        dismissViewControllerAnimated(true, completion: nil)
        
        if mediaType == kUTTypeMovie {
            
            let avAsset = AVAsset(URL: info[UIImagePickerControllerMediaURL] as! NSURL)
            
            if loadingAssetOne {
                
                if let vURL = info[UIImagePickerControllerMediaURL] as? NSURL {
                    self.videoURL = vURL
                } else {
                    print("oops, no url")
                }
                mediaUI.dismissViewControllerAnimated(true, completion: nil)
                self.videoPlayer = MPMoviePlayerController()
                self.videoPlayer.contentURL = videoURL
                self.videoPlayer.view.frame = CGRectMake(38, 57, 220, 106)
                self.view.addSubview(self.videoPlayer.view)
                
                self.videoPlayer.controlStyle = .Embedded
                
                self.videoPlayer.scalingMode = .AspectFill
           
                
                self.videoPlayer.shouldAutoplay = true
                self.videoPlayer.prepareToPlay()
                self.videoPlayer.play()

                
                Asset1 = avAsset
            } else {
                
                if let vURL = info[UIImagePickerControllerMediaURL] as? NSURL {
                    self.videoURL = vURL
                } else {
                    print("oops, no url")
                }
                mediaUI.dismissViewControllerAnimated(true, completion: nil)
                self.videoPlayer = MPMoviePlayerController()
                self.videoPlayer.contentURL = videoURL
                self.videoPlayer.view.frame = CGRectMake(38, 206, 220, 106)
                self.view.addSubview(self.videoPlayer.view)
                self.videoPlayer.play()
          
                self.videoPlayer.controlStyle = .Embedded
                
                self.videoPlayer.scalingMode = .AspectFill
            
                
                self.videoPlayer.shouldAutoplay = true
                self.videoPlayer.prepareToPlay()
            
             
                Asset2 = avAsset
            }
            
        }
        
   
}

            
}
    
    
    
    


extension ViewController: UINavigationControllerDelegate {
    
}

extension ViewController: MPMediaPickerControllerDelegate {
    func mediaPicker(mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        let selectedSongs = mediaItemCollection.items
        if selectedSongs.count > 0 {
            let song = selectedSongs[0]
         
            
            if let vURL = song.valueForProperty(MPMediaItemPropertyAssetURL) as? NSURL {
                audioAsset = AVAsset(URL: vURL)

                dismissViewControllerAnimated(true, completion: nil)
                

                mediaUI.dismissViewControllerAnimated(true, completion: nil)
                      musicImg.hidden = false

                
                let alert = UIAlertController(title: "yes", message: "Audio Loaded", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler:nil))
                presentViewController(alert, animated: true, completion: nil)
            } else {
                dismissViewControllerAnimated(true, completion: nil)
                let alert = UIAlertController(title: "No audio", message: "Audio Not Loaded", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler:nil))
                presentViewController(alert, animated: true, completion: nil)
            }
        } else {
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func mediaPickerDidCancel(mediaPicker: MPMediaPickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}

