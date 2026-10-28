//
//  ContentView.swift
//  Luminosys
//
//  Created by Oliver Crumrine on 1/14/24.
//

import SwiftUI
import AVFoundation

enum MeasurementTypes: String, CaseIterable, Identifiable{
    case Lux, FC;
    var id: Self {self};
}
enum Cameras: String, CaseIterable, Identifiable{
    case Front, Back;
    var id: Self {self};
}
extension Cameras: Equatable {}

struct ContentView: View {
    @Environment(\.scenePhase) var scenePhase
    @StateObject var meter = LuxProcessor();
    @State private var selectedUnit: MeasurementTypes = .Lux
    @State private var selectedCamera: Cameras = .Front
    @State var paper = false;

    
    var body: some View {

        VStack {
                HStack {
                    Spacer()
                    
                }
            Spacer()
            if(selectedUnit == .Lux){
                Gauge(value: min(max(meter.luminosityReading, 1), 2000), in: 0...2000){
                    Text("Lux");
                }currentValueLabel: {
                    if(meter.cameraAuthorized){
                        Text(meter.luminosityReading.rounded().formatted());
                    }else{
                        Text("--");
                    }
                }
                .gaugeStyle(LuxGaugeStyle())
                .padding()
            }else{
                Gauge(value: min(max((meter.luminosityReading/10.764), 0), (2000 / 10.764)), in: 0...(2000/10.764)){
                    Text("FC");
                }currentValueLabel: {
                    if(meter.cameraAuthorized){
                        Text(max((meter.luminosityReading/10.764), 1).rounded().formatted());
                    }else{
                        Text("--");
                    }
                }
                .gaugeStyle(FCGaugeStyle())
                .padding()
            }
            VStack{
                Text("Unit")
                    .bold()
                    .font(.system(size: 19, design: .rounded))
                    .padding(.top)
                HStack{
                    Picker("Units", selection: $selectedUnit) {
                        ForEach(MeasurementTypes.allCases) { MeasurementType in
                            Text(MeasurementType.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding([.leading, .trailing])
                }
                Text("Camera")
                    .bold()
                    .font(.system(size: 19, design: .rounded))
                HStack{
                    Picker("Camera", selection: $selectedCamera){
                        ForEach(Cameras.allCases) { Camera in
                            Text(Camera.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedCamera) { _ in
                        meter.selectedCamera = selectedCamera;
                        meter.cameraChange();
                    }
                }.padding([.leading, .trailing, .bottom])
            }.overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.blue, lineWidth: 5)
            )
            Spacer()
        }.padding()
            .alert("Paper Required",
                   isPresented: $meter.paper,
                   actions: {
                       Button("OK") {}
                Button("More Info") {
                    UIApplication.shared.open(URL(string: "https://sites.google.com/view/luminosys/paper-instructions")!, options: [:], completionHandler: nil)
                }
                   },
                   message: {
                      Text("For accurate readings, place a piece of paper over the camera you intend to use");
                   }
            )
            .alert(isPresented: $meter.showAlert){
                Alert(
                    title: Text("Authorization Required"),
                    message: Text("Luminosys needs to access the camera. This is necessary to display ambient light data."),
                    primaryButton: .default(Text("Settings")) {
                        meter.attemptedToAuthorize = true;
                        meter.showAlert = false;
                        UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                    },
                    secondaryButton: .default(Text("OK")){
                        meter.attemptedToAuthorize = true;
                        meter.showAlert = false;
                    }
                )
            }
        
            .onAppear(perform: ){
                meter.showPaperAlert()
                meter.authorizeCap();
            }
    }
    
}

struct LuxGaugeStyle: GaugeStyle {
    private var purpleGradient = LinearGradient(gradient: Gradient(colors: [ Color(red: 249/255, green: 215/255, blue:74/255), Color(red: 59/255, green: 144/255, blue: 229/255) ]), startPoint: .trailing, endPoint: .leading)
    private var darkGradient = LinearGradient(gradient: Gradient(colors: [ Color(hue: 48 / 360, saturation: 70.3 / 100, brightness: 55 / 100, opacity: 75 / 100), Color(hue: 210 / 360, saturation: 73.6 / 100, brightness: 30 / 100, opacity: 75 / 100) ]), startPoint: .trailing, endPoint: .leading)
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            
            
            Circle()
                .trim(from: 0, to: 0.765)
                .stroke(darkGradient, style: StrokeStyle(lineWidth: 35, lineCap: .round))
                .rotationEffect(.degrees(135-2.7))
            
            
            
            Circle()
                .trim(from: 0, to: 0.75 * configuration.value)
                .stroke(purpleGradient, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .rotationEffect(.degrees(135))
            
            
            VStack {
                configuration.currentValueLabel
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundStyle(.blue)
                Text("Lux")
                    .font(.system(.body, design: .rounded))
                    .bold()
                    .foregroundColor(.gray)
            }
            
        }
        .frame(width: 300, height: 300)
        
    }
    
}
struct FCGaugeStyle: GaugeStyle {
    private var purpleGradient = LinearGradient(gradient: Gradient(colors: [ Color(red: 249/255, green: 215/255, blue:74/255), Color(red: 59/255, green: 144/255, blue: 229/255) ]), startPoint: .trailing, endPoint: .leading)
    private var darkGradient = LinearGradient(gradient: Gradient(colors: [ Color(hue: 48 / 360, saturation: 70.3 / 100, brightness: 55 / 100, opacity: 75 / 100), Color(hue: 210 / 360, saturation: 73.6 / 100, brightness: 30 / 100, opacity: 75 / 100) ]), startPoint: .trailing, endPoint: .leading)
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            
            
            Circle()
                .trim(from: 0, to: 0.765)
                .stroke(darkGradient, style: StrokeStyle(lineWidth: 35, lineCap: .round))
                .rotationEffect(.degrees(135-2.7))
            
            
            
            Circle()
                .trim(from: 0, to: 0.75 * configuration.value)
                .stroke(purpleGradient, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .rotationEffect(.degrees(135))
            
            
            VStack {
                configuration.currentValueLabel
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundStyle(.blue)
                Text("FC")
                    .font(.system(.body, design: .rounded))
                    .bold()
                    .foregroundColor(.gray)
            }
            
        }
        .frame(width: 300, height: 300)
        
    }
    
}





