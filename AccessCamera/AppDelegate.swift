//
//  AppDelegate.swift
//  AccessCamera
//
//  Created by Otowa Joho on 2023/10/19.
//

import Cocoa
import CoreMIDI
import os.log
import Foundation
import AVFoundation
import Dispatch

@main
class AppDelegate: NSObject, NSApplicationDelegate {



    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    

}

protocol MIDIManagerDelegate {
    func noteOn(ch: UInt8, note: UInt8, vel: UInt8, t:UInt8)
    //UInt:符号なし整数値
    func noteOff(ch: UInt8, note: UInt8, vel: UInt8, t:UInt8)
    
    func playnote(note: UInt)
}

class MIDIManager {
  
    var numberOfSources = 0
    var sourceName = [String]()
    var delegate: MIDIManagerDelegate?
    
    let audioEngine = AVAudioEngine()
    let unitSampler = AVAudioUnitSampler()

    

    init() {
       
        findMIDISources()
        audioEngine.attach(unitSampler)
        audioEngine.connect(unitSampler, to: audioEngine.mainMixerNode, format: nil)
        //try? audioEngine.start()
        
        if let _ = try? audioEngine.start(){
            loadSoundFont()
        }
    }
    
    deinit{
        if audioEngine.isRunning{
            audioEngine.stop()
            audioEngine.disconnectNodeOutput(unitSampler)
            audioEngine.detach(unitSampler)
        }
    }
    
    func loadSoundFont() {
        let url = URL(fileURLWithPath: "/Users/otowajoho/Library/Audio/Sounds/Banks/SGM-V2.01.sf2")
//           guard let url = Bundle.main.url(forResource: "DMG-CPU1.5", withExtension: "sf2") else { fatalError("ファイルが見つからない")}let fileURL = URL(fileURLWithPath: "/tmp/tmpFile.txt")
           try? unitSampler.loadSoundBankInstrument(
               at: url, program: 33,
               bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
               bankLSB: 0
           )
       }

//    func play(){
//        unitSampler.startNote(60, withVelocity: 80, onChannel: 0)
//    }
//    func stop(){
//        unitSampler.stopNote(60, onChannel: 0)
//    }
//MIDIデバイスの一覧を取得
    func findMIDISources() {
        sourceName.removeAll()
        numberOfSources = MIDIGetNumberOfSources()
        os_log("%i Device(s) found", numberOfSources)

        for i in 0 ..< numberOfSources {
            let src = MIDIGetSource(i)
            var cfStr: Unmanaged<CFString>?
            let err = MIDIObjectGetStringProperty(src, kMIDIPropertyName, &cfStr)
            if err == noErr {
                if let str = cfStr?.takeRetainedValue() as String? {
                    sourceName.append(str)
                    os_log("Device #%i: %s", i, str)
                }
            }
        }
    }
    
// MIDIClientを作成
    func connectMIDIClient(_ index: Int) {
        if 0 <= index && index < sourceName.count {
            // Create MIDI Client
            let name = NSString(string: sourceName[index])
            var client = MIDIClientRef()
            var err = MIDIClientCreateWithBlock(name, &client, onMIDIStatusChanged)
            if err != noErr {
                os_log(.error, "Failed to create client")
                return
            }
            os_log("MIDIClient created")

// MIDI Input Portを作成
            let portName = NSString("inputPort")
            var port = MIDIPortRef()
            err = MIDIInputPortCreateWithBlock(client, portName, &port, onMIDIMessageReceived)
            if err != noErr {
                os_log("Failed to create input port")
                return
            }
            os_log("MIDIInputPort created")

// Connect MIDIEndpoint to MIDIInputPort
            let src = MIDIGetSource(index)
            err = MIDIPortConnectSource(port, src, nil)
            if err != noErr {
                os_log("Failed to connect MIDIEndpoint")
                return
            }
            os_log("MIDIEndpoint connected to InputPort")
        }
    }
    
// MIDIメッセージの処理
    func onMIDIStatusChanged(message: UnsafePointer<MIDINotification>) {
        os_log("MIDI Status changed!")
    }

    func onMIDIMessageReceived(message: UnsafePointer<MIDIPacketList>, srcConnRefCon: UnsafeMutableRawPointer?) {

        let packetList: MIDIPacketList = message.pointee
        let n = packetList.numPackets
        //os_log("%i MIDI Message(s) Received", n)

        var packet = packetList.packet
        for _ in 0 ..< n {
            // Handle MIDIPacket
            let mes: UInt8 = packet.data.0 & 0xF0
            let ch: UInt8 = packet.data.0 & 0x0F
            if mes == 0x90 && packet.data.2 != 0 {
                // Note On
                
                os_log("Note ON")
                let noteNo = packet.data.1
                let velocity = packet.data.2
                let time = packet.data.3
                
                print("noteNo:", noteNo, "velocity:", velocity, "time",time)
                //unitSampler.sendProgramChange(33, bankMSB: 0x79, bankLSB: 0, onChannel: 0)
               // unitSampler.loadSoundBankInstrument(at: , program: 32, bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB), bankLSB: 0)
                
                unitSampler.startNote(noteNo, withVelocity: velocity, onChannel: 0)
                
                DispatchQueue.main.async {
                    self.delegate?.noteOn(ch: ch, note: noteNo, vel: velocity, t:time)
                }
            } else if (mes == 0x80 || mes == 0x90) {
                // Note Off
                os_log("Note OFF")
                let noteNo = packet.data.1
                let velocity = packet.data.2
                let time = packet.data.3
                
                print("noteNo:", noteNo, "velocity:", velocity, "time",time)
                unitSampler.stopNote(noteNo, onChannel: 0)
                
                DispatchQueue.main.async {
                    self.delegate?.noteOff(ch: ch, note: noteNo, vel: velocity, t:time)
                }
            }
            let packetPtr = MIDIPacketNext(&packet)
            packet = packetPtr.pointee
        }
    }
}

