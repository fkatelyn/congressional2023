//
//  ChatView.swift
//  PalmVision
//
//  Created by Katelyn Fritz on 10/22/23.
//
import SwiftUI

struct ChatView: View {
    @State private var userInput: String = ""
    @State private var messages: [Message] = []
    
    var body: some View {
        VStack {
            ScrollViewReader { scrollView in
                ScrollView {
                    ForEach(messages.indices, id: \.self) { index in
                        let message = messages[index]
                        if message.isFromUser {
                            UserMessageView(text: message.text)
                                .id(index)
                        } else {
                            AssistantMessageView(text: message.text)
                                .id(index)
                        }
                    }
                }
                .onChange(of: messages.count) { _ in
                    // Scroll to the latest message when the number of messages changes
                    withAnimation {
                        scrollView.scrollTo(messages.count - 1)
                    }
                }
            }
            
            
            HStack {
                TextField("Enter your message...",
                          text: $userInput,
                          onCommit: {
                    if !userInput.isEmpty {
                        sendMessage()
                        DispatchQueue.main.async {
                            self.userInput = ""
                        }
                    }
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                Button("Send") {
                    sendMessage()
                }
                .padding()
            }
        }
    }
    
    func sendMessage() {
        let userMessage = Message(text: userInput, isFromUser: true)
        messages.append(userMessage)
        
        // Call the API
        fetchGPT3Response(for: userInput) { response in
            let assistantMessage = Message(text: response, isFromUser: false)
            messages.append(assistantMessage)
        }
        
        userInput = ""
    }
    
    func fetchGPT3Response(for text: String, completion: @escaping (String) -> Void) {
        let apiUrl = "https://api.openai.com/v1/chat/completions" // replace with appropriate endpoint
        guard let url = URL(string: apiUrl) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer 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", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var allMessages: [[String: Any]] = [
            [
                "role": "system",
                "content": "You are a agriculture expert in the area of palm oil, skilled to explain palm oil disseases, and fertilizer."
            ]]
        for m in messages {
            allMessages.append(
                [
                    "role": m.isFromUser ? "user" : "assistant",
                    "content": m.text
                ])
        }
        
        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": allMessages
        ]
        
        print(body)
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("Error encoding data: \(error.localizedDescription)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else { return }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = jsonResponse["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    DispatchQueue.main.async {
                        completion(content)
                    }
                }
            } catch {
                print("Error decoding data: \(error.localizedDescription)")
            }
        }.resume()
    }
}

struct Message: Hashable {
    let text: String
    let isFromUser: Bool
}

struct UserMessageView: View {
    let text: String
    
    var body: some View {
        HStack {
            Text(text)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            Spacer()
        }
        .padding()
    }
}

struct AssistantMessageView: View {
    let text: String
    
    var body: some View {
        HStack {
            Spacer()
            Text(text)
                .padding()
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .padding()
    }
}

#Preview {
    ChatView()
}


