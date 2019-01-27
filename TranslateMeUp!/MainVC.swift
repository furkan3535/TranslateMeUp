//
//  MainVC.swift
//  TranslateMeUp!
//
//  Created by Furkan Polat Acikgoz on 31/07/2017.
//  Copyright © 2017 Furkan Polat Acikgoz. All rights reserved.
//

import UIKit
import Speech
import Alamofire

class MainVC: UIViewController , SFSpeechRecognizerDelegate{
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))  //1
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var translatedView: UITextView!
    @IBOutlet weak var microphoneButton: UIButton!
    @IBOutlet weak var langBtnOut: UIButton!
    var lang:Bool = true//True = English -> Turkish / Else = Turkish -> English
    var url:String = ""
    @IBAction func langBtn(_ sender: Any) {
        lang = !lang
        if lang{
            langBtnOut.setTitle("EN -> TR", for: .normal)
            speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
            textView.text = "Say something, I'm listening!"
            translatedView.text = "Waiting for translate!"

        }else{
            langBtnOut.setTitle("TR -> EN", for: .normal)
            speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "tr"))
            textView.text = "Bir şey söyle, dinliyorum!"
            translatedView.text = "Çeviri için bekleniyor!"

        }
    }
    @IBAction func microphoneTapped(_ sender: Any) {
        if audioEngine.isRunning {
            microphoneButton.setTitle("Press & Talk", for: .normal)
            audioEngine.stop()				
            recognitionRequest?.endAudio()
            microphoneButton.isEnabled = false
            if lang{
            url = "https://translate.yandex.net/api/v1.5/tr.json/translate?key=trnsl.1.1.20170731T040330Z.c348b53bd447fb46.be28a374d693ba2006baf64d657c30a94166b755&lang=en-tr&text=\(textView.text!)".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            }else{
               url = "https://translate.yandex.net/api/v1.5/tr.json/translate?key=trnsl.1.1.20170731T040330Z.c348b53bd447fb46.be28a374d693ba2006baf64d657c30a94166b755&lang=tr-en&text=\(textView.text!)".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            }
            print(textView.text)
            let translatedURL = URL(string: url)!
            print(textView.text)
            print(url)
            Alamofire.request(translatedURL).responseJSON{response in
                let result = response.result
                print(result)
                if let dict = result.value as? Dictionary<String,AnyObject>{
                    print(dict)
                    if let list = dict["text"] as? [String]{
                        print(list)
                        self.translatedView.text = list[0]
                        
                    }
                    
                }
            }

        } else {
            startRecording()
            microphoneButton.setTitle("Press Stop", for: .normal)
        }
    }
    
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    override func viewDidLoad() {
        super.viewDidLoad()

        
        microphoneButton.isEnabled = false  //2
        
        speechRecognizer?.delegate = self  //3
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in  //4
            
            var isButtonEnabled = false
            
            switch authStatus {  //5
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            OperationQueue.main.addOperation() {
                self.microphoneButton.isEnabled = isButtonEnabled
            }
        }
    }
    func startRecording() {
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                
                self.textView.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.microphoneButton.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        if lang{
            textView.text = "Say something, I'm listening!"
        }else{
            textView.text = "Bir şey söyle, dinliyorum!"
        }
        
    }
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            microphoneButton.isEnabled = true
        } else {
            microphoneButton.isEnabled = false
        }
    }
    
}
