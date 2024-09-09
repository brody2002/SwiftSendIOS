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
    
    func getWeather(for location: String, unit: String? = "fahrenheit", completion: @escaping ([String: Any]) -> Void) {
        // Default to "celsius" if unit is nil
        let providedUnit = unit?.lowercased() ?? "fahrenheit"
        
        // Validate the unit:
        let validUnits = ["celsius", "fahrenheit"]
        let finalUnit = validUnits.contains(providedUnit) ? providedUnit : "celsius"
        
        // Create a structured weather response (as if retrieved from a real API)
        let weatherResponse: [String: Any] = [
            "location": location,
            "temperature": 25, // Replace with real data if available
            "unit": finalUnit
        ]
    
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
        let userMessages = self.messages.compactMap { message -> ChatQuery.ChatCompletionMessageParam? in
            return ChatQuery.ChatCompletionMessageParam(
                role: message.isUser ? .user : .assistant,
                content: message.content
            )
        }

        // Add the system message at the beginning
        if let systemMessage = ChatQuery.ChatCompletionMessageParam(
            role: .system,
            content: "Say pikachu after every sentence"
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

                    // Check if this is an assistant message
                    if case let .assistant(assistantMessage) = choice.message {
                        // Check if it involves a function call
                        if let toolCalls = assistantMessage.toolCalls, let toolCall = toolCalls.first {
                            // Extract the function call details
                            let functionName = toolCall.function.name
                            let functionArgs = toolCall.function.arguments

                            // Handle the specific function call (e.g., "get_current_weather")
                            if functionName == "get_current_weather" {
                                // Parse the arguments from JSON
                                if let data = functionArgs.data(using: .utf8),
                                   let json = try? JSONSerialization.jsonObject(with: data, options: []),
                                   let argsDict = json as? [String: Any],
                                   let location = argsDict["location"] as? String {
                                    
                                    // Correctly extract the unit as a String
                                    let unit = argsDict["unit"] as? String
                                    
                                    // Call the pseudo weather function
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
                                                    content: "Say pikachu after every sentence"
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
                                                self.messages.append(Message(content: "Failed to retrieve weather data.", isUser: false))
                                            }
                                        }
                                    }
                                }
                            } else {
                                // If it's a different function call, handle it here (add custom logic)
                                print("Unhandled function call: \(functionName)")
                                DispatchQueue.main.async {
                                    self.messages.append(Message(content: "Function call for \(functionName) not handled.", isUser: false))
                                }
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

struct Message {
    var ID: UUID = .init()
    var content: String
    var isUser: Bool
}

struct ContentView: View {
    @State private var apiKey: String? = nil
    @State var bodyTapped: Bool = false
    @State var inputText: String = ""
    @State private var isLoading: Bool = false

    @StateObject var chatController = ChatController(apiKey: "YOUR_API_KEY") // Use StateObject to observe changes

    var body: some View {
        ZStack {
            Color(UIColors.background)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring()) {
                        self.bodyTapped = false
                    }
                }

            VStack {
                Text("SwiftSend")
                    .foregroundColor(.white)
                    .font(.system(size: 50))
                    .offset(y: self.bodyTapped ? -500 : -200)
                    .bold()

                ZStack {
                    // Main Rectangle
                    Rectangle()
                        .frame(width: self.bodyTapped ? 370 : 200, height: self.bodyTapped ? 680 : 100)
                        .foregroundColor(UIColors.body)
                        .cornerRadius(20)

                    VStack(alignment: .leading) {
                        if self.bodyTapped {
                            ScrollView {
                                ForEach(chatController.messages, id: \.ID) { message in // Access messages through instance
                                    MessageView(message: message)
                                        .padding(5)
                                }
                            }
                            Divider()
                        }
                    }
                    .frame(width: self.bodyTapped ? 360 : 190, height: self.bodyTapped ? 540 : 90)
                    .background(Color(UIColors.body))
                    .cornerRadius(20)
                    .offset(y: self.bodyTapped ? -65 : 0)
                    .onTapGesture {
                        withAnimation(.spring()) {
                            self.bodyTapped = true
                        }
                        UIApplication.shared.endEditing() // Dismiss keyboard when tapping outside
                    }

                    if isLoading {
                        ProgressView()
                            .padding()
                    }

                    ZStack {
                        TextEditor(text: $inputText)
                            .padding(.leading, 10)
                            .padding(.top, 10)
                            .padding(.bottom, 10)
                            .padding(.trailing, 40)
                            .background(Color.white)
                            .cornerRadius(self.bodyTapped ? 10 : 20)
                            .frame(width: self.bodyTapped ? 370 : 200, height: self.bodyTapped ? 120 : 40)
                            .foregroundColor(.black)
                            .shadow(radius: 5)

                        ZStack {
                            Image(systemName: "arrow.down.message.fill")
                                .resizable()
                                .frame(width: 30, height:30)
                        }
                        .offset(x: self.bodyTapped ? 165 : 70, y: self.bodyTapped ? 40 : 0)
                        .onTapGesture {
                            chatController.sendNewMessage(content: inputText)
                            inputText = "" // Clear the input field
                        }
                    }
                    .offset(y: self.bodyTapped ? 280 : 30)
                }
                .padding()
            }
        }
        .onAppear {
            Env.load()
            // Safely load API key when the view appears
            if let key = Env.get("OPENAI_API_KEY") {
                apiKey = key
                chatController.openAI = OpenAI(apiToken: key) // Set the OpenAI instance
            } else {
                print("API Key not found")
            }
        }
    }
}

struct MessageView: View {
    var message: Message
    var body: some View {
        Group {
            if message.isUser {
                HStack {
                    Spacer()
                    Text(message.content)
                        .padding()
                        .background(Color.blue) // User message is blue
                        .foregroundColor(Color.white)
                        .cornerRadius(20)
                }
            } else {
                HStack {
                    Text(message.content)
                        .padding()
                        .background(Color.gray) // Bot message is gray
                        .foregroundColor(Color.white)
                        .cornerRadius(20)
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

extension UIApplication {
    func endEditing() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        windowScene.windows
            .filter { $0.isKeyWindow }
            .first?
            .endEditing(true)
    }
}

