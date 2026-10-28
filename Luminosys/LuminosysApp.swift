//
//  LuminosysApp.swift
//  Luminosys
//
//  Created by Oliver Crumrine on 1/14/24.
//

import SwiftUI
import AVFoundation

@main
struct LuminosysApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

}

class LuxProcessor : NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, ObservableObject{
    @Published var luminosityReading: Double = 0.0
    var session: AVCaptureSession!;
    var videoInput: AVCaptureDeviceInput!;
    var configureAVCaptureSessionQueue = DispatchQueue(label: "ConfigureAVCaptureSessionQueue")
    var changeCameraQueue = DispatchQueue(label: "ChangeCameraQueue");
    var selectedCamera: Cameras = .Back;
    var setupComplete: Bool = false;
    @Published var cameraAuthorized = true;
    @Published var attemptedToAuthorize = false;
    @Published var showAlert = false;
    @Published var paper = false;
    override init(){
        super.init();
        authorizeCap();
    }
    func showPaperAlert(){
        paper = true;
    }
    func authorizeCap(){
        switch(AVCaptureDevice.authorizationStatus(for: .video)){
        case .authorized:
            DispatchQueue.main.async{
                self.cameraAuthorized = true;
            }
            configureAVCaptureSessionQueue.async{
                self.initCameraShiz()
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video){ (granted) in
                
                if granted{
                    DispatchQueue.main.async{
                        self.cameraAuthorized = true;
                    }
                    self.configureAVCaptureSessionQueue.async{
                        self.initCameraShiz()
                    }
                }else{
                    DispatchQueue.main.async{
                        self.cameraAuthorized = false;
                    }
                }
            }
        default:
            cameraAuthorized = false;
        }
        if(!cameraAuthorized && !attemptedToAuthorize){
            showAlert = true;
        }
    }
    func initCameraShiz(){
            session = AVCaptureSession()
            session.beginConfiguration()
            
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {return}
            
            do {
                videoInput = try AVCaptureDeviceInput(device: videoDevice)
                if session.canAddInput(videoInput) {
                    session.addInput(videoInput)
                }
            } catch {
                return
            }
            
            let videoOutput = AVCaptureVideoDataOutput()
            guard
                session.canAddOutput(videoOutput)
            else {
                return
            }
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "CaptureOutputQueue"))
            session.addOutput(videoOutput)
            
            session.sessionPreset = .medium
            session.commitConfiguration()
            session.startRunning()
        setupComplete = true;
    }
    func cameraChange(){
        if(videoInput != nil){
            if(setupComplete == false){
                changeCameraQueue.async{
                    while(!self.setupComplete){}
                }
            }
            let videoDevice: AVCaptureDevice!;
            if(selectedCamera == .Back){
                videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back);
            }else{
                videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front);
            }
            session.beginConfiguration()
            session.removeInput(videoInput);
            do {
                videoInput = try AVCaptureDeviceInput(device: videoDevice)
                if session.canAddInput(videoInput) {
                    session.addInput(videoInput)
                }
            } catch {
                return
            }
            session.commitConfiguration()
        }
        
        
    }
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let rawMetadata = CMCopyDictionaryOfAttachments(allocator: nil, target: sampleBuffer, attachmentMode: CMAttachmentMode(kCMAttachmentMode_ShouldPropagate))
        let metadata = CFDictionaryCreateMutableCopy(nil, 0, rawMetadata) as NSMutableDictionary
        let exifData = metadata.value(forKey: "{Exif}") as? NSMutableDictionary
        
        let brightness = exifData?["BrightnessValue"] as! Double;
        
        let FNumber : Double = exifData?["FNumber"] as! Double
        let ExposureTime : Double = exifData?["ExposureTime"] as! Double
        let ISOSpeedRatingsArray = exifData!["ISOSpeedRatings"] as? NSArray
        let ISOSpeedRatings : Double = ISOSpeedRatingsArray![0] as! Double
        let CalibrationConstant : Double = 50
        
        let luminosityUnder75 : Double = (CalibrationConstant * FNumber * FNumber ) / ( ExposureTime * ISOSpeedRatings )
        
        let luminosity = pow(3.565, brightness) + 360 * brightness - 700;
        print("\(brightness),\(luminosityUnder75)");
        DispatchQueue.main.async{
            if(luminosity < 14 || luminosity.isNaN){
                self.luminosityReading = luminosityUnder75
            }else{
                self.luminosityReading = luminosity
            }
        }
         
    }
    
}

class InitData: ObservableObject{
    @Published var camDenied: Bool;
    @Published var camError: Bool;
    @Published var camAllowed: Bool;
    @Published var camDisplayAlert: Bool;
    @Published var firstReinit: Bool;
    init(camDenied: Bool, camError: Bool, camAllowed: Bool, camDisplayAlert: Bool, firstReinit: Bool) {
        self.camDenied = camDenied;
        self.camError = camError;
        self.camAllowed = camAllowed;
        self.camDisplayAlert = camDisplayAlert;
        self.firstReinit = firstReinit;
    }
}

