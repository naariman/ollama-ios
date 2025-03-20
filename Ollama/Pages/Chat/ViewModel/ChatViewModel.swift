//
//  ChatViewModel.swift
//  LocaLLM
//
//  Created by rbkusser on 17.02.2025.
//

import SwiftUI

class ChatViewModel: ObservableObject, ChatNetworkProtocol {

    @Published var message: String = ""
    @Published var messages: [ChatMessage] = []

    private var chatNetworkService = ChatNetworkService()
    private var chatLocalStorageService = ChatLocalStorageService()
    private var modelSettings = ModelService()

    private var urlString: String?
    private var requestData: ChatRequest

    init() {
        urlString = modelSettings.chatUrl
        requestData = ChatRequest(model: modelSettings.modelName ?? "", messages: [], stream: true)
        chatNetworkService.delegate = self
    }

    func didTapSendMessage() {
        guard let urlString else { return }

        Task { @MainActor in
            let userMessage = ChatMessage(role: .user, content: message)
            requestData.messages.append(userMessage)
            messages.append(userMessage)

            message.removeAll()

            let assistantMessage = ChatMessage(role: .assistant, content: "")
            requestData.messages.append(assistantMessage)
            messages.append(assistantMessage)

            do {
                try await chatNetworkService.sendMessage(requestData: requestData, urlString: urlString)
            } catch {
                print("Error: \(error)")
            }
        }
    }
}

extension ChatViewModel: ChatNetworkServiceDelegate {

    func didAnswerWith(word: String, done: Bool) {
        Task { @MainActor in
            self.messages[self.messages.count - 1].content += word
        }

        if messages.count > 3 {
            if done {
                Task {
                    do {
                        try await chatNetworkService.title(
                            requestData: requestData,
                            urlString: urlString ?? ""
                        )
                    } catch {
                        print("Failed to get title: \(error)")
                    }
                }
            }
        }
    }

    func didMake(title: String) {
        
    }
}
