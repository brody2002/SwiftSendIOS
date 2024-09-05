import SwiftUI
import Wavelike
import OpenAI

class ChatController: ObservableObject {
    @Published var openAI: OpenAI?
    @Published var messages: [Message] = []
    
    init(apiKey: String) {
        self.openAI = OpenAI(apiToken: apiKey)
    }
    
    func sendNewMessage(content: String) {
        let userMessage = Message(content: content, isUser: true)
        self.messages.append(userMessage)
        getBotReply()
    }
    
    func getBotReply() {
        let query = ChatQuery(
            
            messages: self.messages.map({
                .init(role: .user, content: $0.content)!
            }),
            model: .gpt4_o
        )
        
        
        openAI?.chats(query: query) { result in
            switch result {
            case .success(let success):
                guard let choice = success.choices.first else {
                    return
                }
                guard let message = choice.message.content?.string else { return }
                DispatchQueue.main.async {
                    self.messages.append(Message(content: message, isUser: false))
                }
            case .failure(let failure):
                print(failure)
            }
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
                        .opacity(0.4)
                        .cornerRadius(20)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                self.bodyTapped.toggle()
                            }
                        }
                    
                    VStack(alignment: .leading) {
                        if self.bodyTapped{
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
                    .background(Color(UIColors.body).opacity(0.9))
                    .cornerRadius(20)
                    .offset(y: self.bodyTapped ? -65 : 0)
                    .onTapGesture {
                        withAnimation(.spring()) {
                            self.bodyTapped.toggle()
                        }
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
                            Rectangle()
                                .cornerRadius(4)
                                .foregroundColor(Color(red: 183/255, green: 222/255, blue: 255/255))
                                .frame(width: 30, height: 30)
                            
                            Text("->")
                                .foregroundColor(.red)
                                .font(.system(size: 24, weight: .bold))
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
                        .cornerRadius(10)
                }
            } else {
                HStack {
                    Text(message.content)
                        .padding()
                        .background(Color.gray) // Bot message is gray
                        .foregroundColor(Color.white)
                        .cornerRadius(10)
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

