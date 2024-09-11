//
//  ChatController.swift
//  SwiftSend
//
//  Created by Brody on 9/9/24.
//

import Foundation
import SwiftUI
import OpenAI


// Define the FunctionDeclaration and JSONSchema structures
struct FunctionDeclaration {
    let name: String
    let description: String
    let parameters: JSONSchema
}

// Define the JSONSchema to match the expected structure
struct JSONSchema: Codable {
    let type: String
    let properties: [String: JSONSchemaProperty]
    let required: [String]
}

// JSONSchemaProperty defines each property in the schema
struct JSONSchemaProperty: Codable {
    let type: String
    let description: String?
    let enumValues: [String]?
}


extension FunctionDeclaration {
    func toToolParam() -> ChatQuery.ChatCompletionToolParam {
        
        
        
        //IMPORTANT
        // Map JSONSchema to ChatCompletionToolParam.FunctionDefinition.FunctionParameters
        let functionParameters = ChatQuery.ChatCompletionToolParam.FunctionDefinition.FunctionParameters(
            type: .object, // Mapping your JSONSchema.type to the corresponding enum type
            properties: self.parameters.properties.mapValues { property in
                return ChatQuery.ChatCompletionToolParam.FunctionDefinition.FunctionParameters.Property(
                    type: .init(rawValue: property.type) ?? .string, // Defaulting to .string
                    description: property.description,
                    enum: property.enumValues
                )
            },
            required: self.parameters.required
        )

        // Return the tool param with the mapped function parameters
        return ChatQuery.ChatCompletionToolParam(
            function: .init(
                name: self.name,
                description: self.description,
                parameters: functionParameters
            )
        )
    }
}


class ChatController: ObservableObject {
    @Published var openAI: OpenAI?
    @Published var messages: [Message] = []
    
    
    
    //LMM FUNCTIONS:
    
    
    func clearMessages() {
            messages.removeAll()
        }
    
    
    func getWeather(for location: String, unit: String? = "fahrenheit", completion: @escaping ([String: Any]) -> Void) {
        print("Called getWeather()")
        // Default to "celsius" if unit is nil
        let providedUnit = unit?.lowercased() ?? "fahrenheit"
        
        // Validate the unit:
        let validUnits = ["celsius", "fahrenheit"]
        let finalUnit = validUnits.contains(providedUnit) ? providedUnit : "celsius"
        
        // Create a structured weather response (as if retrieved from a real API)
        let weatherResponse: [String: Any] = [
            "location": location,
            "temperature": 25,
            "unit": finalUnit
        ]
    
        completion(weatherResponse)
    }
    
    func getSurf(for location: String, coordinates: String, completion: @escaping ([String: Any]) -> Void) {
        // Default coordinates in case of invalid input
        print("getSurf CALLED")
        let defaultCoordinates = "1002.33,33"
        var validCoordinates = coordinates
        
        // Split the coordinates string by comma
        let components = coordinates.split(separator: ",").map { String($0) }
        
        // Validate that we have exactly 2 components and they can be converted to Double
        if components.count != 2 || components.contains(where: { Double($0) == nil }) {
            // If invalid, use default coordinates
            validCoordinates = defaultCoordinates
        }
        
        // Create the weather response
        let weatherResponse: [String: Any] = [
            "coordinates": validCoordinates,
            "location": location,
            "waveHeight" : "3ft waves"
        ]
        
        // Call the completion handler with the weather response
        completion(weatherResponse)
    }





    
    
    
    
    // --------------------------

    init(apiKey: String) {
        self.openAI = OpenAI(apiToken: apiKey)
    }

    func sendNewMessage(content: String) {
        let userMessage = Message(content: content, isUser: true)
        self.messages.append(userMessage)
        getBotReply()
    }

    func getBotReply() {
        // Map `Message` to `ChatCompletionMessageParam`
        let chatPrompt = "Say pikachu after every sentence"
        let userMessages = self.messages.compactMap { message -> ChatQuery.ChatCompletionMessageParam? in
            return ChatQuery.ChatCompletionMessageParam(
                role: message.isUser ? .user : .assistant,
                content: message.content
            )
        }

        // Add the system message at the beginning
        if let systemMessage = ChatQuery.ChatCompletionMessageParam(
            role: .system,
            content: chatPrompt
        ) {
            // Combine system message with user and bot messages
            let allMessages = [systemMessage] + userMessages

            // Example function declaration
            let functions = [
                FunctionDeclaration(
                    name: "get_current_weather",
                    description: "Get the current weather in a given location",
                    parameters: JSONSchema(
                        type: "object",
                        //Inputs (some are optional)
                        properties: [
                            "location": JSONSchemaProperty(
                                type: "string",
                                description: "The city and state, e.g., San Francisco, CA",
                                enumValues: nil
                            ),
                            "unit": JSONSchemaProperty(
                                type: "string",
                                description: "The temperature unit to use",
                                enumValues: ["celsius", "fahrenheit"]
                            )
                        ],
                        required: ["location"]
                    )
                ),
                
                
                
                FunctionDeclaration(
                    name: "get_surf_conditions",
                    description: "Get the surf condition of a given the location",
                    parameters: JSONSchema(
                        type: "object",
                        //Inputs (some are optional)
                        properties: [
                            "location": JSONSchemaProperty(
                                type: "string",
                                description: "The city and state, e.g., San Francisco, CA",
                                enumValues: nil
                            )
                            
                        ],
                        required: ["location"]
                    )
                )
            ]

            // Map the functions to tool params
            let toolParams = functions.map { $0.toToolParam() }

            let query = ChatQuery(
                messages: allMessages,
                model: "gpt-4",
                tools: toolParams // Pass the tool parameters here
            )

            // Send the query to OpenAI
            openAI?.chats(query: query) { result in
                switch result {
                case .success(let success):
                    guard let choice = success.choices.first else {
                        return
                    }

                    // if assistant  message
                    if case let .assistant(assistantMessage) = choice.message {
                        // Check if it involves a function call
                        if let toolCalls = assistantMessage.toolCalls, let toolCall = toolCalls.first {
                            
                            // Extract the function call details
                            let functionName = toolCall.function.name
                            let functionArgs = toolCall.function.arguments

                            // Handle the specific function calls
                            if functionName == "get_current_weather" {
                                // Parse the arguments from JSON
                                    if let data = functionArgs.data(using: .utf8),
                                       let json = try? JSONSerialization.jsonObject(with: data, options: []),
                                       let argsDict = json as? [String: Any],
                                       let location = argsDict["location"] as? String {
                                        
                                        let unit = argsDict["unit"] as? String
                                        
                                        // Call weather function
                                        self.getWeather(for: location, unit: unit) { weatherResponse in
                                            // Extract data from the weatherResponse dictionary
                                            if let location = weatherResponse["location"] as? String,
                                               let temperature = weatherResponse["temperature"] as? Int,
                                               let unit = weatherResponse["unit"] as? String {
                                                
                                                // Format the message string
                                                let weatherMessage = "The current temperature in \(location) is \(temperature) degrees \(unit)."
                                                
                                                // Unwrap both system message and assistant message before using them in the array
                                                if let followUpSystemMessage = ChatQuery.ChatCompletionMessageParam(
                                                        role: .system,
                                                        content: chatPrompt
                                                    ),
                                                   let assistantMessageParam = ChatQuery.ChatCompletionMessageParam(
                                                        role: .assistant,
                                                        content: weatherMessage
                                                    ) {
                                                    
                                                    // Adds back the system instruction
                                                    let followUpQuery = ChatQuery(
                                                        messages: [
                                                            followUpSystemMessage,  // Unwrapped system message
                                                            assistantMessageParam   // Unwrapped assistant message
                                                        ],
                                                        model: "gpt-4"
                                                    )
                                                    
                                                    self.openAI?.chats(query: followUpQuery) { followUpResult in
                                                        switch followUpResult {
                                                        case .success(let followUpSuccess):
                                                            if let followUpChoice = followUpSuccess.choices.first {
                                                                // Safely unwrap the content to make sure it's non-optional before using it
                                                                if let content = followUpChoice.message.content, case let .string(messageContent) = content {
                                                                    // Handle the string content
                                                                    DispatchQueue.main.async {
                                                                        self.messages.append(Message(content: messageContent, isUser: false))
                                                                    }
                                                                } else {
                                                                    // Handle the case where content is nil (optional)
                                                                    DispatchQueue.main.async {
                                                                        self.messages.append(Message(content: "No content available", isUser: false))
                                                                    }
                                                                }
                                                            }
                                                        case .failure(let followUpFailure):
                                                            print(followUpFailure)
                                                        }
                                                    }
                                                }
                                        } else {
                                            // Handle the case where the dictionary doesn't contain expected values
                                            print("unhandled function call")
//                                            DispatchQueue.main.async {
//                                                self.messages.append(Message(content: "Failed to retrieve weather data.", isUser: false))
//                                            }
                                        }
                                    }
                                }
                            } 
                            if functionName == "get_surf_conditions"{
                                // Parse the arguments from JSON
                                if let data = functionArgs.data(using: .utf8),
                                   let json = try? JSONSerialization.jsonObject(with: data, options: []),
                                   let argsDict = json as? [String: Any],
                                   let location = argsDict["location"] as? String {
                                    
                                    
                                    let coordinates = argsDict["coordinates"] as? String
                                   
                                    //Call weather function
                                    self.getSurf(for: location, coordinates: coordinates ?? "100, 300") { surfGet in
                                        // Extract data from the weatherResponse dictionary
                                        if let location = surfGet["location"] as? String,
                                           let waveHeight = surfGet["waveHeight"] as? String {

                                            // Format the message string
                                            let weatherMessage = "The current surf conditions in \(location) with a wave height of \(waveHeight)."

                                            // Unwrap both system message and assistant message before using them in the array
                                            if let followUpSystemMessage = ChatQuery.ChatCompletionMessageParam(
                                                    role: .system,
                                                    content: chatPrompt
                                                ),
                                               let assistantMessageParam = ChatQuery.ChatCompletionMessageParam(
                                                    role: .assistant,
                                                    content: weatherMessage
                                                ) {
                                                
                                                // Adds back the system instruction
                                                let followUpQuery = ChatQuery(
                                                    messages: [
                                                        followUpSystemMessage,  // Unwrapped system message
                                                        assistantMessageParam   // Unwrapped assistant message
                                                    ],
                                                    model: "gpt-4"
                                                )

                                                self.openAI?.chats(query: followUpQuery) { followUpResult in
                                                    switch followUpResult {
                                                    case .success(let followUpSuccess):
                                                        if let followUpChoice = followUpSuccess.choices.first {
                                                            // Safely unwrap the content to make sure it's non-optional before using it
                                                            if let content = followUpChoice.message.content, case let .string(messageContent) = content {
                                                                            // Handle the string content
                                                                            DispatchQueue.main.async {
                                                                                self.messages.append(Message(content: messageContent, isUser: false))
                                                                            }
                                                            } else {
                                                                // Handle the case where content is nil (optional)
                                                                DispatchQueue.main.async {
                                                                    self.messages.append(Message(content: "No content available", isUser: false))
                                                                }
                                                            }
                                                        }
                                                    case .failure(let followUpFailure):
                                                        print(followUpFailure)
                                                    }
                                                }
                                            }
                                        } else {
                                            // Handle the case where the dictionary doesn't contain expected values
                                            DispatchQueue.main.async {
                                                self.messages.append(Message(content: "Failed to retrieve surf data.", isUser: false))
                                            }
                                        }
                                    }
                                }
                                
                            }else {
                                // If it's a different function call, handle it here (add custom logic)
                                print("Unhandled function call: \(functionName)")
//                                DispatchQueue.main.async {
//                                    self.messages.append(Message(content: "Function call for \(functionName) not handled.", isUser: false))
//                                }
                            }
                        } else if let content = assistantMessage.content {
                            // Handle regular assistant message (fallback if no function call or content available)
                            DispatchQueue.main.async {
                                self.messages.append(Message(content: content, isUser: false))
                            }
                        }
                    }

                case .failure(let failure):
                    print(failure)
                }
            }
        } else {
            print("Failed to create system message")
        }
    }

}
