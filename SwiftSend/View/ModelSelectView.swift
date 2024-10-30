//
//  ModelSelectView.swift
//  SwiftSend
//
//  Created by Brody on 10/30/24.
//

import SwiftUI



struct ModelSelectView: View {
    
    @ObservedObject var viewModel: SurfChatModel
    @State private var selectedModel = ""
    @State private var testList = ["brody35","brody4o","metallama","Cohere llm", "somehuggingFace"]
    var body: some View {
        ZStack{
            Rectangle()
                .frame(width: 260, height: 170)
                .foregroundColor(UIColors.background)
                .cornerRadius(20)
            
                .overlay(content: {
                    
                    ZStack{
                        Form{
                            Picker("select Model", selection: $selectedModel){
                                ForEach(testList, id: \.self){ model in
                                    Text(model)
                                    
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 260, height: 80)
                        }
                        .scrollDisabled(true)
                        .scrollContentBackground(.hidden)
                        .cornerRadius(20)
                        
                    }
                })
            Text("Current selection: \(viewModel.selectedModel)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .padding(.top, 100)
            
            
        }
        .onChange(of: selectedModel){
            print("new picking value")
            viewModel.selectedModel = selectedModel
        }
        .onAppear{
            selectedModel = viewModel.selectedModel ?? "brody35"
        }
        
    }
}

#Preview {
    var currentModel = SurfChatModel()
    ModelSelectView(viewModel: currentModel)
}
