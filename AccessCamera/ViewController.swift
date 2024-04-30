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
    
    var playLayer = CALayer()
    var coloredLayer = CALayer()
    var KeyLayer_w = CAShapeLayer()
    var KeyLayer_b = CAShapeLayer()
    
    var count_all = UInt()
    var count_collect = UInt()
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureSession()
        setupDevice()
        setupPreviewLayer()
        captureSession.startRunning()
        
       // canvasView.layer = CALayer()
        white_key()
        black_key()
        playnote(note: play_no)
        score()
        
      //  let sourcepath = "/Users/otowajoho/Desktop/鍵盤サンプル.png"
        //let sourcepath = "/Users/otowajoho/Desktop/鍵盤サンプル.png"
        
       // let image = NSImage(contentsOfFile: sourcepath)
      // imageView.frame = CGRect(x: 0, y: 10, width: 1440, height: 900)
      //  imageView.image = NSImage(named: "鍵盤サンプル")
        
        midi = MIDIManager()
        if 0 < midi!.numberOfSources {
            midi!.connectMIDIClient(0)
            midi!.delegate = self
    }
        
    }
    
    func playnote(note: UInt) {
        play_no = UInt.random(in: 36..<56)
        score()
        //play_no = 38
        print(play_no)
        playLayer = createLayer()
        
        var X = UInt(100)
        var Y = 300
        let Num = UInt(play_no - 36)
        var Width = UInt(50)
        var Height = UInt(565)
        
        //黒鍵
        if play_no%12 == 1 || play_no%12 == 3 || play_no%12 == 6 || play_no%12 == 8 || play_no%12 == 10 {
            if play_no < 40 {
                X = Num * 55 + 95
                print(X)
            }else if play_no < 47 {
                X = Num * 55 + 150
            } else if play_no < 52 {
                X = Num * 55 + 205
            } else {
                X = Num * 55 + 260
            }
            Width = 70
            Height = 150
            Y = 460
//            white_key()
//            black_key()
            playLayer.frame = CGRect(x: Int(X), y: Y, width: Int(Width), height: Int(Height))
            playLayer.backgroundColor = CGColor(red: 255, green: 0, blue: 0, alpha: 0.8)
            canvasView.layer?.addSublayer(playLayer)
            
        } else{
        //白鍵
            if play_no < 41 {
                X = Num * 54 + 108
            } else if play_no < 48 {
                X = Num * 54 + 108 + 54
            } else if play_no < 53 {
                X = Num * 54 + 108 + 108
            } else{
                X = Num * 54 + 108 + 162
            }
            Width = 50
            Height = 560
            Y = 50
            
            playLayer.frame = CGRect(x: Int(X), y: Y, width: Int(Width), height: Int(Height))
            playLayer.backgroundColor = CGColor(red: 255, green: 0, blue: 0, alpha: 0.8)
            canvasView.layer?.insertSublayer(playLayer, at: 1)
            //black_key()
            //canvasView.layer?.addSublayer(playLayer)
        }

        
        
    }
    
    func noteOn(ch: UInt8, note: UInt8, vel: UInt8, t: UInt8) {
        on_num = note
        count_all = count_all + 1
        //canvasView.layer = CALayer()
       // let layerSize = CGSize(width: 0, height: 0)
        coloredLayer = createLayer()
        var  X = UInt(100)
        var Y = 300
        let Num = UInt(note - 36)
        var Width = UInt(120)
        var Height = UInt(200)
        
        if on_num == play_no{
            playnote(note: play_no)
            count_collect = count_collect + 1
        }
        
        //黒鍵
        if note%12 == 1 || note%12 == 3 || note%12 == 6 || note%12 == 8 || note%12 == 10 {
            if note < 40 {
                X = Num * 55 + 95
                print(X)
            }else if note < 47 {
                X = Num * 55 + 150
            } else if note < 52 {
                X = Num * 55 + 205
            } else {
                X = Num * 55 + 260
            }
            Width = 70
            Height = 150
            Y = 460
            coloredLayer.frame = CGRect(x: Int(X), y: Y, width: Int(Width), height: Int(Height))
            
            if play_no%12 == 1 || play_no%12 == 3 || play_no%12 == 6 || play_no%12 == 8 || play_no%12 == 10 {
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
            if note < 41 {
                X = Num * 54 + 108
            } else if note < 48 {
                X = Num * 54 + 108 + 54
            } else if note < 53 {
                X = Num * 54 + 108 + 108
            } else{
                X = Num * 54 + 162 + 108
            }
            Width = 50
            Height = 560
            Y = 50
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
                    canvasView.layer?.addSublayer(coloredLayer)
                    black_key()
                    canvasView.layer?.addSublayer(playLayer)
                } else {
                    white_key()
                    canvasView.layer?.addSublayer(coloredLayer)
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
        newLayer.backgroundColor = CGColor(red: 0, green: 255, blue: 255, alpha: 0.8)
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
        //KeyLayer_w.strokeColor = CGColor(red: 0, green: 0, blue: 0, alpha: 0.6)
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
                    //view.layer?.addSublayer(previewLayer!)

                } catch {
                    print(AVCaptureSessionErrorKey.description)
                }
            }
        }
        
    }

