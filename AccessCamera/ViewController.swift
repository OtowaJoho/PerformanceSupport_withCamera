//
//  ViewController.swift
//  AccessCamera
//
//  Created by Otowa Joho on 2023/10/19.
//


import Cocoa
import AVFoundation
import SwiftUI
import Vision

let sampler = MIDIManager()

class ViewController: NSViewController, MIDIManagerDelegate {
    
    @IBOutlet weak var camera: NSView!
    @IBOutlet weak var canvasView: NSView!
    @IBOutlet weak var keyView: NSView!
    @IBOutlet weak var imageView: NSImageView!
    private var midi: MIDIManager?
    
    var captureSession = AVCaptureSession()
    var captureDevice : AVCaptureDevice?
    var currentDevice: AVCaptureDevice?
    var previewLayer : AVCaptureVideoPreviewLayer?
    
    var on_num = UInt8()
    var play_no = UInt()
    var Num = Int()
    
    var playLayer = CALayer()
    var coloredLayer = CALayer()
    var KeyLayer_w = CAShapeLayer()
    var KeyLayer_b = CAShapeLayer()
    
    var count_all = UInt()
    var count_collect = UInt()
    
    var X = Int()
    var Y = Int()
    
    var Width = Int()
    var Height = Int()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureSession()
        setupDevice()
        setupPreviewLayer()
        captureSession.startRunning()
        
        canvasView.layer = CALayer()
        //white_key()
        //black_key()
        playnote(note: play_no)
        score()
        
        midi = MIDIManager()
        if 0 < midi!.numberOfSources {
            midi!.connectMIDIClient(0)
            midi!.delegate = self
    }
        
    }
    func frameBlack(playNum : Int){
        
        if playNum < 40 {
            X = Num * 55 + 95
            print(X)
        }else if playNum < 47 {
            X = Num * 55 + 150
        } else if playNum < 52 {
            X = Num * 55 + 205
        } else {
            X = Num * 55 + 260
        }
        Width = 70
        Height = 150
        Y = 460
        print(Num,play_no,X,Y,Width,Height)
    }
    func frameWhite(playNum : Int) {
        if playNum < 41 {
            X = Num * 54 + 108
        } else if playNum < 48 {
            X = Num * 54 + 108 + 54
        } else if playNum < 53 {
            X = Num * 54 + 108 + 108
        } else{
            X = Num * 54 + 108 + 162
        }
        Width = 50
        Height = 560
        Y = 50
    }
    
    func playnote(note: UInt) {
        play_no = UInt.random(in: 36..<56) //演奏提示の鍵盤をランダムで選択
        print("playno\(play_no)")
       // play_no = UInt(37) //テスト用
        score() //スコア表示の関数
        playLayer = createLayer()
        Num = Int(play_no - 36)
        
        //黒鍵
        if play_no%12 == 1 || play_no%12 == 3 || play_no%12 == 6 || play_no%12 == 8 || play_no%12 == 10 {
            frameBlack(playNum: Int(play_no))
        } else{
        //白鍵
            frameWhite(playNum: Int(play_no))

        }
        playLayer.frame = CGRect(x: Int(X), y: Y, width: Int(Width), height: Int(Height))
        playLayer.borderWidth = 8
        playLayer.borderColor = CGColor(red: 1, green: 0.2, blue: 0.2, alpha: 1)
        canvasView.layer?.addSublayer(playLayer)
        
    }
    
    func noteOn(ch: UInt8, note: UInt8, vel: UInt8, t: UInt8) {
        on_num = note
        count_all = count_all + 1
        coloredLayer = createLayer()
        
        if on_num == play_no{
            playnote(note: play_no)
            count_collect = count_collect + 1
            print("onNum:\(Num)")
        }
        Num = Int(note - 36)
        //黒鍵
        if note%12 == 1 || note%12 == 3 || note%12 == 6 || note%12 == 8 || note%12 == 10 {
            frameBlack(playNum: Int(note))
            coloredLayer.frame = CGRect(x: Int(X), y: Y, width: Int(Width), height: Int(Height))
            canvasView.layer?.addSublayer(coloredLayer)
            
            if play_no%12 == 1 || play_no%12 == 3 || play_no%12 == 6 || play_no%12 == 8 || play_no%12 == 10 { //黒鍵を弾かせたいとき
                white_key()
                black_key()
                canvasView.layer?.addSublayer(playLayer)
                canvasView.layer?.addSublayer(coloredLayer)
            } else {
                white_key()
                canvasView.layer?.addSublayer(playLayer)
                black_key()
                canvasView.layer?.addSublayer(coloredLayer)
            }
            
        } else{
        //白鍵
            frameWhite(playNum: Int(note))
            coloredLayer.frame = CGRect(x: Int(X), y: Y, width: Int(Width), height: Int(Height))
            
            if play_no%12 == 1 || play_no%12 == 3 || play_no%12 == 6 || play_no%12 == 8 || play_no%12 == 10 {
                white_key()
                canvasView.layer?.addSublayer(coloredLayer)
                black_key()
                canvasView.layer?.addSublayer(playLayer)
            } else {
                white_key()
                canvasView.layer?.addSublayer(playLayer)
                canvasView.layer?.addSublayer(coloredLayer)
                black_key()
            }
        }
        print("弾いた数：", count_all, "正答数：", count_collect)
        score()
        
    }
    
    func noteOff(ch: UInt8, note: UInt8, vel: UInt8, t: UInt8) {
          score()
          if note == on_num {
              //黒鍵
              if note%12 == 1 || note%12 == 3 || note%12 == 6 || note%12 == 8 || note%12 == 10 {
                  
                  if play_no%12 == 1 || play_no%12 == 3 || play_no%12 == 6 || play_no%12 == 8 || play_no%12 == 10 {
                      white_key()
                      //canvasView.layer?.addSublayer(coloredLayer)
                      black_key()
                      canvasView.layer?.addSublayer(playLayer)
                  } else {
                      white_key()
                     /// canvasView.layer?.addSublayer(coloredLayer)
                      canvasView.layer?.addSublayer(playLayer)
                      black_key()
                  }
              } else{
                  
                  //白鍵
                  if play_no%12 == 1 || play_no%12 == 3 || play_no%12 == 6 || play_no%12 == 8 || play_no%12 == 10 {
                      canvasView.layer?.addSublayer(coloredLayer)
                      white_key()
                      black_key()
                      canvasView.layer?.addSublayer(playLayer)
                  } else {
                      canvasView.layer?.addSublayer(coloredLayer)
                      white_key()
                      canvasView.layer?.addSublayer(playLayer)
                      black_key()
                  }
              }
              score()
          }
      }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
}

//図形の描画
extension ViewController{
    
    func createLayer() -> CALayer {
        let newLayer = CALayer()
        newLayer.borderWidth = 8
        newLayer.borderColor = CGColor(red: 0, green: 1, blue: 1, alpha: 0.8)
        newLayer.anchorPoint = CGPoint(x: 0, y: 0)
        return newLayer
    }
    
    func white_key(){
        canvasView.layer = CALayer()
        //白鍵
        let keypath_w = CGMutablePath()
        for i in stride(from: 0, to: 1240, by: 108){
            keypath_w.addRect( CGRect(x: i+108, y: 50, width: 50, height: 560))
        }
        //let KeyLayer_w = CAShapeLayer()
        KeyLayer_w.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        KeyLayer_w.path = keypath_w
        KeyLayer_w.strokeColor = CGColor(red: 255, green: 255, blue: 255, alpha: 0)
        KeyLayer_w.fillColor = CGColor(red: 255, green: 255, blue: 255, alpha: 0)
        canvasView.layer?.addSublayer(KeyLayer_w)
       
    }
    
    func black_key() {
       // canvasView.layer = CALayer()
        let keypath_b = CGMutablePath()
        let Y = 460
        let W = 70
        let H = 150
        keypath_b.addRect( CGRect(x: 150, y: Y, width: W, height: H))
        keypath_b.addRect( CGRect(x: 260, y: Y, width: W, height: H))
        keypath_b.addRect( CGRect(x: 480, y: Y, width: W, height: H))
        keypath_b.addRect( CGRect(x: 590, y: Y, width: W, height: H))
        keypath_b.addRect( CGRect(x: 700, y: Y, width: W, height: H))
        keypath_b.addRect( CGRect(x: 920, y: Y, width: W, height: H))
        keypath_b.addRect( CGRect(x: 1030, y: Y, width: W, height: H))
        keypath_b.addRect( CGRect(x: 1250, y: Y, width: W, height: H))
        
        //let KeyLayer_b = CAShapeLayer()
        KeyLayer_b.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        KeyLayer_b.path = keypath_b
        KeyLayer_b.fillColor = CGColor(red: 0, green: 0, blue: 0, alpha: 0)
        canvasView.layer?.addSublayer(KeyLayer_b)
    }
    
    func score() {
        let textLayer = CATextLayer()
        textLayer.frame = CGRectMake(800,700, 300, 100)
        textLayer.string = "弾いた数：\(count_all)\n 正解数：\(count_collect)"
        textLayer.foregroundColor = CGColor(red: 255, green: 255, blue: 255, alpha: 1)
        textLayer.fontSize = 30.0
        // 次の行は、ないと非Retina状態でレンダリングされる by Takabosoftさん
        //textLayer.contentsScale = CGScreen.mainScreen().scale
       canvasView.layer?.addSublayer(textLayer)
    }
    
}

    
// カメラ映像の描画
    extension ViewController{
        
        func setupCaptureSession() {
            camera.layer = CALayer()
            //rect.layer = CALayer()
            captureSession.sessionPreset = AVCaptureSession.Preset.qHD960x540
        }
        
        func setupDevice(){
            let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .externalUnknown], mediaType: .video, position: .unspecified)
            let captureSession = AVCaptureSession()
            
            //接続されたデバイスの確認
                for device in discoverySession.devices {
                    print(device.localizedName)
                    let videoInput = try! AVCaptureDeviceInput(device: device)
                    let available: String = captureSession.canAddInput(videoInput) ? "true": "false"
        
                    print("\tConnected: \(device.isConnected)")
                    print("\tSuspended: \(device.isSuspended)")
                    print("\tAvailable: \(available)")
                    print("\tIs In Use: \(device.isInUseByAnotherApplication)")
                    print()
                }
            
            let devices = discoverySession.devices
            for device in devices {
                print(device)
                if device.localizedName == "Brio 500" {
                    captureDevice = device
                }
                
                // Camera object found and assign it to captureDevice
            }
            currentDevice = captureDevice
        }
        
        func setupPreviewLayer() {
            if captureDevice != nil {

                do {

                    try captureSession.addInput(AVCaptureDeviceInput(device: currentDevice!))
                    
                    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                    previewLayer?.transform = CATransform3DMakeRotation(Double.pi / 180 * 180, 0, 0, 1)
                    previewLayer?.frame = CGRect(x: 0, y: 0, width: 1440, height: 900)
                    previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
                    //previewLayer?.frame = CGRect(x: 0, y: 0, width: 1000, height: 900)
                    // Add previewLayer into custom view
                    self.camera.layer?.addSublayer(previewLayer!)

                } catch {
                    print(AVCaptureSessionErrorKey.description)
                }
            }
        }
        
    }

