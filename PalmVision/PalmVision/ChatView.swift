//
//  ChatView.swift
//  PalmVision
//
//  Created by Katelyn Fritz on 10/22/23.
//
import Foundation
import SwiftUI

struct Location: Decodable, Identifiable {
    let id: Int
    let longitude: Double
    let latitude: Double
}

struct LocationsContainer: Decodable {
    let lastMentionedLocations: [Location]
}

struct ChatView: View {
    @ObservedObject var imagesModel: ImageViewModel
    @State private var userInput: String = ""
    @State private var messages: [Message] = []
    @State private var isMapPresented = false
    @State var lastLocationContainer: LocationsContainer = LocationsContainer(lastMentionedLocations: [])
    
    func visitLocations(locationsContainer: LocationsContainer?) -> String {
        if locationsContainer == nil {
            return ""
        }
        print("visiting locations \(locationsContainer?.lastMentionedLocations)")
        lastLocationContainer = locationsContainer!
        return "locations have been visited"
    }
    
    var body: some View {
        VStack {
            ScrollViewReader { scrollView in
                ScrollView {
                    ForEach(messages.indices, id: \.self) { index in
                        let message = messages[index]
                        if message.role == .user {
                            UserMessageView(text: message.text)
                                .id(index)
                        } else if message.role == .assistant {
                            if message.functionName == nil {
                                AssistantMessageView(text: message.text) .id(index)
                            }
                        } else if message.role == .function {
                            AssistantMessageView(text: "Generating plan. Please wait... ") .id(index)
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
            
            
            VStack {
                HStack {
                    Button("Update map") {
                        sendMessageModifiedPrompt()
                    }
                    .padding()
                    
                    Button(action: { isMapPresented = true }) {
                        Text("Show map")
                    }
                    .padding()
                    .sheet(isPresented: $isMapPresented) {
                       MapView(imagesModel: ImageViewModel(),
                               overwriteLocations: lastLocationContainer)
                    }
                    
 
                    Button("Send") {
                        sendMessage()
                    }
                    .padding()
                }
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
            }
        }
    }
    
    func sendMessage() {
        let userMessage = Message(text: userInput, role: .user, functionName: nil, functionCall: nil)
        messages.append(userMessage)
        
        // Call the API
        fetchGPT3Response(for: userInput, withFunction: false) { response in
            let assistantMessage = Message(text: response, role: .assistant, functionName: nil, functionCall: nil)
            messages.append(assistantMessage)
        }
        
        userInput = ""
    }
    func sendMessageModifiedPrompt() {
        let modifiedPrompt = "\(userInput) Call function with the name visit_locations with only the locations included in the recently mentioned locations. Locations ordering must be preserved."
        let userMessage = Message(text: modifiedPrompt, role: .user, functionName: nil, functionCall: nil)
        messages.append(userMessage)
        
        // Call the API
        fetchGPT3Response(for: userInput, withFunction: true) { response in
            let assistantMessage = Message(text: response, role: .assistant, functionName: nil, functionCall: nil)
            messages.append(assistantMessage)
        }
        
        userInput = ""
    }
     
    func sendFunctionMessage(text: String,
                             functionName: String,
                             functionCall: FunctionCall) {
        messages.append(Message(text: text,
                                role: .function,
                                functionName: functionName,
                                functionCall: nil))
        // Call the API
        fetchGPT3Response(for: text, withFunction: true) { response in
            let assistantMessage = Message(text: response, role: .assistant, functionName: nil, functionCall: nil)
            messages.append(assistantMessage)
        }
        
        userInput = ""
    }
     
    func toJsonString(dictionary: [String:Any]) -> String {
        if let jsonData = try? JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted) {
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
                return jsonString
            } else {
                print("Failed to convert data to string.")
            }
        } else {
            print("Failed to serialize dictionary.")
        }
        return "{}"
    }
    
    func getImageAnalysisModelPrompt() -> String {
        var text = ""
        for index in imagesModel.attachments.indices {
            let attachment = imagesModel.attachments[index]
            let healthy = attachment.imageAnalysis.objectCounts[.healthy]
            let nitrogen = attachment.imageAnalysis.objectCounts[.nitrogen]
            let ganoderma = attachment.imageAnalysis.objectCounts[.ganoderma]
            let trees = attachment.imageAnalysis.treeCountsText
            text += "location \(index+1), latitude \(attachment.imageLocationLat), longitude \(attachment.imageLocationLon) with \(nitrogen) trees lack of nitrogen, \(healthy) healthy trees, and \(ganoderma) trees has ganoderma. "
        }
        return text
    }
    
    func fetchGPT3Response(for text: String, withFunction: Bool, completion: @escaping (String) -> Void) {
        let apiUrl = "https://api.openai.com/v1/chat/completions" // replace with appropriate endpoint
        guard let url = URL(string: apiUrl) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer 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", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let functions: [[String: Any]] = [
            [
                "name": "visit_locations",
                "description": "A function which visits gps locations",
                "parameters": [
                    "type": "object",
                    "properties": [
                        "lastMentionedLocations": [
                            "type": "array",
                            "description": "the gps locations from the last mentioned locations by the assistant",
                            "items": [
                                "type": "object",
                                "properties": [
                                    "id": ["type": "number", "description": "ordered id, the lower the number the higher the priority"],
                                    "longitude": ["type": "number", "description": "longitude"],
                                    "latitude": ["type": "number", "description": "latitude"]
                                ]
                            ]
                        ]
                    ],
                    "required": ["lastMentionedLocations"]
                ],
            ]
        ]
        
        var allMessages: [[String: Any]] = [
            [
                "role": "system",
                "content": "You are a agriculture expert in the area of palm oil, skilled to explain palm oil disseases, and fertilizer. If you mentioned any locations, call function with the name visit_locations only with the last locations you mentioned."
            ],
            [ "role": "user",
              "content": "I have trees with initial gps locations as follow: \(getImageAnalysisModelPrompt())"
              //location 1: latitude 1.0 and longitude 1.0 with 78 trees lack of nitrogen and 10 trees healthy, location 2: latitude 2.0 and longitude 2.0 with 18 trees lack of nitrogen and 20 trees healthy, location 3: latitude 3.0 and longitude 3.0 with 98 trees lack of nitrogen and 20 trees healthy"
            ]
        ]
        for m in messages {
            if m.role == .assistant && m.functionCall == nil {
               allMessages.append(
                    [
                        "role": m.role.rawValue,
                        "content": m.text
                    ])
                  
            } else if m.role == .assistant && m.functionCall != nil {
               allMessages.append(
                    [
                        "role": m.role.rawValue,
                        "function_call": [
                            "name": m.functionCall!.name,
                            "arguments": m.functionCall!.arguments],
                        "content": ""
                    ])
                  
            } else if m.role == .function {
                allMessages.append(
                    [
                        "role": m.role.rawValue,
                        "name": m.functionName!,
                        "content": m.text
                    ])
                 
            } else if m.role == .user {
                allMessages.append(
                    [
                        "role": m.role.rawValue,
                        "content": m.text
                    ])
            }
        }
        
        var body: [String: Any] = [:]
        
        if withFunction {
            body = [
                "model": "gpt-3.5-turbo",
                "messages": allMessages,
                "functions": functions,
                "function_call": "auto"
            ]
        } else {
            body = [
                "model": "gpt-3.5-turbo",
                "messages": allMessages,
            ]
        }
        print("Body to be sent to ChatGPT")
        print(body)
        print("---")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("Error encoding data: \(error.localizedDescription)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else { return }
            
            do {
                var functionArgs: String = ""
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = jsonResponse["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any] {
                    if let function_call = message["function_call"] as? [String: Any] {
                        var locationContainers: LocationsContainer?
                        if let function_args = function_call["arguments"] as? String {
                            functionArgs = function_args
                            // Convert the JSON string to Data
                            if let jsonData = function_args.data(using: .utf8) {
                                let decoder = JSONDecoder()
                                do {
                                    // Decode the JSON data
                                    locationContainers = try decoder.decode(LocationsContainer.self, from: jsonData)
                                } catch {
                                    print("Error decoding JSON: \(error)")
                                }
                            } else {
                                print("Invalid JSON string")
                            }
                        }
                        let functionName: String = function_call["name"] as! String
                        messages.append(Message(text: "",
                                                role: .assistant,
                                                functionName: functionName,
                                                functionCall: FunctionCall(name: functionName,
                                                                           arguments: functionArgs)))
                        if functionName == "visit_locations" {
                            let result = visitLocations(locationsContainer: locationContainers)
                            sendFunctionMessage(text: result,
                                                functionName: functionName,
                                                functionCall: FunctionCall(name: functionName,
                                                                           arguments: functionArgs))
                        }
                    }
                    else if let content = message["content"] as? String {
                        DispatchQueue.main.async {
                            completion(content)
                        }
                    }
                }
            } catch {
                print("Error decoding data: \(error.localizedDescription)")
            }
        }.resume()
    }
}

enum Role: String {
    case user = "user"
    case assistant = "assistant"
    case function = "function"
}
struct FunctionCall: Hashable {
    let name: String
    let arguments: String
}
struct Message: Hashable {
    let text: String
    let role: Role
    let functionName: String?
    let functionCall: FunctionCall?
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

//#Preview {
    //ChatView()
//}


