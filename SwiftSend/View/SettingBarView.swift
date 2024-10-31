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
    @State private var dragOffset = CGSize.zero
    var body: some View {
    
            VStack{
                ZStack{
                    UIColors.body.ignoresSafeArea()
                    
                    
                }
                .frame(height: 200)
                    .cornerRadius(20)
                    .overlay{
                        ZStack{
                            
                            
                            HStack{
                                Text("Model Select:")
                                    .rotationEffect(Angle(degrees: 270))
                                    .foregroundColor(Color.black)
                                    .font(.system(size: 19))
                                    .bold()
                                
                                Spacer(minLength: 10)
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
