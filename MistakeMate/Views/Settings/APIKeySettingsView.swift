import SwiftUI

struct APIKeySettingsView: View {
    @State private var apiKeyInput = ""
    @State private var isTesting = false
    @State private var hasSavedKey = false
    @State private var alertMessage: String?
    @State private var showAlert = false
    @FocusState private var isFieldFocused: Bool
    @AppStorage("gemini_model") private var selectedModel = "gemini-2.0-flash"

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("API Key 将安全存储在设备 Keychain 中，仅用于调用 Gemini API。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Section("模型") {
                TextField("输入模型名称", text: $selectedModel)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(GeminiService.availableModels, id: \.self) { model in
                            Button {
                                selectedModel = model
                            } label: {
                                Text(model)
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedModel == model ? Color(hex: "#5A5A40") ?? .brown : Color(.systemGray6))
                                    .foregroundStyle(selectedModel == model ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Text("点击预设快速切换，或直接输入任意模型名。不同模型配额独立。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("密钥") {
                HStack {
                    SecureField(hasSavedKey ? "•••• 已存储，输入新密钥可替换" : "粘贴 Gemini API Key", text: $apiKeyInput)
                        .focused($isFieldFocused)
                        .submitLabel(.done)
                        .disabled(isTesting)
                        .onSubmit { saveKey() }

                    if !apiKeyInput.isEmpty {
                        Button(action: { apiKeyInput = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .disabled(isTesting)
                    }
                }

                if hasSavedKey && apiKeyInput.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(.green)
                        Text("已配置 API Key")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                Button(action: saveKey) {
                    HStack {
                        Spacer()
                        if isTesting {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text("保存")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTesting)
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "#5A5A40") ?? .brown)

                Button(action: testConnection) {
                    HStack {
                        Spacer()
                        if isTesting {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "network")
                        }
                        Text("测试连接")
                        Spacer()
                    }
                }
                .disabled(isTesting)
                .buttonStyle(.bordered)
                .tint(.secondary)
            }

            if hasSavedKey {
                Section {
                    Button(role: .destructive, action: deleteKey) {
                        HStack {
                            Spacer()
                            Image(systemName: "trash")
                            Text("删除已存储的密钥")
                            Spacer()
                        }
                    }
                    .disabled(isTesting)
                }
            }

            Section {
                NavigationLink("如何获取 API Key？") {
                    GetAPIKeyView()
                }
            }
        }
        .navigationTitle("Gemini API Key")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            hasSavedKey = (try? KeychainService.shared.load(key: KeychainService.geminiKey)) != nil
            if selectedModel.isEmpty {
                selectedModel = "gemini-2.0-flash"
            }
        }
        .alert("Gemini API Key", isPresented: $showAlert) {
            Button("好", role: .cancel) { }
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private func saveKey() {
        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            try KeychainService.shared.save(key: KeychainService.geminiKey, value: trimmed)
            hasSavedKey = true
            apiKeyInput = ""
            isFieldFocused = false
            alertMessage = "API Key 已安全存储到 Keychain"
            showAlert = true
        } catch {
            alertMessage = "保存失败：\(error.localizedDescription)"
            showAlert = true
        }
    }

    private func testConnection() {
        let key: String
        if !apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            key = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if let saved = try? KeychainService.shared.load(key: KeychainService.geminiKey) {
            key = saved
        } else {
            alertMessage = "请先输入或保存 API Key"
            showAlert = true
            return
        }

        isTesting = true
        Task {
            do {
                let ok = try await GeminiService.shared.testConnection(apiKey: key)
                await MainActor.run {
                    isTesting = false
                    alertMessage = ok ? "连接成功！API Key 有效" : "连接失败，请检查 Key 是否正确"
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    isTesting = false
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }

    private func deleteKey() {
        do {
            try KeychainService.shared.delete(key: KeychainService.geminiKey)
            hasSavedKey = false
            apiKeyInput = ""
            alertMessage = "API Key 已删除"
            showAlert = true
        } catch {
            alertMessage = "删除失败：\(error.localizedDescription)"
            showAlert = true
        }
    }
}

struct GetAPIKeyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("获取 Gemini API Key")
                    .font(.title2)
                    .fontWeight(.bold)

                VStack(alignment: .leading, spacing: 8) {
                    Text("1.").fontWeight(.semibold) + Text(" 打开 Google AI Studio")
                    Link("https://aistudio.google.com/apikey", destination: URL(string: "https://aistudio.google.com/apikey")!)
                        .font(.callout)
                        .foregroundStyle(.blue)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("2.").fontWeight(.semibold) + Text(" 登录 Google 账号后，点击「Create API Key」")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("3.").fontWeight(.semibold) + Text(" 复制生成的 API Key，粘贴到上一页的输入框中")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("注意").fontWeight(.semibold).foregroundStyle(.orange) + Text("：Gemini API 有免费配额，超出后需付费。请妥善保管你的 Key。")
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("获取 API Key")
        .navigationBarTitleDisplayMode(.inline)
    }
}
