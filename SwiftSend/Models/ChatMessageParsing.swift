//
//  ChatMessageParsing.swift
//  SwiftSend
//
//  Created by Brody on 10/28/24.
//

import Foundation
import CallableFunction



@CallableFunction("Get the surf conditions given a location")
struct ParseSurfRequest {
    struct Parameters: Codable {
        
        @ParameterDescription("The location of the user")
        var location: String
        
        @ParameterDescription("The latitude of the location if it can be inferred from the location.")
        var latitude: Double
        
        @ParameterDescription("The longitude of the location if it can be inferred from the location.   ")
        var longitude: Double
        
    }

    typealias Output = String
}
