/**
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import AVFoundation
import Speech

class RecordingViewController: UIViewController {
  
  fileprivate var player: AVPlayer?
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var subtitleLabel: UILabel!
  @IBOutlet weak var transcriptionTextView: UITextView!
  @IBOutlet weak var rewindButton: BorderedButton!
  @IBOutlet weak var playButton: BorderedButton!
  @IBOutlet weak var stopButton: BorderedButton!
  @IBOutlet weak var transcribeButton: BorderedButton!
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  @IBOutlet weak var contentStackView: UIStackView!
  @IBOutlet weak var faceReplaceButton: UIBarButtonItem!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    faceReplaceButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera)
    
    if let recording = recording {
      updateForRecording(recording)
    } else {
      contentStackView.isHidden = true
    }
    
    try! AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord)
    
  }
  
  // Mark: - Audio control
  @IBAction func handlePlaybackControlTapped(_ sender: BorderedButton) {
    switch sender {
    case playButton:
      playButton.isEnabled = false
      stopButton.isEnabled = true
      player?.play()
    case stopButton:
      playButton.isEnabled = true
      stopButton.isEnabled = false
      player?.pause()
    case rewindButton:
      player?.seek(to: CMTime(seconds: 0, preferredTimescale: 1))
    default:
      break
    }
  }
  
  var recording: Recording? {
    didSet {
      if let recording = recording {
        updateForRecording(recording)
      }
    }
  }
  
  fileprivate func updateForRecording(_ recording: Recording) {
    contentStackView?.isHidden = false
    titleLabel?.text = recording.title
    subtitleLabel?.text = recording.subtitle
    transcriptionTextView?.text = .none
    stopButton?.isEnabled = false
    player = AVPlayer(url: recording.audio)
    activityIndicator?.stopAnimating()
    activityIndicator?.isHidden = true
    transcriptionTextView?.isHidden = true
  }
}

// MARK: - Transcription management
extension RecordingViewController {
  
  @IBAction func handleTranscribeButtonTapped(_ sender: BorderedButton) {
    print("tapped")
    SFSpeechRecognizer.requestAuthorization {
        [unowned self] (authStatus) in
        switch authStatus {
        case .authorized:
        if let recording = self.recording {
         //kickoff transcription
            self.transcribeFile(url: recording.audio
            )
        }
        case .denied:
            print("Speech recognition authorization denied")
        case .restricted:
            print("Not available on this device")
        case .notDetermined:
            print("not determined - need to ask!")
        default:
            print("default new case")
        }
        
    }
  }
  
  fileprivate func updateUIForTranscriptionInProgress() {
    DispatchQueue.main.async { [unowned self] in
      self.transcribeButton.isEnabled = false
      self.activityIndicator.startAnimating()
      UIView.animate(withDuration: 0.5) {
        self.activityIndicator.isHidden = false
      }
    }
  }
  
  fileprivate func updateUIWithCompletedTranscription(_ transcription: String) {
    DispatchQueue.main.async { [unowned self] in
      self.transcriptionTextView.text = transcription
      UIView.animate(withDuration: 0.5, animations: {
        self.activityIndicator.isHidden = true
        self.transcriptionTextView.isHidden = false
        }, completion: { _ in
          self.activityIndicator.stopAnimating()
          self.transcribeButton.isEnabled = true
      })
    }
  }
}
/*
// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVAudioSessionCategory(_ input: AVAudioSession.Category) -> String {
	return input.rawValue
}
*/

extension RecordingViewController {

    fileprivate func transcribeFile(url:URL){
        guard let recognizer = SFSpeechRecognizer() else {
            print("Speech recognition not avaiable for specified locale.")
            return
            
        }
        
        if !recognizer.isAvailable {
            print("Speech recognition not currently available")
            return
            
        }
        
        updateUIForTranscriptionInProgress()
        let request = SFSpeechURLRecognitionRequest(url:url)
        
        recognizer.recognitionTask(with: request){
            [unowned self] (result,error) in
        guard let result = result else {
            print("There was an error transcribing the file.")
            return
        }//else
        
            if result.isFinal {
                self.updateUIWithCompletedTranscription(result.bestTranscription.formattedString)
            }
    }//recognitionTask

    }//func transcribeFile
}//extension
