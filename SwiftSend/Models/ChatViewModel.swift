//
//  ChatViewModel.swift
//  SwiftSend
//
//  Created by Brody on 10/27/24.
//


import CallableFunction
import CoreLocation
import Foundation
import Wavelike
import WeatherKit
import SwiftUI

// TODO: Set location for the surfChatModel
// TODO: make Content view attatch to this view model.

func getTodayDateString() -> String {
    let today = Date()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd" // Format to extract only YYYY-MM-DD
    return dateFormatter.string(from: today)
}



@MainActor


@Observable
class SurfChatModel: ObservableObject{
    
    var messageHistory: [Message] = []
    var isLoading: Bool = false
    
    var displayedMessages: [Message] {
        messageHistory
            .filter { [.user, .assistant].contains($0.role) }
    }

    
    //Aquire chatGPT 3.5 from Wavelike
    let chat = Wavelike.model(for: ModelIdentifier(ChatModel.self, id: "brody35"))
    
   
    
    var getSurfFunction = ParseSurfRequest { params in
        
        print("PARAMS: \(params)\n\n\n")
        // Make SurfAPI immutable
        let todaysDate = getTodayDateString()
        let SurfAPI = SurfAPI(latitude: params.latitude, longitude: params.longitude)
        let StormGlassAPI = StormGlassAPI(lat: params.latitude, lng: params.longitude, startDate: todaysDate)
        // Use Task for handling async code
        
        func extractTides(from data: [[String: Any]], tideType: String) -> [(time: String, height: Double)] {
            return data.compactMap { entry in
                if let type = entry["type"] as? String, type == tideType,
                   let time = entry["time"] as? String,
                   let height = entry["height"] as? Double {
                    
                    
                    // Creating substring to obtain the correct date format
                    let heightFt = height * 3.28084 // m -> ft
                    let startIndex = time.index(time.startIndex, offsetBy: 11)
                    let endIndex = time.index(time.startIndex, offsetBy: 16)
                    let substring = String(time[startIndex..<endIndex])
                    
                    return (time: substring, height: heightFt)
                }
                return nil  // If the type doesn't match, or if time/height is missing, return nil
            }
        }
        
        
            do {
                // Fetch the SurfData and aquires API KEy
                if let data = try await SurfAPI.fetchWeatherData(), let stormdata = try await StormGlassAPI.fetchTideData(){
                    // Extract low and high tides from stormdata
                    let lowTides = extractTides(from: stormdata, tideType: "low")
                    let highTides = extractTides(from: stormdata, tideType: "high")
                    
                    // Create the weather response using the fetched data and tide data
                    let surfGet: [String: Any] = [
                        "lowTide1": lowTides.first.map { "\($0.time) - Height: \($0.height)ft" } ?? "No data", // First low tide (time and height)
                        "lowTide2": lowTides.count > 1 ? "\(lowTides[1].time) - Height: \(lowTides[1].height)ft" : "No data", // Second low tide (time and height)
                        "highTide1": highTides.first.map { "\($0.time) - Height: \($0.height)ft" } ?? "No data", // First high tide (time and height)
                        "highTide2": highTides.count > 1 ? "\(highTides[1].time) - Height: \(highTides[1].height)ft" : "No data", // Second high tide (time and height)
                        "location": params.location,
                        "latitude": params.latitude,
                        "longitude": params.longitude,
                        "waveHeightMax": data.daily.waveHeightMax.first ?? "No data",
                        "waveDirectionDominant": data.daily.waveDirectionDominant.first ?? "No data",
                        "wavePeriodMax": data.daily.wavePeriodMax.first ?? "No data",
                        "windWaveHeightMax": data.daily.windWaveHeightMax.first ?? "No data",
                        "windWaveDirectionDominant": data.daily.windWaveDirectionDominant.first ?? "No data",
                        "windWavePeriodMax": data.daily.windWavePeriodMax.first ?? "No data",
                        "windWavePeakPeriodMax": data.daily.windWavePeakPeriodMax.first ?? "No data",
                        "swellWaveHeightMax": data.daily.swellWaveHeightMax.first ?? "No data",
                        "swellWaveDirectionDominant": data.daily.swellWaveDirectionDominant.first ?? "No data",
                        "swellWavePeriodMax": data.daily.swellWavePeriodMax.first ?? "No data",
                        "swellWavePeakPeriodMax": data.daily.swellWavePeakPeriodMax.first ?? "No data"
                    ]
                    
                    
                    if let location = surfGet["location"] as? String,
                       
                        let lowTide1 = surfGet["lowTide1"] as? String,
                       let lowTide2 = surfGet["lowTide2"] as? String,
                       let highTide1 = surfGet["highTide1"] as? String,
                       let highTide2 = surfGet["highTide2"] as? String,
                       
                        
                        let waveHeight = surfGet["waveHeightMax"] as? Float,
                       let waveDirection = surfGet["waveDirectionDominant"] as? Float,
                       let wavePeriod = surfGet["wavePeriodMax"] as? Float,
                       let windWaveHeight = surfGet["windWaveHeightMax"] as? Float,
                       let windWaveDirection = surfGet["windWaveDirectionDominant"] as? Float,
                       let windWavePeriod = surfGet["windWavePeriodMax"] as? Float,
                       let windWavePeakPeriod = surfGet["windWavePeakPeriodMax"] as? Float,
                       let swellWaveHeight = surfGet["swellWaveHeightMax"] as? Float,
                       let swellWaveDirection = surfGet["swellWaveDirectionDominant"] as? Float,
                       let swellWavePeriod = surfGet["swellWavePeriodMax"] as? Float,
                       let swellWavePeakPeriod = surfGet["swellWavePeakPeriodMax"] as? Float {
                        
                        
                        
                        // Ouput Message
                        let surfMessage =
                            """
                            Here are the surf conditions for \(location):
                            - Max Wave Height: \(waveHeight)ft
                            - Wave Direction: \(waveDirection)°
                            - Wave Period: \(wavePeriod)s
                            - Max Wind Wave Height: \(windWaveHeight)ft
                            - Wind Wave Direction: \(windWaveDirection)°
                            - Wind Wave Period: \(windWavePeriod)s
                            - Wind Wave Peak Period: \(windWavePeakPeriod)s
                            - Max Swell Wave Height: \(swellWaveHeight)ft
                            - Swell Wave Direction: \(swellWaveDirection)°
                            - Swell Wave Period: \(swellWavePeriod)s
                            - Swell Wave Peak Period: \(swellWavePeakPeriod)s
                            - Low Tide 1: \(lowTide1) ft
                            - Low Tide 1: \(lowTide2) ft
                            - High Tide 1: \(highTide1) ft
                            - High Tide 2: \(highTide2) ft
                            """
                        
                        var surfString = "\n\n\nSURF FORECAST MESSAGE: \(surfMessage)\n\n\n"
                        print("returnMessage: \(surfString)")
                        print("properly returned surf information\n\n")
                        
                        return surfString
                        
                        
                    }
                } else {
                    // Handle case where no data is returned
                    DispatchQueue.main.async {
                        print("No data available")
                        
                    }
                }
            } catch {
                // Handle error
                DispatchQueue.main.async {
                    print("Unable to fetch weather data: \(error)")

                }
            }

        return ""
    }
    
    func send(message text: String) async {

        var messages: [Message] = []
        
        // Add initial context for date / time and user location
        // TODO: Instead, fetch user location client-side and don't share with llm.
        
        print("sending message\n\n")
        if messageHistory.isEmpty {
            let dateSystemMessage = Message(role: .system, content: "Today's date is: \(Date().formatted(date: .complete, time: .complete))")
            let locationSystemMessage = Message(role: .system, content: "You are an assistant that helps users learn about current Surf conditions provided that the user provides a location of a beach with water. ")
            messages = [dateSystemMessage, locationSystemMessage]
        }

        let userMessage = Message(role: .user, content: text)
        messages.append(userMessage)
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)){
            messageHistory.append(contentsOf: messages)
        }

        isLoading = true
        print("before chatSend")
        let (message, surf) = try! await chat.send(history: messageHistory, functions: getSurfFunction)
        
        
        
        isLoading = false
        
        if message.content != nil {
            print("Called regular chat function")
            withAnimation(.spring(response: 0.3, dampingFraction: 0.9)){
                messageHistory.append(message)
            }
        }

        if let surf {
            print("Called surf function")
            print("Message: \(message)")
            print("SURF: \(surf)")

            guard let lastQuestion = (messageHistory.last { $0.role == .user })?.content else {
                print("⚠️ Could not find user's last question")
                return
            }
            
            let contextualSystemMessage = Message(role: .system, content: "Given this information: \n\n \(surf) \n\n\n\nCan you please tell the user what the surf conditions will be like give \(lastQuestion). Please provide the most important information such as the tides height and the times they will appear, the wave height, and where the wind is coming from.")
            
            
            print("\n\n\n\(contextualSystemMessage.content)")
            

            let dummyFunction = DummyFunction { _ in return "" }

            isLoading = true
            let (message, _) = try! await chat.send(history: [contextualSystemMessage], functions: dummyFunction)
            isLoading = false
            withAnimation(.spring(response: 0.3, dampingFraction: 0.9)){
                messageHistory.append(message)
            }
        }
    }
}


@CallableFunction("No function implemented")
struct DummyFunction {
    struct Parameters: Codable {
        var dummyParam: String
    }

    typealias Output = String
}
