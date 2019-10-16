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
import GLKit
import AVFoundation
import Speech

class LiveTranscribeViewController: UIViewController {
  
    let audioEngine = AVAudioEngine()
    let speechRecognizer = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?

  @IBOutlet weak var imageView: GLKView!
  var faceReplacer: FaceReplacer!
  
  @IBOutlet weak var faceCollectionView: UICollectionView!
  let faceSource = FaceSource()
  
  @IBOutlet weak var transcriptionOutputLabel: UILabel!
  
  @IBAction func handleDoneTapped(_ sender: BorderedButton) {
    faceReplacer.stopCapture()
    stopRecording()

    dismiss(animated: true, completion: .none)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    initialiseFaceReplacer()
    //startRecording()
    SFSpeechRecognizer.requestAuthorization {
    [unowned self] (authStatus) in
    switch authStatus {
    case .authorized:
        do {
            try self.startRecording()
        } catch let error {
            print("There was a problem starting recording: \(error.localizedDescription)")
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
}

extension LiveTranscribeViewController {
  fileprivate func startRecording() throws {
    DispatchQueue.main.async {
         self.transcriptionOutputLabel.text = ""
    }
   
    // 1
    let node = audioEngine.inputNode
    
    print(audioEngine.inputNode.inputFormat(forBus: 0))
    print(audioEngine.inputNode.outputFormat(forBus: 0))
  
    
    //let recordingFormat = node.outputFormat(forBus: 0)
    let recordingFormat = node.inputFormat(forBus: 0)
//trying
    let mixer = audioEngine.mainMixerNode
    let format = mixer.outputFormat(forBus: 0)
    print(format)
    // 2
    
    let sampleRate = AVAudioSession.sharedInstance().sampleRate
    let fmt = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 48000, channels: 1, interleaved: false)
    
    print("Rate is \(sampleRate)")
    
    node.installTap(onBus: 0, bufferSize: 1024,
                    format: fmt) { [unowned self]
      (buffer, _) in
      self.request.append(buffer)
    }
 print("Made it!")
    // 3
    audioEngine.prepare()
    do{
     try audioEngine.start()
    } catch let error {
        print("aargh \(error.localizedDescription)")
    }
    
    recognitionTask = speechRecognizer?.recognitionTask(with: request) {
      [unowned self]
      (result, _) in
      if let transcription = result?.bestTranscription {
        DispatchQueue.main.async(execute:{
              // self.transcriptionOutputLabel.text = transcription.formattedString
            self.updateText(txt: transcription.formattedString)
            print(transcription.formattedString)
        })
     
      }
    }

  }
    
    fileprivate func stopRecording() {
      audioEngine.stop()
      request.endAudio()
      recognitionTask?.cancel()
    }

    func updateText(txt:String){
        print("called")
        self.transcriptionOutputLabel.text = txt
    }
}


extension LiveTranscribeViewController {
  fileprivate func initialiseFaceReplacer() {
    faceReplacer = FaceReplacer(imageView: imageView)
    do {
      try faceReplacer.startCapture()
    } catch let error as NSError {
      let alert = UIAlertController(title: "Sorry", message: error.localizedDescription, preferredStyle: .alert)
      present(alert, animated: true, completion: .none)
    }
    faceCollectionView.dataSource = faceSource
    faceCollectionView.delegate = faceSource
    faceSource.collectionView = faceCollectionView
    faceSource.faceChosen = {
      [unowned self]
      face in
      self.faceReplacer.newFace = face
    }
  }
}

