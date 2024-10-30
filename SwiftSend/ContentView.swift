import SwiftUI
import OpenAI
import Combine
import Wavelike


@Observable
class CurrentModel: ObservableObject{
    var model = "brody35"
}



struct ContentView: View {
    @State private var apiKey: String? = nil
    @State var bodyTapped: Bool = false
    @State var inputText: String = ""
    
    @State var showSettingBarView: Bool = false
    
    // Adjusts App for when the Keyboard shows upp
    @State private var keyboardHeight: CGFloat = 0
    // Use StateObject to change the key via onAppear in ContentView

    @StateObject private var viewModel = SurfChatModel()
    
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
            
            VStack{
                HStack{
                    ZStack{
                        Button(action: {
                            print("chose model")
                            print("TEST")
                            
                                showSettingBarView.toggle()
                            
                        }) {
                            SettingsViewButton()
                                
                        }
                    }
                    .padding(.leading, 30)
                    .opacity(self.bodyTapped ? 0 : 1 )
                    Spacer()
                    Spacer()
                }
                Spacer()
                Spacer()
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
                            ScrollViewReader { scrollProxy in
                                ScrollView {
                                    
                                    // display messages.
                                    ForEach(viewModel.displayedMessages, id: \.self){ message in
                                        HStack{
                                            if let content = message.content{
                                                if message.role == .user{
                                                    Spacer()
                                                }
                                                Text(content)
                                                    .padding(15)
                                                    .background(message.role == .user ? Color.blue : Color.gray)
                                                    .foregroundColor(Color.white)
                                                    .cornerRadius(20)
                                                    
                                                if message.role != .user{
                                                    Spacer()
                                                }
                                            }
                                        }
                                        .padding()
                                        .transition(message.role == .user ? .move(edge: .trailing) : .move(edge: .leading))
                                        Spacer().frame(height: 20)
                                        
                                            
                                                
                                        
                                    }

                                    if viewModel.isLoading {
                                        ProgressView()
                                    }
                                    Color.clear
                                        .frame(height: 1)
                                        .id("Bottom")
                                    
                                }
                                .onChange(of: viewModel.displayedMessages.count) { _ in
                                    // Scroll to the invisible view at the bottom
                                    print("Changed")
                                    withAnimation {
                                        scrollProxy.scrollTo("Bottom")
                                    }
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
                                //send message
                                
                                Task {
                                    print("sending message")
                                    await viewModel.send(message: inputText)
                                    inputText = ""
                                }
    
                                
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
                        //Clear message
                        viewModel.messageHistory = []
                    }
                }
            
            
            
            
            if showSettingBarView{
                SettingBarView(showSettingBarView: $showSettingBarView, viewModel: viewModel)
                    .animation(.easeInOut(duration: 0.5), value: showSettingBarView)
                    
                    
            }
            
            
            
            
            
            
            
            
        }
        .onReceive(Publishers.keyboardHeight) { height in
            withAnimation {
                self.keyboardHeight = height // Update the keyboard height when it changes
            }
        }
        
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
