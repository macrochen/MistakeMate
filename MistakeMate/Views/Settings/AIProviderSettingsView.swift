import SwiftData
import SwiftUI

struct AIProviderSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomAIProvider.createdAt) private var providers: [CustomAIProvider]

    @State private var showAddSheet = false
    @State private var selectedPreset: PresetProvider?
    @State private var editingProvider: CustomAIProvider?
    @State private var showDeleteAlert = false
    @State private var providerToDelete: CustomAIProvider?
    @State private var alertMessage: String?
    @State private var showAlert = false

    var body: some View {
        List {
            emptyState
            providerList
            addButton
            presetSection
        }
        .navigationTitle("AI 提供商")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddSheet, onDismiss: {
            selectedPreset = nil
        }) {
            ProviderEditView(
                initialName: selectedPreset?.displayName ?? "",
                initialBaseURL: selectedPreset?.baseURL ?? "https://api.deepseek.com/v1",
                initialModel: selectedPreset?.defaultModel ?? "deepseek-chat",
                onSave: saveProvider
            )
        }
        .sheet(item: $editingProvider) { provider in
            ProviderEditView(
                initialName: provider.name,
                initialBaseURL: provider.baseURL,
                initialModel: provider.model,
                initialApiKey: (try? KeychainService.shared.load(key: provider.keychainKey)) ?? "",
                isEditing: true,
                existingProvider: provider,
                onSave: { name, baseURL, apiKey, model in
                    updateProvider(provider, name: name, baseURL: baseURL, apiKey: apiKey, model: model)
                }
            )
        }
        .alert("删除提供商", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                if let provider = providerToDelete {
                    deleteProvider(provider)
                }
            }
        } message: {
            Text("删除后该提供商的 API Key 也会从 Keychain 中移除。")
        }
        .alert("AI 提供商", isPresented: $showAlert) {
            Button("好", role: .cancel) { }
        } message: {
            Text(alertMessage ?? "")
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if providers.isEmpty {
            Section {
                ContentUnavailableView(
                    "未配置 AI 提供商",
                    systemImage: "network.slash",
                    description: Text("添加一个提供商后即可开始使用 AI 助手。")
                )
            }
        }
    }

    private var providerList: some View {
        ForEach(providers) { provider in
            ProviderRowView(provider: provider, onDelete: {
                providerToDelete = provider
                showDeleteAlert = true
            }, onSetDefault: {
                setDefault(provider)
            })
            .contentShape(Rectangle())
            .onTapGesture {
                editingProvider = provider
            }
        }
    }

    private var addButton: some View {
        Section {
            Button {
                showAddSheet = true
            } label: {
                Label("添加提供商", systemImage: "plus.circle")
                    .fontWeight(.medium)
            }
        }
    }

    private var presetSection: some View {
        Section("预设") {
            ForEach(PresetProvider.allCases) { preset in
                Button {
                    selectedPreset = preset
                    showAddSheet = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(preset.displayName)
                                .fontWeight(.medium)
                            Text(preset.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "plus.circle")
                            .foregroundStyle(.tint)
                    }
                }
                .disabled(providers.contains { $0.baseURL == preset.baseURL })
                .foregroundStyle(.primary)
            }
        }
    }

    // MARK: - Actions

    private func setDefault(_ provider: CustomAIProvider) {
        for p in providers {
            p.isDefault = (p.id == provider.id)
        }
        try? modelContext.save()
    }

    private func saveProvider(name: String, baseURL: String, apiKey: String, model: String) {
        let normalizedURL = normalizedAIBaseURL(baseURL)

        // Save API key to Keychain
        let newProvider = CustomAIProvider(
            name: name,
            baseURL: normalizedURL,
            apiKey: "",
            model: model,
            isDefault: providers.isEmpty
        )

        do {
            try KeychainService.shared.save(key: newProvider.keychainKey, value: apiKey)
            newProvider.apiKey = newProvider.keychainKey // store reference
            modelContext.insert(newProvider)
            try? modelContext.save()
        } catch {
            alertMessage = "API Key 保存失败：\(error.localizedDescription)"
            showAlert = true
        }
    }

    private func updateProvider(_ provider: CustomAIProvider, name: String, baseURL: String, apiKey: String, model: String) {
        let oldKeychainKey = provider.keychainKey
        provider.name = name
        provider.baseURL = normalizedAIBaseURL(baseURL)
        provider.model = model
        provider.updatedAt = Date()

        if !apiKey.isEmpty {
            do {
                // Delete old key if baseURL/name changed
                if oldKeychainKey != provider.keychainKey {
                    try? KeychainService.shared.delete(key: oldKeychainKey)
                }
                try KeychainService.shared.save(key: provider.keychainKey, value: apiKey)
                provider.apiKey = provider.keychainKey
            } catch {
                alertMessage = "API Key 保存失败：\(error.localizedDescription)"
                showAlert = true
            }
        }

        try? modelContext.save()
    }

    private func deleteProvider(_ provider: CustomAIProvider) {
        // Remove from Keychain
        try? KeychainService.shared.delete(key: provider.keychainKey)
        modelContext.delete(provider)
        try? modelContext.save()
    }

}

// MARK: - Provider Row

private struct ProviderRowView: View {
    let provider: CustomAIProvider
    let onDelete: () -> Void
    let onSetDefault: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(provider.name)
                        .fontWeight(.semibold)
                    if provider.isDefault {
                        Text("默认")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor)
                            .clipShape(Capsule())
                    }
                }
                Text(provider.displayEndpoint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(provider.model)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.quaternary)
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("删除", systemImage: "trash")
            }

            if !provider.isDefault {
                Button {
                    onSetDefault()
                } label: {
                    Label("设为默认", systemImage: "star")
                }
                .tint(.yellow)
            }
        }
    }
}

// MARK: - Provider Edit Sheet

private struct ProviderEditView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var baseURL: String
    @State private var apiKey: String
    @State private var model: String
    @State private var isTesting = false

    let isEditing: Bool
    let existingProvider: CustomAIProvider?
    let onSave: (String, String, String, String) -> Void

    @State private var alertMessage: String?
    @State private var showAlert = false

    init(
        initialName: String = "",
        initialBaseURL: String = "https://api.deepseek.com",
        initialModel: String = "deepseek-chat",
        initialApiKey: String = "",
        isEditing: Bool = false,
        existingProvider: CustomAIProvider? = nil,
        onSave: @escaping (String, String, String, String) -> Void
    ) {
        _name = State(initialValue: initialName)
        _baseURL = State(initialValue: initialBaseURL)
        _model = State(initialValue: initialModel)
        _apiKey = State(initialValue: initialApiKey)
        self.isEditing = isEditing
        self.existingProvider = existingProvider
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("显示名称", text: $name)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    TextField("API 地址", text: $baseURL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.URL)

                    TextField("模型名称", text: $model)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }

                Section("密钥") {
                    HStack {
                        if isEditing && apiKey.isEmpty {
                            SecureField("输入新密钥可替换", text: $apiKey)
                        } else {
                            SecureField("API Key", text: $apiKey)
                        }
                        if !apiKey.isEmpty {
                            Button { apiKey = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if isEditing && apiKey.isEmpty {
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundStyle(.green)
                            Text("已有密钥，输入新值可替换")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Button(action: save) {
                        HStack {
                            Spacer()
                            Text(isEditing ? "保存修改" : "添加提供商")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(name.isEmpty || baseURL.isEmpty || model.isEmpty || (apiKey.isEmpty && !isEditing))
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
                    .disabled(isTesting || apiKey.isEmpty)
                    .buttonStyle(.bordered)
                    .tint(.secondary)
                }
            }
            .navigationTitle(isEditing ? "编辑提供商" : "添加提供商")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("AI 提供商"), message: Text(alertMessage ?? ""), dismissButton: .default(Text("好")))
            }
        }
    }

    private func save() {
        guard !name.isEmpty, !baseURL.isEmpty, !model.isEmpty else { return }
        guard !apiKey.isEmpty || isEditing else { return }
        onSave(name, baseURL, apiKey, model)
        dismiss()
    }

    private func testConnection() {
        guard !apiKey.isEmpty else {
            alertMessage = "请先输入 API Key"
            showAlert = true
            return
        }

        isTesting = true
        Task {
            do {
                let ok = try await AIService.shared.testConnection(
                    apiKey: apiKey,
                    baseURL: normalizedAIBaseURL(baseURL),
                    model: model
                )
                await MainActor.run {
                    isTesting = false
                    alertMessage = ok ? "连接成功！API Key 有效" : "连接失败，请检查配置"
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
}

// MARK: - Presets

enum PresetProvider: String, CaseIterable, Identifiable {
    case deepseek
    case openrouter
    case gemini
    case siliconflow

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .deepseek: return "DeepSeek"
        case .openrouter: return "OpenRouter"
        case .gemini: return "Google Gemini"
        case .siliconflow: return "SiliconFlow"
        }
    }

    var baseURL: String {
        switch self {
        case .deepseek: return "https://api.deepseek.com/v1"
        case .openrouter: return "https://openrouter.ai/api/v1"
        case .gemini: return "https://generativelanguage.googleapis.com/v1beta/openai"
        case .siliconflow: return "https://api.siliconflow.cn/v1"
        }
    }

    var description: String {
        switch self {
        case .deepseek: return "api.deepseek.com — deepseek-chat"
        case .openrouter: return "openrouter.ai — 多模型聚合"
        case .gemini: return "generativelanguage.googleapis.com/openai — gemini-2.5-flash"
        case .siliconflow: return "api.siliconflow.cn — 国产 GPU 推理"
        }
    }

    var defaultModel: String {
        switch self {
        case .deepseek: return "deepseek-chat"
        case .openrouter: return "openrouter/auto"
        case .gemini: return "gemini-2.5-flash"
        case .siliconflow: return "deepseek-ai/DeepSeek-V3"
        }
    }
}

private func normalizedAIBaseURL(_ url: String) -> String {
    var result = url.trimmingCharacters(in: .whitespacesAndNewlines)
    while result.hasSuffix("/") {
        result.removeLast()
    }

    if result.hasSuffix("/v1") || result.hasSuffix("/v1beta") || result.hasSuffix("/openai") {
        return result
    }

    return "\(result)/v1"
}
