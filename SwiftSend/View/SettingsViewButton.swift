//
//  SettingsView.swift
//  SwiftSend
//
//  Created by Brody on 10/30/24.
//

import SwiftUI

struct SettingsViewButton: View {
    var body: some View {
        VStack{
            Capsule()
                .frame(width: 40, height: 6)
                .foregroundColor(UIColors.body)
            Spacer()
            Capsule()
                .frame(width: 40, height: 6)
                .foregroundColor(UIColors.body)
        }
        .frame(height: 20)
        
    }
}

#Preview {
    SettingsViewButton()
}
