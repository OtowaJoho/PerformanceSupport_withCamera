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
import opencv2
import AppKit

let sampler = MIDIManager()

class ViewController: NSViewController, MIDIManagerDelegate{
    
    @IBOutlet weak var camera: NSView!
    @IBOutlet weak var canvasView: NSView!
    @IBOutlet weak var keyView: NSView!
    //@IBOutlet weak var imageView: NSImageView!
    
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
    var startLayer = CAShapeLayer()
    
    var count_all = UInt()
    var count_collect = UInt()
    
    var X = Int()
    var Y = Int()
    
    var Width = Int()
    var Height = Int()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        CameraManager.shared.startSession(delegate: self)
        canvasView.layer = CALayer()
        //kyaritan()
        //white_key()
        //black_key()
        //        playnote(note: play_no)
        //        score()
        
        midi = MIDIManager()
        if 0 < midi!.numberOfSources {
            midi!.connectMIDIClient(0)
            midi!.delegate = self
        }
    }
    override var representedObject: Any? {
        didSet {}
    }
    
    
    
    func kyaritan() {
        let kyaripath = CGMutablePath()
        kyaripath.addRect( CGRect(x: 0, y: 610, width: 1500, height: 10))
        kyaripath.addRect( CGRect(x: 98, y: 0, width: 10, height: 800))
        //let KeyLayer_b = CAShapeLayer()
        startLayer.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        startLayer.path = kyaripath
        startLayer.fillColor = CGColor(red: 0.9, green: 0, blue: 0.9, alpha: 0.6)
        camera.layer?.addSublayer(startLayer)
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



class CameraManager:NSObject, AVCaptureVideoDataOutputSampleBufferDelegate{
    private let targetDeviceName = "FaceTime HDカメラ"
    
    private let captureSession = AVCaptureSession()
    private var captureDevice : AVCaptureDevice!
    private var videoOutput = AVCaptureVideoDataOutput()
    
    
    func startSession(delegate:AVCaptureVideoDataOutputSampleBufferDelegate){
        
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .externalUnknown], mediaType: .video, position: .unspecified)
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
            //FaceTime HDカメラ
            //Brio 500
            if device.localizedName == "FaceTime HDカメラ" {
                captureDevice = device
            }
            
            // Camera object found and assign it to captureDevice
        }
        
        captureSession.beginConfiguration()
        let videoInput = try? AVCaptureDeviceInput.init(device: captureDevice)
        captureSession.sessionPreset = AVCaptureSession.Preset.qHD960x540
        captureSession.addInput(videoInput!)
        captureSession.addOutput(videoOutput)
        captureSession.commitConfiguration()
        //フレームレート
        captureDevice.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 60)
        captureSession.startRunning()
        
        //画像バッファ取得のための設定
        let queue:DispatchQueue = DispatchQueue(label: "videoOutput", attributes: .concurrent)
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String : Int(kCMPixelFormat_32BGRA)]
        videoOutput.setSampleBufferDelegate(delegate, queue: queue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        
    }
    
}

extension CameraManager {
    class var shared : CameraManager {
        struct Static { static let instance : CameraManager = CameraManager()}
        return Static.instance
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection){
        DispatchQueue.main.sync(execute: {
            
            let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
            CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
            let base = CVPixelBufferGetBaseAddressOfPlane(imageBuffer,0)!
            let bytesPerRow = UInt(CVPixelBufferGetBytesPerRow(imageBuffer))
            let width = UInt(CVPixelBufferGetWidth(imageBuffer))
            let height = UInt(CVPixelBufferGetHeight(imageBuffer))
            
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitsPerCompornent = 8
            let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue) as UInt32)
            let newContext = CGContext(data: base, width: Int(width), height: Int(height), bitsPerComponent: Int(bitsPerCompornent), bytesPerRow: Int(bytesPerRow), space: colorSpace, bitmapInfo: bitmapInfo.rawValue)! as CGContext
            
            CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
            
            let imageRef = newContext.makeImage()!
            let image = NSImage(cgImage: imageRef, size: NSSize(width:Int(width),height: Int(height)))
            
            //NSImage -> Mat に変換
            let srcMat = Mat(nsImage: image)
            let mtx = Mat(rows: 3, cols: 3, type: CvType.CV_64F)
            try! mtx.put(row: 0, col: 0, data: [1.92380473e+03, 0, 1.43588428e+03] as [Float64])
            try! mtx.put(row: 1, col: 0, data: [0, 1.92926580e+03, 9.02045464e+02] as [Float64])
            try! mtx.put(row: 2, col: 0, data: [0, 0, 1] as [Float64])
            //print("mat: \(mtx.dump())")
            
            let dist =  Mat(rows:3, cols: 3, type: CvType.CV_64F)
            try! dist.put(row: 0, col: 0, data: [0.17418398, -0.58908136, -0.00068051, 0.00181742, 0.636665  ])
            
            let distCoeffs = Mat()
            
            let newcameramtx = Mat(rows:3, cols:3, type: CvType.CV_64F)
            try! newcameramtx.put(row: 0, col: 0, data: [1.96640717e+03, 0, 1.44133019e+03])
            try! newcameramtx.put(row: 1, col: 0, data: [0, 1.95778770e+03, 9.01038419e+02])
            try! newcameramtx.put(row: 2, col: 0, data: [0, 0, 1] as [Float64])
            
            Calib3d.undistort(src: srcMat, dst: mtx, cameraMatrix: dist, distCoeffs: distCoeffs, newCameraMatrix: newcameramtx)
            let img = srcMat.toNSImage()
            let subLayer = CALayer()
            subLayer.frame = CGRect(x: 0, y: 0, width: Int(width), height: Int(height))
            subLayer.contents = image
            camera.layer?.addSublayer(subLayer)
            
        })
    }
}

