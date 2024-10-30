//
//  SettingBarView.swift
//  SwiftSend
//
//  Created by Brody on 10/30/24.
//

import SwiftUI

struct SettingBarView: View {
    @Binding var showSettingBarView: Bool
    @State var backButtonPressed: Bool = false
    @ObservedObject var viewModel: SurfChatModel
    var body: some View {
        VStack{
            ZStack{
                UIColors.body.ignoresSafeArea()
                
                
            }
            .frame(height: 200)
                .cornerRadius(20)
                .overlay{
                    ZStack{
                        Button(action: {
                            withAnimation{
                                backButtonPressed = true
                                
                               
                                
                                      showSettingBarView.toggle()
                                  
                                  
                              

                                                              
                                
                            }
                            
                        } ,label: {
                            ZStack{
                                Rectangle()
                                    .fill(UIColors.background)
                                    .frame(width: 30, height: 30)
                                    .cornerRadius(4)
                                Image(systemName: "lessthan")
                                    .foregroundColor(Color.black)
                                    .font(.system(size: 30))
                                    
                                    
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .padding(.leading, 40)
                            .padding(.top, 30)
                            
                        })
                        
                        HStack{
                            
                            Spacer(minLength: 120)
                            ModelSelectView(viewModel: viewModel)
                            Spacer()
                                
                        }
                    }
                }
                    
                
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    var viewModel = SurfChatModel()
    SettingBarView(showSettingBarView: .constant(true), viewModel: viewModel)
}
