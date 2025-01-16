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
var count_all = UInt()
var count_collect = UInt()


struct KeyPoint: Codable {
    var x: CGFloat
    var y: CGFloat
}

typealias KeyPoints = [[KeyPoint]] // 各鍵の座標リスト


class PianoKeyState: ObservableObject {
    //色保持してる
    @Published var whiteKeyColors: [Color] = Array(repeating: Color.clear, count: 12) // 白鍵12個分
    @Published var blackKeyColors: [Color] = Array(repeating: Color.clear, count: 8) // 白鍵12個分
    @Published var selectedNote: UInt8? = nil
    
    // 白鍵と黒鍵のMIDI番号
    let midiWhiteNotes: [UInt8] = [36, 38, 40, 41, 43, 45, 47, 48, 50, 52, 53, 55] // 白鍵のMIDI番号
    let midiBlackNotes: [UInt8] = [37, 39, 42, 44, 46, 49, 51, 54]               // 黒鍵のMIDI番号
    
    // 鍵盤の色を変更するメソッド
    func updateKeyColor(forNote note: UInt8, isNoteOn: Bool) {
        if let whiteKeyIndex = midiWhiteNotes.firstIndex(of: note) {
            if note == selectedNote {
                // 白鍵で選ばれたノート
                whiteKeyColors[whiteKeyIndex] = isNoteOn ? Color.blue : Color.red
            } else {
                // 白鍵で選ばれていないノート
                whiteKeyColors[whiteKeyIndex] = isNoteOn ? Color.blue : Color.clear
            }
        } else if let blackKeyIndex = midiBlackNotes.firstIndex(of: note) {
            if note == selectedNote {
                // 黒鍵で選ばれたノート
                blackKeyColors[blackKeyIndex] = isNoteOn ? Color.blue : Color.red
            } else {
                // 黒鍵で選ばれていないノート
                blackKeyColors[blackKeyIndex] = isNoteOn ? Color.blue : Color.clear
            }
        }

    }
}


struct DraggablePianoKeysView: View {
    
    // 白鍵の4つの頂点の座標（12個の白鍵）
    @State private var whiteKeyPoints: [[CGPoint]] = [
        [CGPoint(x: 108, y: 860), CGPoint(x: 158, y: 860), CGPoint(x: 158, y: 300), CGPoint(x: 108, y: 300)],
        [CGPoint(x: 216, y: 860), CGPoint(x: 266, y: 860), CGPoint(x: 266, y: 300), CGPoint(x: 216, y: 300)],
        [CGPoint(x: 324, y: 860), CGPoint(x: 374, y: 860), CGPoint(x: 374, y: 300), CGPoint(x: 324, y: 300)],
        [CGPoint(x: 432, y: 860), CGPoint(x: 482, y: 860), CGPoint(x: 482, y: 300), CGPoint(x: 432, y: 300)],
        [CGPoint(x: 540, y: 860), CGPoint(x: 590, y: 860), CGPoint(x: 590, y: 300), CGPoint(x: 540, y: 300)],
        [CGPoint(x: 648, y: 860), CGPoint(x: 698, y: 860), CGPoint(x: 698, y: 300), CGPoint(x: 648, y: 300)],
        [CGPoint(x: 756, y: 860), CGPoint(x: 806, y: 860), CGPoint(x: 806, y: 300), CGPoint(x: 756, y: 300)],
        [CGPoint(x: 864, y: 860), CGPoint(x: 914, y: 860), CGPoint(x: 914, y: 300), CGPoint(x: 864, y: 300)],
        [CGPoint(x: 972, y: 860), CGPoint(x: 1022, y: 860), CGPoint(x: 1022, y: 300), CGPoint(x: 972, y: 300)],
        [CGPoint(x: 1080, y: 860), CGPoint(x: 1130, y: 860), CGPoint(x: 1130, y: 300), CGPoint(x: 1080, y: 300)],
        [CGPoint(x: 1188, y: 860), CGPoint(x: 1238, y: 860), CGPoint(x: 1238, y: 300), CGPoint(x: 1188, y: 300)],
        [CGPoint(x: 1296, y: 860), CGPoint(x: 1346, y: 860), CGPoint(x: 1346, y: 300), CGPoint(x: 1296, y: 300)]
    ]
 
    // 黒鍵の4つの頂点の座標（8個の黒鍵）
    @State private var blackKeyPoints: [[CGPoint]] = [
        [CGPoint(x: 150, y: 300), CGPoint(x: 220, y: 300), CGPoint(x: 220, y: 450), CGPoint(x: 150, y: 450)],
        [CGPoint(x: 260, y: 300), CGPoint(x: 330, y: 300), CGPoint(x: 330, y: 450), CGPoint(x: 260, y: 450)],
        [CGPoint(x: 480, y: 300), CGPoint(x: 550, y: 300), CGPoint(x: 550, y: 450), CGPoint(x: 480, y: 450)],
        [CGPoint(x: 590, y: 300), CGPoint(x: 660, y: 300), CGPoint(x: 660, y: 450), CGPoint(x: 590, y: 450)],
        [CGPoint(x: 700, y: 300), CGPoint(x: 770, y: 300), CGPoint(x: 770, y: 450), CGPoint(x: 700, y: 450)],
        [CGPoint(x: 920, y: 300), CGPoint(x: 990, y: 300), CGPoint(x: 990, y: 450), CGPoint(x: 920, y: 450)],
        [CGPoint(x: 1030, y: 300), CGPoint(x: 1100, y: 300), CGPoint(x: 1100, y: 450), CGPoint(x: 1030, y: 450)],
        [CGPoint(x: 1250, y: 300), CGPoint(x: 1320, y: 300), CGPoint(x: 1320, y: 450), CGPoint(x: 1250, y: 450)],
    ]
    
    @ObservedObject var pianoKeyState: PianoKeyState
    @State private var whiteDragOffsets: [CGSize] = Array(repeating: .zero, count: 12) // 各図形のドラッグオフセットを保持
    @State private var blackDragOffsets: [CGSize] = Array(repeating: .zero, count: 8)
    
    @State private var isPerforming = false // 確定ボタン後に画面遷移するフラグ
    @State private var whiteKeyList:[[CGPoint]] = [[]]
    @State private var blackKeyList: [[CGPoint]] = []
    

    
    
    var body: some View {
        VStack {
            if isPerforming {
                PerformanceView(whiteKeyPoints: whiteKeyPoints, blackKeyPoints: blackKeyPoints, pianoKeyState: pianoKeyState)
                
            }else {
                ZStack {
                    // 白鍵を描画
                    ForEach(0..<whiteKeyPoints.count, id: \.self) { index in
                        ZStack {
                            // 4つの頂点を使って四角形を描画
                            let path = Path { path in
                                let points = whiteKeyPoints[index]
                                path.move(to: points[0])
                                path.addLine(to: points[1])
                                path.addLine(to: points[2])
                                path.addLine(to: points[3])
                                path.closeSubpath()
                            }
                            
                            path
                                .stroke(Color.blue, lineWidth: 6) // 枠線を青色で描画
                                .background(Color.clear) // 背景をクリアに設定
                                .border(Color.clear)
                                .contentShape(path)
                                .offset(whiteDragOffsets[index])
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            // 各図形のドラッグオフセットを更新
                                            whiteDragOffsets[index] = value.translation
                                        }
                                        .onEnded { _ in
                                            // 終了時にオフセットを更新
                                            for i in 0..<whiteKeyPoints[index].count {
                                                whiteKeyPoints[index][i].x += whiteDragOffsets[index].width
                                                whiteKeyPoints[index][i].y += whiteDragOffsets[index].height
                                            }
                                            whiteDragOffsets[index] = .zero // リセット
                                        }
                                )
                            
                            // 各頂点をドラッグ可能にする
                            ForEach(0..<whiteKeyPoints[index].count, id: \.self) { pointIndex in
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 15, height: 15)
                                    .position(whiteKeyPoints[index][pointIndex])
                                    .gesture(
                                        DragGesture()
                                            .onChanged { value in
                                                whiteKeyPoints[index][pointIndex] = value.location
                                            }
                                    )
                            }
                        }
                    }
                    
                    // 黒鍵を描画
                    ForEach(0..<blackKeyPoints.count, id: \.self) { index in
                        ZStack {
                            // 4つの頂点を使って四角形を描画
                            let path = Path { path in
                                let points = blackKeyPoints[index]
                                path.move(to: points[0])
                                path.addLine(to: points[1])
                                path.addLine(to: points[2])
                                path.addLine(to: points[3])
                                path.closeSubpath()
                            }
                            
                            path
                                .stroke(Color.red, lineWidth: 6)
                                .background(Color.clear) // 背景をクリアに設定
                                .border(Color.clear)
                                .contentShape(path)
                                .offset(blackDragOffsets[index])
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            // 各図形のドラッグオフセットを更新
                                            blackDragOffsets[index] = value.translation
                                        }
                                        .onEnded { _ in
                                            // 終了時にオフセットを更新
                                            for i in 0..<blackKeyPoints[index].count {
                                                blackKeyPoints[index][i].x += blackDragOffsets[index].width
                                                blackKeyPoints[index][i].y += blackDragOffsets[index].height
                                            }
                                            blackDragOffsets[index] = .zero // リセット
                                        }
                                )
                            
                            // 各頂点をドラッグ可能にする
                            ForEach(0..<blackKeyPoints[index].count, id: \.self) { pointIndex in
                                Circle()
                                    .fill(Color.black)
                                    .frame(width: 15, height: 15)
                                    .position(blackKeyPoints[index][pointIndex])
                                    .gesture(
                                        DragGesture()
                                            .onChanged { value in
                                                blackKeyPoints[index][pointIndex] = value.location
                                            }
                                    )
                            }
                        }
                    }
                }
                
            
            // 確定ボタンを追加
            Button(action: {
                confirmKeyPositions()
                isPerforming = true
                count_all = 0
                count_collect = 0
            }) {
                Text("確定")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .offset(x:0, y: -800)
        }
        }
    }
    
    // 鍵盤位置をログに出力
    func confirmKeyPositions() {
        print("白鍵の位置:")
        for (index, points) in whiteKeyPoints.enumerated() {
            print("白鍵 \(index): \(points)")
        }
        
        print("黒鍵の位置:")
        for (index, points) in blackKeyPoints.enumerated() {
            print("黒鍵 \(index): \(points)")
        }
    }
}




class TimerViewModel: ObservableObject {
    static let shared = TimerViewModel()
    @Published var remainingTime: Int = 360 // 初期値は6分（秒単位）
    @Published var isTimerActive: Bool = false
    @Published var showAlert: Bool = false

    private var timer: Timer? = nil
    
    struct MeasuredTimeData {
        let timestamp: TimeInterval       // 記録されたタイムスタンプ
        let selectedNote: UInt8           // 正解の鍵盤
        let responseTime: TimeInterval    // 鍵盤に正解するまでの時間
    }

    private(set) var measuredTimes: [MeasuredTimeData] = [] // 測定データのリスト
    private var lastNoteTimestamp: TimeInterval = Date().timeIntervalSinceReferenceDate // 最初のタイムスタンプ

    func startTimer() {
        isTimerActive = true
        lastNoteTimestamp = Date().timeIntervalSinceReferenceDate // 開始時にタイムスタンプをリセット
        measuredTimes.removeAll() // 古い記録をクリア
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.remainingTime > 0 {
                self.remainingTime -= 1
            } else {
                self.timer?.invalidate()
                self.timer = nil
                self.isTimerActive = false
                self.showAlert = true
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isTimerActive = false
    }

    func recordTimeForNote(selectedNote: UInt8) {
        if isTimerActive {
            let currentTime = Date().timeIntervalSinceReferenceDate
            let responseTime = currentTime - lastNoteTimestamp
            lastNoteTimestamp = currentTime // 現在の時刻を次の計測の基準に設定
            measuredTimes.append(MeasuredTimeData(
                timestamp: currentTime,
                selectedNote: selectedNote,
                responseTime: responseTime
            ))
        }
    }
    
    func saveDataAsCSV() {
        let header = "Timestamp,SelectedNote,ResponseTime\n"
        var csvContent = header
        
        for data in measuredTimes {
            let line = "\(data.timestamp),\(data.selectedNote),\(data.responseTime)\n"
            csvContent += line
        }
        csvContent += "\n"
        csvContent += "弾いた数: \(count_all)\n"
        csvContent += "正解数: \(count_collect)\n"

        
        // ファイル保存
        //let fileName = "MeasuredTimes_camera_1.csv"
        let fileName = "1217test_camera_003.csv"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try csvContent.write(to: path, atomically: true, encoding: .utf8)
            print("CSVファイルを保存しました: \(path)")
        } catch {
            print("CSVファイルの保存に失敗しました: \(error.localizedDescription)")
        }
    }


    var formattedTime: String {
        let minutes = remainingTime / 60
        let seconds = remainingTime % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}



struct PerformanceView: View {
    var whiteKeyPoints: [[CGPoint]]
    var blackKeyPoints: [[CGPoint]]
    
    @ObservedObject var pianoKeyState: PianoKeyState
    @StateObject private var timerViewModel = TimerViewModel.shared
    
    var body: some View {
        ZStack {
            VStack {
                Spacer().frame(height: 20)
                HStack {
                    // タイマー表示
                    
                    
                    // スタートボタン
                    Button(action: {
                        timerViewModel.startTimer()
                        print(timerViewModel.isTimerActive)
                    }) {
                        Text(timerViewModel.isTimerActive ? "タイマー進行中" : "スタート")
                            .font(.title2)
                            .padding()
                            .background(timerViewModel.isTimerActive ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .disabled(timerViewModel.isTimerActive) // タイマー進行中はボタンを無効化
                    
                    Text("残り時間: \(timerViewModel.formattedTime)")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                    
                    Spacer()
                    
                    Button(action: {
                        timerViewModel.saveDataAsCSV()
                    }) {
                        Text("データ保存")
                            .font(.title2)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
                .padding() // 上部にスペースを追加
                
                Spacer() // HStack の下にスペースを追加して上部に配置されるようにする
            }

            
            // 白鍵を固定して描画
            ForEach(0..<whiteKeyPoints.count, id: \.self) { index in
                let path = Path { path in
                    let points = whiteKeyPoints[index]
                    path.move(to: points[0])
                    path.addLine(to: points[1])
                    path.addLine(to: points[2])
                    path.addLine(to: points[3])
                    path.closeSubpath()
                }
                path
                    .stroke(pianoKeyState.whiteKeyColors[index], lineWidth: 6)
            }
            
            // 黒鍵を固定して描画
            ForEach(0..<blackKeyPoints.count, id: \.self) { index in
                let path = Path { path in
                    let points = blackKeyPoints[index]
                    path.move(to: points[0])
                    path.addLine(to: points[1])
                    path.addLine(to: points[2])
                    path.addLine(to: points[3])
                    path.closeSubpath()
                }
                path
                    .stroke(pianoKeyState.blackKeyColors[index], lineWidth: 6)
            }
        }
        .alert(isPresented: $timerViewModel.showAlert) {
            Alert(
                title: Text("タイマー終了"),
                message: Text("演奏を終了してください"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}



extension CGSize {
    func adding(_ other: CGSize) -> CGSize {
        return CGSize(width: self.width + other.width, height: self.height + other.height)
    }
}



class ViewController: NSViewController, MIDIManagerDelegate {
    
    @ObservedObject var pianoKeyState = PianoKeyState()
    @ObservedObject var timerViewModel = TimerViewModel.shared
    
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
    var scoreTextLayer: CATextLayer? // scoreを表示するためのレイヤー
//    var count_all = UInt()
//    var count_collect = UInt()
    var selectedNote: UInt? // 選ばれたノートを保持するプロパティ
    
    
    var X = Int()
    var Y = Int()
    
    var Width = Int()
    var Height = Int()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        CameraManager.shared.startSession(delegate: self)
        canvasView.layer = CALayer()
        
        // ここでプレビュー層の設定を追加
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.frame = camera.bounds
        videoPreviewLayer.videoGravity = .resizeAspectFill
        camera.layer?.addSublayer(videoPreviewLayer)
        
        // ズームの設定
        let zoomScale: CGFloat = 1.2
        videoPreviewLayer.setAffineTransform(CGAffineTransform(scaleX: zoomScale, y: zoomScale))
        
        // SwiftUIの鍵盤ビューをNSHostingViewとしてラップし、camera上に追加
        let pianoKeysView = NSHostingView(rootView: DraggablePianoKeysView(pianoKeyState: pianoKeyState))
        pianoKeysView.frame = canvasView.bounds
        pianoKeysView.layer?.zPosition = 1 // プレビューの上に配置
        canvasView.addSubview(pianoKeysView)
        
        playnote(note: 55)
        
        // MIDIセットアップ
        midi = MIDIManager()
        if 0 < midi!.numberOfSources {
            midi!.connectMIDIClient(0)
            midi!.delegate = self
        }
        
        //    override func viewDidLoad() { //元コード
        //        super.viewDidLoad()
        //        CameraManager.shared.startSession(delegate: self)
        //        canvasView.layer = CALayer()
        //
        //        white_key()
        //        //black_key()
        //        kyaritan()
        //    playnote(note:)
        //        //score()
        //
        //    var midi = MIDIManager()
        //        if 0 < midi!.numberOfSources {
        //            midi!.connectMIDIClient(0)
        //            midi!.delegate = self
        //        }
        //    }
        
    }
    
    
    override var representedObject: Any? {
        didSet {}
    }
    
    //    func frameBlack(playNum : Int){
    //
    //        if playNum < 40 {
    //            X = Num * 55 + 95
    //            print(X)
    //        }else if playNum < 47 {
    //            X = Num * 55 + 150
    //        } else if playNum < 52 {
    //            X = Num * 55 + 205
    //        } else {
    //            X = Num * 55 + 260
    //        }
    //        Width = 70
    //        Height = 150
    //        Y = 460
    //        print(Num,play_no,X,Y,Width,Height)
    //    }
    
    //    func frameWhite(playNum : Int) {
    //        if playNum < 41 {
    //            X = Num * 54 + 108
    //        } else if playNum < 48 {
    //            X = Num * 54 + 108 + 54
    //        } else if playNum < 53 {
    //            X = Num * 54 + 108 + 108
    //        } else{
    //            X = Num * 54 + 108 + 162
    //        }
    //        Width = 50
    //        Height = 560
    //        Y = 50
    //    }
    
    
    
    func noteOn(ch: UInt8, note: UInt8, vel: UInt8, t: UInt8) {
        
        if note == pianoKeyState.selectedNote {
            if timerViewModel.isTimerActive {
                timerViewModel.recordTimeForNote(selectedNote: pianoKeyState.selectedNote!) // 正解時の記録
//                print("正しい鍵盤弾いた\(timerViewModel.recordTimeForNote)")
                
                // 次の正解鍵盤をランダムに設定
                pianoKeyState.selectedNote = UInt8(UInt.random(in: 36...55))
                //print(pianoKeyState.selectedNote)
                pianoKeyState.updateKeyColor(forNote: pianoKeyState.selectedNote!, isNoteOn: false)

                count_collect += 1
            }
        }
        pianoKeyState.updateKeyColor(forNote: note, isNoteOn: true)
        count_all += 1
        score()
    }

    
    func noteOff(ch: UInt8, note: UInt8, vel: UInt8, t: UInt8) {
        pianoKeyState.updateKeyColor(forNote: note, isNoteOn: false)
    }
    
    
    
    func playnote(note: UInt) {
        pianoKeyState.selectedNote = UInt8(UInt.random(in: 36...55))
        pianoKeyState.updateKeyColor(forNote: pianoKeyState.selectedNote!, isNoteOn: false)
        score() //スコア表示の関数
    }
    
    func score() {
        // 既にあるレイヤーを削除してから新しいレイヤーを追加する
        
        if let existingLayer = scoreTextLayer {
            existingLayer.removeFromSuperlayer() // 既存のレイヤーを削除
        }
        
        // 新しいテキストレイヤーを作成
        let textLayer = CATextLayer()
        textLayer.frame = CGRect(x: 800, y: 700, width: 300, height: 100)
        textLayer.string = "弾いた数：\(count_all)\n 正解数：\(count_collect)"
        textLayer.foregroundColor = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
        textLayer.fontSize = 30.0
        textLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 1.0 // Retina対応
        
        // レイヤーを保存しておく
        scoreTextLayer = textLayer
        
        // canvasViewに追加
        canvasView.layer?.addSublayer(textLayer)
    }
    
    
    //    func noteOn(ch: UInt8, note: UInt8, vel: UInt8, t: UInt8) {
    //        on_num = note
    //        count_all = count_all + 1
    //        coloredLayer = createLayer()
    //
    //        if on_num == play_no{
    //            playnote(note: play_no)
    //            count_collect = count_collect + 1
    //            print("onNum:\(Num)")
    //        }
    //        Num = Int(note - 36)
    //        //黒鍵
    //        if note%12 == 1 || note%12 == 3 || note%12 == 6 || note%12 == 8 || note%12 == 10 {
    //            frameBlack(playNum: Int(note))
    //            coloredLayer.frame = CGRect(x: Int(X), y: Y, width: Int(Width), height: Int(Height))
    //            canvasView.layer?.addSublayer(coloredLayer)
    //
    //            if play_no%12 == 1 || play_no%12 == 3 || play_no%12 == 6 || play_no%12 == 8 || play_no%12 == 10 { //黒鍵を弾かせたいとき
    //                white_key()
    //                black_key()
    //                canvasView.layer?.addSublayer(playLayer)
    //                canvasView.layer?.addSublayer(coloredLayer)
    //            } else {
    //                white_key()
    //                canvasView.layer?.addSublayer(playLayer)
    //                black_key()
    //                canvasView.layer?.addSublayer(coloredLayer)
    //            }
    //
    //        } else{
    //            //白鍵
    //            frameWhite(playNum: Int(note))
    //            coloredLayer.frame = CGRect(x: Int(X), y: Y, width: Int(Width), height: Int(Height))
    //
    //            if play_no%12 == 1 || play_no%12 == 3 || play_no%12 == 6 || play_no%12 == 8 || play_no%12 == 10 {
    //                white_key()
    //                canvasView.layer?.addSublayer(coloredLayer)
    //                black_key()
    //                canvasView.layer?.addSublayer(playLayer)
    //            } else {
    //                white_key()
    //                canvasView.layer?.addSublayer(playLayer)
    //                canvasView.layer?.addSublayer(coloredLayer)
    //                black_key()
    //            }
    //        }
    //        print("弾いた数：", count_all, "正答数：", count_collect)
    //        score()
    //
    //    }
    
    //    func noteOff(ch: UInt8, note: UInt8, vel: UInt8, t: UInt8) {
    //        score()
    //        if note == on_num {
    //            //黒鍵
    //            if note%12 == 1 || note%12 == 3 || note%12 == 6 || note%12 == 8 || note%12 == 10 {
    //
    //                if play_no%12 == 1 || play_no%12 == 3 || play_no%12 == 6 || play_no%12 == 8 || play_no%12 == 10 {
    //                    white_key()
    //                    //canvasView.layer?.addSublayer(coloredLayer)
    //                    black_key()
    //                    canvasView.layer?.addSublayer(playLayer)
    //                } else {
    //                    white_key()
    //                    /// canvasView.layer?.addSublayer(coloredLayer)
    //                    canvasView.layer?.addSublayer(playLayer)
    //                    black_key()
    //                }
    //            } else{
    //
    //                //白鍵
    //                if play_no%12 == 1 || play_no%12 == 3 || play_no%12 == 6 || play_no%12 == 8 || play_no%12 == 10 {
    //                    canvasView.layer?.addSublayer(coloredLayer)
    //                    white_key()
    //                    black_key()
    //                    canvasView.layer?.addSublayer(playLayer)
    //                } else {
    //                    canvasView.layer?.addSublayer(coloredLayer)
    //                    white_key()
    //                    canvasView.layer?.addSublayer(playLayer)
    //                    black_key()
    //                }
    //            }
    //            score()
    //        }
    //    }
    
}

//図形の描画
//extension ViewController{
//
//    func createLayer() -> CALayer {
//        let newLayer = CALayer()
//        newLayer.borderWidth = 8
//        newLayer.borderColor = CGColor(red: 0, green: 1, blue: 1, alpha: 0.8)
//        newLayer.anchorPoint = CGPoint(x: 0, y: 0)
//        return newLayer
//    }
//
//    func white_key(){
//        canvasView.layer = CALayer()
//        //白鍵
//        let keypath_w = CGMutablePath()
//        for i in stride(from: 0, to: 1240, by: 108){
//            keypath_w.addRect( CGRect(x: i+108, y: 50, width: 50, height: 560))
//        }
//        //let KeyLayer_w = CAShapeLayer()
//        KeyLayer_w.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
//        KeyLayer_w.path = keypath_w
//        KeyLayer_w.strokeColor = CGColor(red: 255, green: 255, blue: 255, alpha: 0.5)
//        KeyLayer_w.fillColor = CGColor(red: 255, green: 255, blue: 255, alpha: 0.5)
//        canvasView.layer?.addSublayer(KeyLayer_w)
//
//    }
//
//    func black_key() {
//        // canvasView.layer = CALayer()
//        let keypath_b = CGMutablePath()
//        let Y = 460
//        let W = 70
//        let H = 150
//        keypath_b.addRect( CGRect(x: 150, y: Y, width: W, height: H))
//        keypath_b.addRect( CGRect(x: 260, y: Y, width: W, height: H))
//        keypath_b.addRect( CGRect(x: 480, y: Y, width: W, height: H))
//        keypath_b.addRect( CGRect(x: 590, y: Y, width: W, height: H))
//        keypath_b.addRect( CGRect(x: 700, y: Y, width: W, height: H))
//        keypath_b.addRect( CGRect(x: 920, y: Y, width: W, height: H))
//        keypath_b.addRect( CGRect(x: 1030, y: Y, width: W, height: H))
//        keypath_b.addRect( CGRect(x: 1250, y: Y, width: W, height: H))
//
//        //let KeyLayer_b = CAShapeLayer()
//        KeyLayer_b.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
//        KeyLayer_b.path = keypath_b
//        KeyLayer_b.fillColor = CGColor(red: 0, green: 0, blue: 0, alpha: 0.5)
//        canvasView.layer?.addSublayer(KeyLayer_b)
//    }
//
//    func score() {
////        // 既にあるレイヤーを削除してから新しいレイヤーを追加する
////        if let existingLayer = scoreTextLayer {
////            existingLayer.removeFromSuperlayer() // 既存のレイヤーを削除
////        }
////
////        // 新しいテキストレイヤーを作成
////        let textLayer = CATextLayer()
////        textLayer.frame = CGRect(x: 800, y: 700, width: 300, height: 100)
////        textLayer.string = "弾いた数：\(count_all)\n 正解数：\(count_collect)"
////        textLayer.foregroundColor = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
////        textLayer.fontSize = 30.0
////        textLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 1.0 // Retina対応
////
////        // レイヤーを保存しておく
////        scoreTextLayer = textLayer
////
////        // canvasViewに追加
////        canvasView.layer?.addSublayer(textLayer)
////    }
//
//}



class CameraManager:NSObject, AVCaptureVideoDataOutputSampleBufferDelegate{
    private let targetDeviceName = "Brio 500"
    
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
            if device.localizedName == "Brio 500" {
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
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        DispatchQueue.global(qos: .userInitiated).async {
            
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                print("Error: Unable to get image buffer.")
                return
            }
            
            CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
            let ciImage = CIImage(cvPixelBuffer: imageBuffer)
            CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
            
            let context = CIContext()
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
                print("Error: Unable to create CGImage.")
                return
            }
            
            let image = NSImage(cgImage: cgImage, size: NSSize(width: ciImage.extent.width, height: ciImage.extent.height))
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self, let cameraLayer = self.camera.layer else {
                    print("Error: Camera layer not found.")
                    return
                }
                
                // 古いレイヤーを削除
                cameraLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
                
                // 新しいレイヤーを作成
                let subLayer = CALayer()
                subLayer.frame = cameraLayer.bounds // カメラのレイヤーのサイズに合わせる
                subLayer.contents = image
                
                let zoomScale: CGFloat = 1.15 // 1.0 は元のサイズ、1.1 は 10% ズーム
                // ズームを適用
                let scaleTransform = CATransform3DMakeScale(zoomScale, zoomScale, 1.0)
                
                subLayer.transform = CATransform3DConcat(CATransform3DMakeRotation(.pi, 0, 0, 1), scaleTransform)
                
                // アスペクト比を維持して表示
                subLayer.contentsGravity = .resizeAspect
                
                // 新しいレイヤーを追加
                cameraLayer.addSublayer(subLayer)
            }
        }
    }
}

//extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
//
//    //元のやつ
//    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        // 画像処理をバックグラウンドスレッドで実行
//
//
//        DispatchQueue.global(qos: .userInitiated).async {
//
//            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
//                print("Error: Unable to get image buffer.")
//                return
//            }
//
//            CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
//            guard let base = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0) else {
//                print("Error: Unable to get base address.")
//                CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
//                return
//            }
//
//            let bytesPerRow = UInt(CVPixelBufferGetBytesPerRow(imageBuffer))
//            let width = UInt(CVPixelBufferGetWidth(imageBuffer))
//            let height = UInt(CVPixelBufferGetHeight(imageBuffer))
//
//            let colorSpace = CGColorSpaceCreateDeviceRGB()
//            let bitsPerComponent = 8
//            let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue) as UInt32)
//
//            guard let newContext = CGContext(data: base, width: Int(width), height: Int(height), bitsPerComponent: Int(bitsPerComponent), bytesPerRow: Int(bytesPerRow), space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
//                print("Error: Unable to create CGContext.")
//                CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
//                return
//            }
//
//            CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
//
//            guard let imageRef = newContext.makeImage() else {
//                print("Error: Unable to make image from CGContext.")
//                return
//            }
//
//            let image = NSImage(cgImage: imageRef, size: NSSize(width: Int(width), height: Int(height)))
//
//            // NSImage -> Mat に変換
//            let srcMat = Mat(nsImage: image)
//            let mtx = Mat(rows: 3, cols: 3, type: CvType.CV_64F)
//            try! mtx.put(row: 0, col: 0, data: [1.92380473e+03, 0, 1.43588428e+03] as [Float64])
//            try! mtx.put(row: 1, col: 0, data: [0, 1.92926580e+03, 9.02045464e+02] as [Float64])
//            try! mtx.put(row: 2, col: 0, data: [0, 0, 1] as [Float64])
//
//            let distCoeffs = Mat(rows: 1, cols: 5, type: CvType.CV_64F)
//            try! distCoeffs.put(row: 0, col: 0, data: [0.17418398, -0.58908136, -0.00068051, 0.00181742, 0.636665] as [Float64])
//
//            // 歪み補正処理
//            let undistortedMat = Mat()
//            Calib3d.undistort(src: srcMat, dst: undistortedMat, cameraMatrix: mtx, distCoeffs: distCoeffs, newCameraMatrix: mtx)
//
//            // Mat -> NSImageに変換
//            let correctedImage = undistortedMat.toNSImage()
//
//            // メインスレッドでUIを更新
//            DispatchQueue.main.async { [weak self] in
//                guard let self = self, let cameraLayer = self.camera.layer else {
//                    print("Error: Camera layer not found.")
//                    return
//                }
//
//                // 古いレイヤーを削除
//                cameraLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
//
//                // 新しいレイヤーを作成
//                let subLayer = CALayer()
//                subLayer.frame = cameraLayer.bounds // カメラのレイヤーのサイズに合わせる
//                subLayer.contents = correctedImage
//
//                // ズーム倍率を設定
//                let zoomScale: CGFloat = 1.2 // 1.0 は元のサイズ、1.1 は 10% ズーム
//
//                // ズームを適用
//                let scaleTransform = CATransform3DMakeScale(zoomScale, zoomScale, 1.0)
//                subLayer.transform = CATransform3DConcat(CATransform3DMakeRotation(.pi, 0, 0, 1), scaleTransform)
//
//                // スケーリングを適用
//                subLayer.contentsGravity = .resizeAspect // アスペクト比を維持
//
//                // 新しいレイヤーを追加
//                cameraLayer.addSublayer(subLayer)
//            }
//        }
//    }
//
//
//}
