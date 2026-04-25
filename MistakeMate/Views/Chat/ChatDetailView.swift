import SwiftData
import SwiftUI

struct ChatDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let session: ChatSession

    @Query private var messages: [ChatMessage]
    @State private var inputText = ""
    @State private var selectedImage: UIImage?
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var showPhotoPicker = false
    @State private var showImagePreview = false
    @State private var showPromptLibrary = false

    @FocusState private var isFieldFocused: Bool

    init(session: ChatSession) {
        self.session = session
        let id = session.persistentModelID
        _messages = Query(
            filter: #Predicate<ChatMessage> { $0.session?.persistentModelID == id },
            sort: \ChatMessage.createdAt
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            messageList
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
                    .padding(.top, 4)
            }
            inputBar
        }
        .navigationTitle(session.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showPromptLibrary.toggle()
                } label: {
                    Image(systemName: "text.badge.plus")
                }
            }
        }
        .sheet(isPresented: $showPromptLibrary) {
            PromptLibraryView { template in
                inputText = template
                isFieldFocused = true
                showPromptLibrary = false
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPicker(image: $selectedImage)
        }
        .onChange(of: selectedImage) { _, image in
            if image != nil {
                showImagePreview = true
            }
        }
        .onAppear {
            scrollToLatest = true
        }
    }

    @State private var scrollToLatest = false

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    if messages.isEmpty {
                        ContentUnavailableView(
                            "开始对话",
                            systemImage: "message",
                            description: Text("和 AI 讨论错题、上传题目图片、请教知识点。")
                        )
                        .padding(.top, 80)
                    }

                    ForEach(messages) { message in
                        ChatBubble(message: message)
                            .id(message.id)
                    }

                    if isSending {
                        HStack {
                            ChatLoadingBubble()
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }

                    Color.clear.frame(height: 1).id("bottom")
                }
            }
            .onChange(of: messages.count) { _, _ in
                withAnimation {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
            .onChange(of: isSending) { _, sending in
                if sending {
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
            .onAppear {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
        .background(Color(.systemGroupedBackground))
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            if showImagePreview, let image = selectedImage {
                HStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    Button {
                        selectedImage = nil
                        showImagePreview = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                Divider()
            }

            HStack(alignment: .bottom, spacing: 8) {
                Button {
                    showPhotoPicker = true
                } label: {
                    Image(systemName: "photo.badge.plus")
                        .font(.title3)
                }
                .disabled(isSending)

                TextField("输入消息...", text: $inputText, axis: .vertical)
                    .focused($isFieldFocused)
                    .lineLimit(1...5)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .disabled(isSending)

                if !inputText.isEmpty || selectedImage != nil {
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color(hex: "#5A5A40") ?? .brown)
                    }
                    .disabled(isSending)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.regularMaterial)
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty || selectedImage != nil else { return }

        var imageData: Data?
        if let img = selectedImage {
            imageData = ImageProcessor.compress(img)
        }

        let userMsg = ChatMessage(
            role: "user",
            content: text,
            session: session,
            imageData: imageData
        )
        modelContext.insert(userMsg)
        inputText = ""
        selectedImage = nil
        showImagePreview = false
        isSending = true
        errorMessage = nil

        let historySnapshot = messages.map { msg in
            ChatHistorySnapshot(role: msg.role, content: msg.content, imageData: msg.imageData, audioData: msg.audioData)
        }

        try? modelContext.save()

        Task {
            do {
                let reply = try await GeminiService.shared.chat(
                    message: text,
                    history: historySnapshot + [ChatHistorySnapshot(role: "user", content: text, imageData: imageData, audioData: nil)],
                    imageData: imageData
                )

                await MainActor.run {
                    let assistantMsg = ChatMessage(
                        role: "assistant",
                        content: reply,
                        session: session
                    )
                    modelContext.insert(assistantMsg)
                    session.updatedAt = Date()
                    try? modelContext.save()

                    // Auto-generate title after first exchange
                    if messages.count <= 1 {
                        generateTitle(firstUserMessage: text)
                    }

                    isSending = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSending = false
                }
            }
        }
    }

    private func generateTitle(firstUserMessage: String) {
        Task {
            do {
                let title = try await GeminiService.shared.generateContent(
                    prompt: "用10个字以内概括这段对话的主题，只返回标题本身：\(firstUserMessage)"
                )
                await MainActor.run {
                    let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
                    if !cleaned.isEmpty {
                        session.title = cleaned
                        try? modelContext.save()
                    }
                }
            } catch { }
        }
    }
}

// MARK: - ChatBubble

private struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top) {
            if message.role == "assistant" {
                VStack(alignment: .leading, spacing: 4) {
                    MarkdownWebView(markdown: message.content)
                        .frame(minHeight: 20)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .background(Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.leading, 12)

                if let imgData = message.imageData, let uiImage = UIImage(data: imgData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.leading, 12)
                }

                Spacer(minLength: 60)
            } else {
                Spacer(minLength: 60)

                VStack(alignment: .trailing, spacing: 4) {
                    if let imgData = message.imageData, let uiImage = UIImage(data: imgData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    if !message.content.isEmpty {
                        Text(message.content)
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(Color(hex: "#5A5A40") ?? .brown)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(.trailing, 12)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ChatLoadingBubble: View {
    var body: some View {
        HStack(spacing: 4) {
            Circle().frame(width: 8, height: 8)
            Circle().frame(width: 8, height: 8)
            Circle().frame(width: 8, height: 8)
        }
        .foregroundStyle(.secondary)
        .padding(12)
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.leading, 12)
    }
}
