//
//  ContentView.swift
//  PJTLauren
//
//  Created by Synn on 5/4/24.
//

import SwiftUI

struct ContentView: View {
    @State private var inputNumber: String = ""
    @State private var koreanNumber: String = ""
    @State private var showingCameraView = false

    var body: some View {
        NavigationView {
            VStack {
                TextField("숫자를 입력하세요", text: $inputNumber)
                                    .padding()
                                    .frame(width:200, height: 200)
                                    .keyboardType(.numberPad)
                                    .onChange(of: inputNumber) { newValue in
                                        // 숫자만 입력 받도록 필터링하고, 16자리로 제한
                                        let filtered = newValue.filter { "0123456789".contains($0) }
                                        if filtered.count <= 16 {
                                            inputNumber = filtered
                                            if let number = Int(filtered) {
                                                koreanNumber = numberToKorean(number)
                                            }
                                        } else {
                                            // 입력 값이 16자리를 초과하면 마지막 유효 숫자로 되돌림
                                            inputNumber = String(filtered.prefix(16))
                                        }
                                    }
                                
                
                Text(" \(koreanNumber)")
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 200)
                    .background(Color.black)
                    .border(Color.blue)
                    .edgesIgnoringSafeArea(.all)
                
                Button(action: {
                    self.showingCameraView = true
                }) {
                    Text("카메라로 인식")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            .padding()
            .sheet(isPresented: $showingCameraView) {
                CameraView(recognizedText: $koreanNumber)
            }
        }
    }
}

#Preview {
    ContentView()
}
