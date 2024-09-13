import SwiftUI
import OpenAI
import Combine

struct Message : Equatable {
    var ID: UUID = .init()
    var content: String
    var isUser: Bool
}

struct ContentView: View {
    @State private var apiKey: String? = nil
    @State var bodyTapped: Bool = false
    @State var inputText: String = ""
    @State private var keyboardHeight: CGFloat = 0 // Adjusts App for when the Keyboard shows upp
    
    @StateObject var chatController = ChatController(apiKey: "YOUR_API_KEY") // Use StateObject to observe changes
    private var cancellable: AnyCancellable?
    
    
    @State var percent = 20.0
    @State var waveOffset = Angle(degrees: 0)
    

    var body: some View {
        ZStack {
            Color(UIColors.background)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring()) {
                        self.bodyTapped = false
                    }
                }
            
            
            Wave(offSet: Angle(degrees: waveOffset.degrees), percent: percent)
                .fill(Color.blue)
                .ignoresSafeArea(.all)
                .onAppear {
                            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                                
                                waveOffset = Angle(degrees: 360)
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

                    VStack() {
                        if self.bodyTapped {
                            ScrollView {
                                ForEach(chatController.messages, id: \.ID) { message in
                                    MessageView(message: message)
                                        
                                        .padding(5)
                                         // Differentiate by color
                                        .cornerRadius(20)
                                        .transition(message.isUser ? .move(edge: .trailing) : .move(edge: .leading))
//                                        
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
                    
                    
                    
                    ZStack {
                        TextEditor(text: $inputText)
                                .padding(.leading, 10)
                                .padding(.top, 10)
                                .padding(.bottom, 10)
                                .padding(.trailing, 40)
                                .background(Color.white)
                                .cornerRadius(self.bodyTapped ? 10 : 20)
                                .frame(width: self.bodyTapped ? 370 : 200, height: self.bodyTapped ? 120 : 40)
                                .foregroundColor(self.bodyTapped ? .black : .clear)
                                .shadow(radius: 5)
                                

                        ZStack {
                            Image(systemName: "arrow.down.message.fill")
                                .resizable()
                                .frame(width: 30, height:30)
                        }
                        .offset(x: self.bodyTapped ? 165 : 70, y: self.bodyTapped ? 40 : 0)
                        .onTapGesture {
                            
                            
                            withAnimation(.spring(response: 0.6, dampingFraction: 1.5)) {
                                chatController.sendNewMessage(content: inputText)
                                inputText = "" // Clear the input field
                            }
                            UIApplication.shared.endEditing()
                        }
                    }
                    .offset(y: self.bodyTapped ? 280 : 30)
                    .disabled(self.bodyTapped ? false : true)
                }
                .padding()
            }
            .padding(.bottom, keyboardHeight)
            
            
            
            Text("Clear Chat") // Clear Button
                .foregroundColor(.white)
                .bold()
                .font(.system(size: 30))
                .offset(x: self.bodyTapped ? 100 : 300, y: -340)
                .onTapGesture {
                    withAnimation(.spring()){
                        chatController.clearMessages()
                    }
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
        .onReceive(Publishers.keyboardHeight) { height in
            withAnimation {
                self.keyboardHeight = height // Update the keyboard height when it changes
            }
        }
    }
}
struct MessageView: View {
    var message: Message
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                Text(message.content)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(Color.white)
                    .cornerRadius(20)
            } else {
                Text(message.content)
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(Color.white)
                    .cornerRadius(20)
                Spacer()
            }
        }
        .padding(5)
        .zIndex(/*@START_MENU_TOKEN@*/1.0/*@END_MENU_TOKEN@*/)
    }
}


// Keyboard height publisher to observe keyboard changes
extension Publishers {
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        let willShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .map { notification -> CGFloat in
                (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
            }
        
        let willHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ -> CGFloat in 0 }
        
        return MergeMany(willShow, willHide)
            .eraseToAnyPublisher()
    }
}
// Keyboard extension for transitioning from no longer typing
extension UIApplication {
    func endEditing() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        windowScene.windows
            .filter { $0.isKeyWindow }
            .first?
            .endEditing(true)
    }
}


#Preview{
    ContentView()
}
