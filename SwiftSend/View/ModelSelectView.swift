//
//  ModelSelectView.swift
//  SwiftSend
//
//  Created by Brody on 10/30/24.
//

import SwiftUI



struct ModelSelectView: View {
    
    @ObservedObject var viewModel: SurfChatModel
    @State private var selectedVisualModel = "ChatGPT 4.0"
    @State private var modelNameList: [String: String] = ["ChatGPT 4.0": "chatgpt40", "ChatGPT 3.5": "chatgpt35", "Mixtral 4.67B": "mixtral46b"]

    var body: some View {
        ZStack{
            Rectangle()
                .frame(width: 260, height: 170)
                .foregroundColor(UIColors.background)
                .cornerRadius(20)
            
                .overlay(content: {
                    
                    ZStack{
                        Form{
                            Picker("select Model", selection: $selectedVisualModel){
                                ForEach(modelNameList.keys.sorted(), id: \.self){ model in
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
//            Text("Current selection: \(viewModel.selectedModel)")
//                                            .font(.caption)
//                                            .foregroundColor(.gray)
//                                            .padding(.top, 100)
            
            
        }
        .onChange(of: selectedVisualModel){
            print("new picking value")
            viewModel.selectedModel = selectedVisualModel
        }
        .onAppear{
            selectedVisualModel = viewModel.selectedModel ?? "chatgpt40"
        }
        
    }
}

#Preview {
    var currentModel = SurfChatModel()
    ModelSelectView(viewModel: currentModel)
}
