     1|# 错题助手 iOS App — 开发计划
     2|
     3|> **For Hermes:** Use `subagent-driven-development` skill to implement this plan task-by-task.
     4|>
     5|> **Goal:** 从零搭建 SwiftUI + SwiftData 本地错题管理 iOS App，集成 Gemini AI 识别和分析
     6|
     7|**架构:** MVVM + SwiftData + Gemini API 直调，WebView 渲染 Markdown + KaTeX 公式
     8|
     9|**技术栈:** SwiftUI, SwiftData, WKWebView, PhotosUI, Keychain, URLSession async/await
    10|
    11|**最低版本:** iOS 17.0
    12|
    13|---
    14|
    15|## 项目路径
    16|
    17|```
    18|/Users/shi/workspace/MistakeMate/
    19|```
    20|
    21|---
    22|
    23|✅ ## Phase 1: 项目初始化 + 数据模型 [8 tasks]
    24|
    25|### ✅ Task 1.1: 创建 Xcode 项目
    26|
    27|**Objective:** 用 SwiftUI + SwiftData 模板创建项目
    28|
    29|**Files:**
    30|- Create: 通过 Xcode CLI 创建项目目录结构
    31|- Create: `MistakeMateApp.swift`
    32|- Create: `ContentView.swift`
    33|
    34|**Step 1: 创建项目**
    35|
    36|```bash
    37|mkdir -p /Users/shi/workspace/MistakeMate
    38|cd /Users/shi/workspace/MistakeMate
    39|# 手动创建 Xcode 项目文件结构（Xcode CLI 不支持全自动创建，需手写 .xcodeproj）
    40|```
    41|
    42|实际上我们将用 Swift Package 方式组织，配合手动 Xcode 项目配置。为了快速启动，先创建核心文件结构：
    43|
    44|```bash
    45|mkdir -p MistakeMate/{Models,Services,ViewModels,Views/{MistakeBook,Chat,Settings,Components},Resources}
    46|```
    47|
    48|**Step 2: 创建 `MistakeMateApp.swift`**
    49|
    50|```swift
    51|import SwiftUI
    52|import SwiftData
    53|
    54|@main
    55|struct MistakeMateApp: App {
    56|    var body: some Scene {
    57|        WindowGroup {
    58|            ContentView()
    59|        }
    60|        .modelContainer(for: [Subject.self, Mistake.self, PracticeSet.self, PracticeItem.self, AppSettings.self, ChatSession.self, ChatMessage.self, PromptTemplate.self])
    61|    }
    62|}
    63|```
    64|
    65|**Step 3: 创建 `ContentView.swift`**
    66|
    67|```swift
    68|import SwiftUI
    69|
    70|struct ContentView: View {
    71|    @State private var selectedTab = 0
    72|    
    73|    var body: some View {
    74|        TabView(selection: $selectedTab) {
    75|            MistakeListView()
    76|                .tabItem {
    77|                    Label("错题本", systemImage: "text.book.closed")
    78|                }
    79|                .tag(0)
    80|            
    81|            ChatListView()
    82|                .tabItem {
    83|                    Label("AI助手", systemImage: "message")
    84|                }
    85|                .tag(1)
    86|            
    87|            SettingsView()
    88|                .tabItem {
    89|                    Label("设置", systemImage: "gear")
    90|                }
    91|                .tag(2)
    92|        }
    93|    }
    94|}
    95|```
    96|
    97|**Step 4: 创建占位 View 文件**（确保编译通过）
    98|
    99|- `MistakeListView.swift` → `Text("错题本")`
   100|- `ChatListView.swift` → `Text("AI助手")`
   101|- `SettingsView.swift` → `Text("设置")`
   102|
   103|**Verification:** Xcode Build → Success, 模拟器显示 TabView
   104|
   105|---
   106|
   107|### ✅ Task 1.2: 创建 Subject 与 AppSettings 模型
   108|
   109|**Objective:** SwiftData Subject 与 AppSettings 模型，支持科目管理与年级配置
   110|
   111|**Files:**
   112|- Create: `MistakeMate/Models/Subject.swift`
   113|- Create: `MistakeMate/Models/AppSettings.swift`
   114|
   115|```swift
   116|import SwiftData
   117|import SwiftUI
   118|import Foundation
   119|
   120|@Model
   121|final class Subject {
   122|    var name: String
   123|    var colorHex: String
   124|    var sortOrder: Int
   125|    
   126|    @Relationship(deleteRule: .nullify, inverse: \\Mistake.subject)
   127|    var mistakes: [Mistake]? = []
   128|    
   129|    init(name: String, colorHex: String = "#5A5A40", sortOrder: Int = 0) {
   130|        self.name = name
   131|        self.colorHex = colorHex
   132|        self.sortOrder = sortOrder
   133|    }
   134|    
   135|    static let defaultSubjects: [(name: String, color: String)] = [
   136|        ("语文", "#E74C3C"), ("数学", "#3498DB"), ("英语", "#2ECC71"),
   137|        ("物理", "#9B59B6"), ("化学", "#F39C12"), ("生物", "#1ABC9C"),
   138|        ("历史", "#E67E22"), ("地理", "#27AE60"), ("政治", "#E91E63")
   139|    ]
   140|    
   141|    var color: Color {
   142|        Color(hex: colorHex) ?? Color.gray
   143|    }
   144|}
   145|
   146|@Model
   147|final class AppSettings {
   148|    var currentGrade: String
   149|    var createdAt: Date
   150|    var updatedAt: Date
   151|    
   152|    init(currentGrade: String = "未设置") {
   153|        self.currentGrade = currentGrade
   154|        self.createdAt = Date()
   155|        self.updatedAt = Date()
   156|    }
   157|}
   158|```
   159|
   160|**Step 1:** 在 `MistakeMateApp.swift` 的 `modelContainer` 中已包含 `.self`
   161|
   162|**Step 2:** 添加 Color hex 扩展（`Color+Hex.swift`）
   163|
   164|**Verification:** Build 通过，app 启动不崩溃
   165|
   166|---
   167|
   168|### ✅ Task 1.3: 创建 Mistake 模型
   169|
   170|**Objective:** SwiftData Mistake 模型
   171|
   172|**Files:**
   173|- Create: `MistakeMate/Models/Mistake.swift`
   174|
   175|```swift
   176|import SwiftData
   177|import Foundation
   178|
   179|@Model
   180|final class Mistake {
   181|    var content: String
   182|    var mistakeType: String        // 不会 / 会但不熟 / 粗心 / 审题错 / 记忆错乱
   183|    var textbookUnit: String?
   184|    var knowledgePoint: String?
   185|    var scoreLossPoint: String?
   186|    var analysis: String
   187|    var preventionRule: String
   188|    var socraticQuestions: [String]
   189|    var source: String?
   190|    var notes: String?
   191|    var imageData: Data?           // JPEG compressed
   192|    var createdAt: Date
   193|    var updatedAt: Date
   194|    
   195|    @Relationship
   196|    var subject: Subject?
   197|    
   198|    static let mistakeTypes = [
   199|        "不会", "会但不熟", "粗心", "审题错", "记忆错乱"
   200|    ]
   201|    
   202|    init(
   203|        content: String,
   204|        mistakeType: String,
   205|        textbookUnit: String? = nil,
   206|        knowledgePoint: String? = nil,
   207|        scoreLossPoint: String? = nil,
   208|        analysis: String,
   209|        preventionRule: String,
   210|        socraticQuestions: [String] = [],
   211|        source: String? = nil,
   212|        subject: Subject? = nil,
   213|        imageData: Data? = nil
   214|    ) {
   215|        self.content = content
   216|        self.mistakeType = mistakeType
   217|        self.textbookUnit = textbookUnit
   218|        self.knowledgePoint = knowledgePoint
   219|        self.scoreLossPoint = scoreLossPoint
   220|        self.analysis = analysis
   221|        self.preventionRule = preventionRule
   222|        self.socraticQuestions = socraticQuestions
   223|        self.source = source
   224|        self.subject = subject
   225|        self.imageData = imageData
   226|        self.createdAt = Date()
   227|        self.updatedAt = Date()
   228|    }
   229|}
   230|```
   231|
   232|**Verification:** Build 通过
   233|
   234|---
   235|
   236|### ✅ Task 1.4: 创建 ChatSession、ChatMessage、PromptTemplate 与练习集模型
   237|
   238|**Objective:** 对话、提示词库与举一反三练习集持久化模型
   239|
   240|**Files:**
   241|- Create: `MistakeMate/Models/ChatSession.swift`
   242|- Create: `MistakeMate/Models/ChatMessage.swift`
   243|- Create: `MistakeMate/Models/PromptTemplate.swift`
   244|- Create: `MistakeMate/Models/PracticeSet.swift`
   245|- Create: `MistakeMate/Models/PracticeItem.swift`
   246|
   247|```swift
   248|// ChatSession.swift
   249|import SwiftData
   250|import Foundation
   251|
   252|@Model
   253|final class ChatSession {
   254|    var title: String
   255|    var createdAt: Date
   256|    var updatedAt: Date
   257|    
   258|    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.session)
   259|    var messages: [ChatMessage]? = []
   260|    
   261|    init(title: String = "新对话") {
   262|        self.title = title
   263|        self.createdAt = Date()
   264|        self.updatedAt = Date()
   265|    }
   266|}
   267|```
   268|
   269|```swift
   270|// ChatMessage.swift
   271|import SwiftData
   272|import Foundation
   273|
   274|@Model
   275|final class ChatMessage {
   276|    var role: String       // "user" | "assistant" | "system"
   277|    var content: String
   278|    var imageData: Data?
   279|    var audioData: Data?
   280|    var audioDuration: Double?
   281|    var createdAt: Date
   282|    
   283|    @Relationship
   284|    var session: ChatSession?
   285|    
   286|    init(
   287|        role: String,
   288|        content: String,
   289|        session: ChatSession? = nil,
   290|        imageData: Data? = nil,
   291|        audioData: Data? = nil,
   292|        audioDuration: Double? = nil
   293|    ) {
   294|        self.role = role
   295|        self.content = content
   296|        self.session = session
   297|        self.imageData = imageData
   298|        self.audioData = audioData
   299|        self.audioDuration = audioDuration
   300|        self.createdAt = Date()
   301|    }
   302|}
   303|```
   304|
   305|```swift
   306|// PromptTemplate.swift
   307|import SwiftData
   308|import Foundation
   309|
   310|@Model
   311|final class PromptTemplate {
   312|    var title: String
   313|    var content: String
   314|    var category: String
   315|    var createdAt: Date
   316|    var updatedAt: Date
   317|    var lastUsedAt: Date?
   318|    
   319|    init(title: String, content: String, category: String = "我的定制") {
   320|        self.title = title
   321|        self.content = content
   322|        self.category = category
   323|        self.createdAt = Date()
   324|        self.updatedAt = Date()
   325|        self.lastUsedAt = nil
   326|    }
   327|}
   328|```
   329|
   330|```swift
   331|// PracticeSet.swift
   332|import SwiftData
   333|import Foundation
   334|
   335|@Model
   336|final class PracticeSet {
   337|    var title: String
   338|    var gradeSnapshot: String
   339|    var status: String
   340|    var createdAt: Date
   341|    var updatedAt: Date
   342|    
   343|    @Relationship
   344|    var mistake: Mistake?
   345|    
   346|    @Relationship(deleteRule: .cascade, inverse: \PracticeItem.practiceSet)
   347|    var items: [PracticeItem]? = []
   348|    
   349|    init(title: String, gradeSnapshot: String, status: String = "未开始", mistake: Mistake? = nil) {
   350|        self.title = title
   351|        self.gradeSnapshot = gradeSnapshot
   352|        self.status = status
   353|        self.mistake = mistake
   354|        self.createdAt = Date()
   355|        self.updatedAt = Date()
   356|    }
   357|}
   358|```
   359|
   360|```swift
   361|// PracticeItem.swift
   362|import SwiftData
   363|import Foundation
   364|
   365|@Model
   366|final class PracticeItem {
   367|    var question: String
   368|    var hint: String?
   369|    var answer: String
   370|    var explanation: String
   371|    var difficulty: String
   372|    var userAnswer: String?
   373|    var isCompleted: Bool
   374|    var sortOrder: Int
   375|    
   376|    @Relationship
   377|    var practiceSet: PracticeSet?
   378|    
   379|    init(question: String, hint: String? = nil, answer: String, explanation: String, difficulty: String, sortOrder: Int = 0, practiceSet: PracticeSet? = nil) {
   380|        self.question = question
   381|        self.hint = hint
   382|        self.answer = answer
   383|        self.explanation = explanation
   384|        self.difficulty = difficulty
   385|        self.userAnswer = nil
   386|        self.isCompleted = false
   387|        self.sortOrder = sortOrder
   388|        self.practiceSet = practiceSet
   389|    }
   390|}
   391|```
   392|
   393|**Verification:** Build 通过
   394|
   395|---
   396|
   397|### ✅ Task 1.5: 创建种子数据初始化
   398|
   399|**Objective:** 首次启动时插入默认科目
   400|
   401|**Files:**
   402|- Create: `MistakeMate/Models/DataSeeder.swift`
   403|
   404|```swift
   405|import SwiftData
   406|import Foundation
   407|
   408|struct DataSeeder {
   409|    static func seedIfNeeded(context: ModelContext) {
   410|        let descriptor = FetchDescriptor<Subject>()
   411|        guard let count = try? context.fetchCount(descriptor), count == 0 else { return }
   412|        
   413|        for (index, subject) in Subject.defaultSubjects.enumerated() {
   414|            let s = Subject(name: subject.name, colorHex: subject.color, sortOrder: index)
   415|            context.insert(s)
   416|        }
   417|        try? context.save()
   418|    }
   419|}
   420|```
   421|
   422|在 `MistakeMateApp.swift` 中调用：
   423|
   424|```swift
   425|.modelContainer(for: [...]) { result in
   426|    if case .success(let container) = result {
   427|        DataSeeder.seedIfNeeded(context: container.mainContext)
   428|    }
   429|}
   430|```
   431|
   432|**Verification:** 首次启动后 SwiftData 中有 9 个默认科目
   433|
   434|---
   435|
   436|### ✅ Task 1.6: 创建 Color+Hex 工具扩展
   437|
   438|**Objective:** hex string → SwiftUI Color
   439|
   440|**Files:**
   441|- Create: `MistakeMate/Utilities/Color+Hex.swift`
   442|
   443|```swift
   444|import SwiftUI
   445|
   446|extension Color {
   447|    init?(hex: String) {
   448|        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
   449|        var int: UInt64 = 0
   450|        Scanner(string: hex).scanHexInt64(&int)
   451|        let a, r, g, b: UInt64
   452|        switch hex.count {
   453|        case 6:
   454|            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
   455|        case 8:
   456|            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
   457|        default:
   458|            return nil
   459|        }
   460|        self.init(
   461|            .sRGB,
   462|            red: Double(r) / 255,
   463|            green: Double(g) / 255,
   464|            blue:  Double(b) / 255,
   465|            opacity: Double(a) / 255
   466|        )
   467|    }
   468|}
   469|```
   470|
   471|**Verification:** Build 通过
   472|
   473|---
   474|
   475|### ✅ Task 1.7: 创建科目管理页面占位 + 编译验证
   476|
   477|**Objective:** 确保所有基础模型文件完整，项目可编译
   478|
   479|**Files:**
   480|- Modify: `MistakeListView.swift` → 使用 `@Query` 获取错题、显示计数
   481|- Modify: `ChatListView.swift` → 使用 `@Query` 获取会话
   482|- Modify: `SettingsView.swift` → 简单列表
   483|
   484|**Verification:** `xcodebuild` 或直接 `swift build` 通过，模拟器运行正常
   485|
   486|---
   487|
   488|### ✅ Task 1.8: 建立 Git 仓库
   489|
   490|**Objective:** 项目纳入版本管理
   491|
   492|```bash
   493|cd /Users/shi/workspace/MistakeMate
   494|git init
   495|git add -A
   496|git commit -m "init: SwiftUI + SwiftData project scaffold with data models"
   497|```
   498|
   499|**Verification:** `git log` 显示初始提交
   500|
   501|---
   502|
   503|✅ ## Phase 2: Gemini API 服务层 [5 tasks]
   504|
   505|### ✅ Task 2.1: Keychain 封装
   506|
   507|**Objective:** API Key 安全存储
   508|
   509|**Files:**
   510|- Create: `MistakeMate/Services/KeychainService.swift`
   511|
   512|```swift
   513|import Foundation
   514|import Security
   515|
   516|struct KeychainService {
   517|    static let shared = KeychainService()
   518|    
   519|    func save(key: String, value: String) {
   520|        let data = value.data(using: .utf8)!
   521|        let query: [CFString: Any] = [
   522|            kSecClass: kSecClassGenericPassword,
   523|            kSecAttrAccount: key,
   524|            kSecValueData: data
   525|        ]
   526|        SecItemDelete(query as CFDictionary)
   527|        SecItemAdd(query as CFDictionary, nil)
   528|    }
   529|    
   530|    func load(key: String) -> String? {
   531|        let query: [CFString: Any] = [
   532|            kSecClass: kSecClassGenericPassword,
   533|            kSecAttrAccount: key,
   534|            kSecReturnData: true,
   535|            kSecMatchLimit: kSecMatchLimitOne
   536|        ]
   537|        var result: AnyObject?
   538|        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
   539|              let data = result as? Data else { return nil }
   540|        return String(data: data, encoding: .utf8)
   541|    }
   542|    
   543|    func delete(key: String) {
   544|        let query: [CFString: Any] = [
   545|            kSecClass: kSecClassGenericPassword,
   546|            kSecAttrAccount: key
   547|        ]
   548|        SecItemDelete(query as CFDictionary)
   549|    }
   550|    
   551|    static let geminiKey = "com.mistakemate.gemini-api-key"
   552|}
   553|```
   554|
   555|**Verification:** 单元测试 save/load/delete 循环
   556|
   557|---
   558|
   559|### ✅ Task 2.2: 图片处理器
   560|
   561|**Objective:** 图片压缩、resize
   562|
   563|**Files:**
   564|- Create: `MistakeMate/Services/ImageProcessor.swift`
   565|
   566|```swift
   567|import UIKit
   568|
   569|struct ImageProcessor {
   570|    static func compress(_ image: UIImage, maxSide: CGFloat = 1200, quality: CGFloat = 0.7) -> Data? {
   571|        let size = image.size
   572|        let ratio = min(maxSide / size.width, maxSide / size.height, 1.0)
   573|        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
   574|        
   575|        let renderer = UIGraphicsImageRenderer(size: newSize)
   576|        let resized = renderer.image { _ in
   577|            image.draw(in: CGRect(origin: .zero, size: newSize))
   578|        }
   579|        return resized.jpegData(compressionQuality: quality)
   580|    }
   581|}
   582|```
   583|
   584|**Verification:** 输入大图 → 输出 ≤ 500KB JPEG data
   585|
   586|---
   587|
   588|### ✅ Task 2.3: GeminiService — 基础 API 客户端
   589|
   590|**Objective:** 封装 Google Gemini REST API
   591|
   592|**Files:**
   593|- Create: `MistakeMate/Services/GeminiService.swift`
   594|
   595|```swift
   596|import Foundation
   597|
   598|struct GeminiService {
   599|    static let shared = GeminiService()
   600|    
   601|    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"
   602|    private let model = "gemini-2.0-flash"
   603|    
   604|    private var apiKey: String? {
   605|        KeychainService.shared.load(key: KeychainService.geminiKey)
   606|    }
   607|    
   608|    // MARK: - Test Connection
   609|    func testConnection(apiKey: String) async throws -> Bool {
   610|        let url = URL(string: "\(baseURL)/models/\(model):generateContent?key=\(apiKey)")!
   611|        let body: [String: Any] = [
   612|            "contents": [["parts": [["text": "Hi"]]]],
   613|            "generationConfig": ["maxOutputTokens": 5]
   614|        ]
   615|        var request = URLRequest(url: url)
   616|        request.httpMethod = "POST"
   617|        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
   618|        request.httpBody = try JSONSerialization.data(withJSONObject: body)
   619|        
   620|        let (_, response) = try await URLSession.shared.data(for: request)
   621|        return (response as? HTTPURLResponse)?.statusCode == 200
   622|    }
   623|    
   624|    // MARK: - Generate Content (General)
   625|    func generateContent(
   626|        prompt: String,
   627|        imageData: Data? = nil,
   628|        systemInstruction: String? = nil
   629|    ) async throws -> String {
   630|        guard let key = apiKey else { throw GeminiError.noAPIKey }
   631|        let url = URL(string: "\(baseURL)/models/\(model):generateContent?key=\(key)")!
   632|        
   633|        var parts: [[String: Any]] = [[ "text": prompt ]]
   634|        if let imageData = imageData {
   635|            parts.append([
   636|                "inline_data": [
   637|                    "mime_type": "image/jpeg",
   638|                    "data": imageData.base64EncodedString()
   639|                ]
   640|            ])
   641|        }
   642|        
   643|        var body: [String: Any] = [
   644|            "contents": [["parts": parts]]
   645|        ]
   646|        
   647|        if let sys = systemInstruction {
   648|            body["systemInstruction"] = ["parts": [["text": sys]]]
   649|        }
   650|        
   651|        var request = URLRequest(url: url)
   652|        request.httpMethod = "POST"
   653|        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
   654|        request.httpBody = try JSONSerialization.data(withJSONObject: body)
   655|        
   656|        let (data, response) = try await URLSession.shared.data(for: request)
   657|        
   658|        guard let httpResponse = response as? HTTPURLResponse,
   659|              httpResponse.statusCode == 200 else {
   660|            throw GeminiError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
   661|        }
   662|        
   663|        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
   664|        let candidates = json?["candidates"] as? [[String: Any]]
   665|        let content = candidates?.first?["content"] as? [String: Any]
   666|        let parts2 = content?["parts"] as? [[String: Any]]
   667|        return parts2?.first?["text"] as? String ?? ""
   668|    }
   669|}
   670|
   671|enum GeminiError: LocalizedError {
   672|    case noAPIKey
   673|    case httpError(Int)
   674|    case parseError
   675|    
   676|    var errorDescription: String? {
   677|        switch self {
   678|        case .noAPIKey: return "请先在设置中配置 Gemini API Key"
   679|        case .httpError(let code): return "API 请求失败 (HTTP \(code))"
   680|        case .parseError: return "AI 返回数据解析失败"
   681|        }
   682|    }
   683|}
   684|```
   685|
   686|**Verification:** `testConnection` 用真实 API Key 返回 true
   687|
   688|---
   689|
   690|### ✅ Task 2.4: GeminiService — 错题识别专用方法
   691|
   692|**Objective:** 图片 → 错题 JSON 数组
   693|
   694|**Files:**
   695|- Modify: `MistakeMate/Services/GeminiService.swift` — 新增 `analyzeMistakes` 方法
   696|
   697|```swift
   698|extension GeminiService {
   699|    // 响应模型
   700|    struct MistakeResult: Codable {
   701|        let content: String
   702|        let type: String
   703|        let textbookUnit: String
   704|        let knowledgePoint: String
   705|        let scoreLossPoint: String
   706|        let analysis: String
   707|        let preventionRule: String
   708|        let socraticQuestions: [String]
   709|    }
   710|    
   711|    struct AnalyzeResponse: Codable {
   712|        let mistakes: [MistakeResult]
   713|    }
   714|    
   715|    static let mistakeAnalysisPrompt = """
   716|    你是一个极其专业的错题分析专家。请深度分析用户提供的图片或文字内容。
   717|    
   718|    【核心任务】：
   719|    1. 识别图片中出现的错题内容
   720|    2. 判断学生的主要丢分点
   721|    3. 把丢分点对应到课本具体单元和知识点
   722|    4. 输出清晰的解题分析和正确答案
   723|    5. 生成一句防错提醒
   724|    6. 用苏格拉底式提问，一步步引导孩子自己走向正确解题
   725|    7. 语言风格适配学生年级理解能力
   726|    
   727|    字段要求：
   728|    - type: 不会 / 会但不熟 / 粗心 / 审题错 / 记忆错乱
   729|    - textbookUnit: 课本具体单元
   730|    - knowledgePoint: 具体知识点
   731|    - scoreLossPoint: 主要丢分点
   732|    - socraticQuestions: 3~5 个循序渐进的问题
   733|    
   734|    严格以 JSON 格式返回，包含一个 mistakes 数组。
   735|    """
   736|    
   737|    func analyzeMistakes(imageData: Data, gradeLevel: String, textNote: String? = nil) async throws -> [MistakeResult] {
   738|        let prompt = "当前学生年级：\(gradeLevel)\n" + (textNote ?? "请分析图片中的错题")
   739|        
   740|        guard let key = apiKey else { throw GeminiError.noAPIKey }
   741|        let url = URL(string: "\(baseURL)/models/\(model):generateContent?key=\(key)")!
   742|        
   743|        var parts: [[String: Any]] = []
   744|        if let note = textNote, !note.isEmpty {
   745|            parts.append(["text": "用户备注: \(note)"])
   746|        }
   747|        parts.append(["text": prompt])
   748|        parts.append([
   749|            "inline_data": [
   750|                "mime_type": "image/jpeg",
   751|                "data": imageData.base64EncodedString()
   752|            ]
   753|        ])
   754|        
   755|        let body: [String: Any] = [
   756|            "contents": [["parts": parts]],
   757|            "systemInstruction": ["parts": [["text": Self.mistakeAnalysisPrompt]]],
   758|            "generationConfig": ["responseMimeType": "application/json"]
   759|        ]
   760|        
   761|        var request = URLRequest(url: url)
   762|        request.httpMethod = "POST"
   763|        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
   764|        request.httpBody = try JSONSerialization.data(withJSONObject: body)
   765|        
   766|        let (data, _) = try await URLSession.shared.data(for: request)
   767|        
   768|        // Gemini 返回 JSON 时在 responseMimeType 下直接给纯 JSON 文本
   769|        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
   770|        let candidates = json?["candidates"] as? [[String: Any]]
   771|        let content = candidates?.first?["content"] as? [String: Any]
   772|        let parts2 = content?["parts"] as? [[String: Any]]
   773|        let text = parts2?.first?["text"] as? String ?? ""
   774|        
   775|        // 清理可能的 markdown 代码块包裹
   776|        let cleanedText = text
   777|            .replacingOccurrences(of: "```json", with: "")
   778|            .replacingOccurrences(of: "```", with: "")
   779|            .trimmingCharacters(in: .whitespacesAndNewlines)
   780|        
   781|        guard let textData = cleanedText.data(using: .utf8) else { throw GeminiError.parseError }
   782|        let response = try JSONDecoder().decode(AnalyzeResponse.self, from: textData)
   783|        return response.mistakes
   784|    }
   785|}
   786|```
   787|
   788|**Verification:** 传入错题图片 → 返回正确的错题数组，且每题包含教材单元、知识点、丢分点与苏格拉底引导问题
   789|
   790|---
   791|
   792|### ✅ Task 2.5: GeminiService — 对话方法
   793|
   794|**Objective:** 多轮对话（带历史）
   795|
   796|**Files:**
   797|- Modify: `MistakeMate/Services/GeminiService.swift` — 新增 `chat` 方法
   798|
   799|```swift
   800|extension GeminiService {
   801|    func chat(
   802|        message: String,
   803|        history: [ChatMessage],
   804|        imageData: Data? = nil,
   805|        systemInstruction: String? = nil
   806|    ) async throws -> String {
   807|        guard let key = apiKey else { throw GeminiError.noAPIKey }
   808|        let url = URL(string: "\(baseURL)/models/\(model):generateContent?key=\(key)")!
   809|        
   810|        // 构建历史
   811|        var contents: [[String: Any]] = []
   812|        for msg in history {
   813|            let role = msg.role == "assistant" ? "model" : "user"
   814|            var parts: [[String: Any]] = [[ "text": msg.content ]]
   815|            if let img = msg.imageData {
   816|                parts.append([
   817|                    "inline_data": ["mime_type": "image/jpeg", "data": img.base64EncodedString()]
   818|                ])
   819|            }
   820|            contents.append(["role": role, "parts": parts])
   821|        }
   822|        
   823|        // 当前消息
   824|        var currentParts: [[String: Any]] = [[ "text": message ]]
   825|        if let img = imageData {
   826|            currentParts.append([
   827|                "inline_data": ["mime_type": "image/jpeg", "data": img.base64EncodedString()]
   828|            ])
   829|        }
   830|        contents.append(["role": "user", "parts": currentParts])
   831|        
   832|        var body: [String: Any] = ["contents": contents]
   833|        if let sys = systemInstruction {
   834|            body["systemInstruction"] = ["parts": [["text": sys]]]
   835|        }
   836|        
   837|        var request = URLRequest(url: url)
   838|        request.httpMethod = "POST"
   839|        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
   840|        request.httpBody = try JSONSerialization.data(withJSONObject: body)
   841|        
   842|        let (data, _) = try await URLSession.shared.data(for: request)
   843|        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
   844|        let candidates = json?["candidates"] as? [[String: Any]]
   845|        let content = candidates?.first?["content"] as? [String: Any]
   846|        let parts = content?["parts"] as? [[String: Any]]
   847|        return parts?.first?["text"] as? String ?? ""
   848|    }
   849|}
   850|```
   851|
   852|**Verification:** 发送 "你好" → 返回 Gemini 回复
   853|
   854|---
   855|
   856|## Phase 3: 错题本 UI [8 tasks]
   857|
   858|### ✅ Task 3.1: 错题列表视图
   859|
   860|**Objective:** SwiftData `@Query` 驱动的错题列表
   861|
   862|**Files:**
   863|- Modify: `MistakeMate/Views/MistakeBook/MistakeListView.swift`
   864|
   865|功能：
   866|- `@Query` 获取所有错题，按 createdAt 倒序
   867|- 每条显示：科目标签（带颜色）、错误类型标签、题目摘要（截断50字）、日期
   868|- NavigationLink → 详情页
   869|- 右上角 "+" 按钮 → 录入 Sheet
   870|- 空状态占位
   871|
   872|**Verification:** 手动插入测试数据 → 列表正确显示
   873|
   874|---
   875|
   876|### ✅ Task 3.2: 错题录入视图 — 基础 UI
   877|
   878|**Objective:** Sheet 形式的录入界面
   879|
   880|**Files:**
   881|- Create: `MistakeMate/Views/MistakeBook/MistakeInputView.swift`
   882|
   883|功能：
   884|- 科目 Picker（从 SwiftData 查询）
   885|- 来源 TextField（试卷名）
   886|- 图片选择：相机 / 相册 / 粘贴
   887|- 图片预览（可删除）
   888|- 文字备注 TextEditor
   889|- "开始分析" 按钮 → 调用 GeminiService.analyzeMistakes
   890|
   891|**Verification:** UI 完整，Picker 可选科目，图片可预览
   892|
   893|---
   894|
   895|### ✅ Task 3.3: ImagePicker 封装（相册 + 相机）
   896|
   897|**Objective:** PhotosUI 和相机封装
   898|
   899|**Files:**
   900|- Create: `MistakeMate/Views/Components/ImagePicker.swift`
   901|
   902|```swift
   903|import SwiftUI
   904|import PhotosUI
   905|
   906|struct ImagePicker: UIViewControllerRepresentable {
   907|    @Binding var image: UIImage?
   908|    var sourceType: UIImagePickerController.SourceType = .photoLibrary
   909|    
   910|    func makeUIViewController(context: Context) -> UIImagePickerController {
   911|        let picker = UIImagePickerController()
   912|        picker.sourceType = sourceType
   913|        picker.delegate = context.coordinator
   914|        return picker
   915|    }
   916|    
   917|    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
   918|    
   919|    func makeCoordinator() -> Coordinator {
   920|        Coordinator(self)
   921|    }
   922|    
   923|    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
   924|        let parent: ImagePicker
   925|        init(_ parent: ImagePicker) { self.parent = parent }
   926|        
   927|        func imagePickerController(_ picker: UIImagePickerController,
   928|                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
   929|            if let image = info[.originalImage] as? UIImage {
   930|                parent.image = image
   931|            }
   932|            picker.dismiss(animated: true)
   933|        }
   934|    }
   935|}
   936|
   937|// PhotosUI Picker (iOS 16+)
   938|struct PhotoPicker: UIViewControllerRepresentable {
   939|    @Binding var image: UIImage?
   940|    
   941|    func makeUIViewController(context: Context) -> PHPickerViewController {
   942|        var config = PHPickerConfiguration()
   943|        config.filter = .images
   944|        config.selectionLimit = 1
   945|        let picker = PHPickerViewController(configuration: config)
   946|        picker.delegate = context.coordinator
   947|        return picker
   948|    }
   949|    
   950|    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
   951|    
   952|    func makeCoordinator() -> Coordinator {
   953|        Coordinator(self)
   954|    }
   955|    
   956|    class Coordinator: NSObject, PHPickerViewControllerDelegate {
   957|        let parent: PhotoPicker
   958|        init(_ parent: PhotoPicker) { self.parent = parent }
   959|        
   960|        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
   961|            picker.dismiss(animated: true)
   962|            guard let provider = results.first?.itemProvider,
   963|                  provider.canLoadObject(ofClass: UIImage.self) else { return }
   964|            provider.loadObject(ofClass: UIImage.self) { image, _ in
   965|                DispatchQueue.main.async { self.parent.image = image as? UIImage }
   966|            }
   967|        }
   968|    }
   969|}
   970|```
   971|
   972|**Verification:** 选中图片 → 正确显示预览
   973|
   974|---
   975|
   976|### ✅ Task 3.4: 错题分析流程 + 保存
   977|
   978|**Objective:** 录入 → 调 Gemini → 展示结果 → 保存到 SwiftData
   979|
   980|**Files:**
   981|- Modify: `MistakeMate/Views/MistakeBook/MistakeInputView.swift`
   982|
   983|流程：
   984|1. 用户点击"开始分析" → 显示 Loading（"AI 正在识别错题..."）
   985|2. 图片 → `ImageProcessor.compress` → `GeminiService.analyzeMistakes(imageData:gradeLevel:)`
   986|4. 展示分析结果列表（每道错题的信息预览）
   987|5. 每道错题展示：教材单元、知识点、丢分点、分析、防错金句、引导问题
   988|6. 用户可以编辑每道错题的内容（有些识别可能不准）
   989|7. 点击"保存全部" → 逐条插入 SwiftData
   990|
   991|**Step 1:** 添加 `@State` 变量：`isAnalyzing`, `analyzedMistakes: [GeminiService.MistakeResult]`
   992|
   993|**Step 2:** Loading overlay + 结果显示
   994|
   995|**Step 3:** 保存逻辑
   996|
   997|```swift
   998|private func saveMistakes() {
   999|    guard let subject = selectedSubject else { return }
  1000|    for mistake in analyzedMistakes {
  1001|        let m = Mistake(
  1002|            content: mistake.content,
  1003|            mistakeType: mistake.type,
  1004|            textbookUnit: mistake.textbookUnit,
  1005|            knowledgePoint: mistake.knowledgePoint,
  1006|            scoreLossPoint: mistake.scoreLossPoint,
  1007|            analysis: mistake.analysis,
  1008|            preventionRule: mistake.preventionRule,
  1009|            socraticQuestions: mistake.socraticQuestions,
  1010|            source: source,
  1011|            subject: subject,
  1012|            imageData: compressedImageData
  1013|        )
  1014|        modelContext.insert(m)
  1015|    }
  1016|    try? modelContext.save()
  1017|    dismiss()
  1018|}
  1019|```
  1020|
  1021|**Verification:** 拍照 → 分析 → 保存 → 列表出现新错题
  1022|
  1023|---
  1024|
  1025|### ✅ Task 3.5: 错题详情视图
  1026|
  1027|**Objective:** 查看完整错题信息
  1028|
  1029|**Files:**
  1030|- Create: `MistakeMate/Views/MistakeBook/MistakeDetailView.swift`
  1031|
  1032|功能：
  1033|- 原图查看（可放大）
  1034|- 题目完整内容
  1035|- 错误类型标签
  1036|- 解题分析（Markdown 渲染）
  1037|- 防错金句（高亮卡片）
  1038|- 来源 / 日期信息
  1039|- 编辑 / 删除按钮
  1040|
  1041|**Verification:** 从列表点击 → 详情展示完整
  1042|
  1043|---
  1044|
  1045|### Task 3.6: Markdown WebView 组件
  1046|
  1047|**Objective:** WKWebView 渲染 Markdown + KaTeX 公式
  1048|
  1049|**Files:**
  1050|- Create: `MistakeMate/Resources/markdown-template.html`
  1051|- Create: `MistakeMate/Views/Components/MarkdownWebView.swift`
  1052|
  1053|HTML 模板（嵌入 marked.js + KaTeX CDN）：
  1054|
  1055|```swift
  1056|// MarkdownWebView.swift
  1057|import SwiftUI
  1058|import WebKit
  1059|
  1060|struct MarkdownWebView: UIViewRepresentable {
  1061|    let markdown: String
  1062|    
  1063|    func makeUIView(context: Context) -> WKWebView {
  1064|        let webView = WKWebView()
  1065|        webView.isOpaque = false
  1066|        webView.backgroundColor = .clear
  1067|        webView.scrollView.isScrollEnabled = false
  1068|        return webView
  1069|    }
  1070|    
  1071|    func updateUIView(_ webView: WKWebView, context: Context) {
  1072|        let html = renderHTML(markdown)
  1073|        webView.loadHTMLString(html, baseURL: nil)
  1074|    }
  1075|    
  1076|    private func renderHTML(_ md: String) -> String {
  1077|        let escaped = md
  1078|            .replacingOccurrences(of: "\\", with: "\\\\")
  1079|            .replacingOccurrences(of: "`", with: "\\`")
  1080|            .replacingOccurrences(of: "$", with: "\\$")
  1081|        
  1082|        return """
  1083|        <!DOCTYPE html>
  1084|        <html>
  1085|        <head>
  1086|        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
  1087|        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.css">
  1088|        <script src="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.js"></script>
  1089|        <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
  1090|        <style>
  1091|        body { font-family: -apple-system; font-size: 16px; color: #333; padding: 8px; margin: 0; }
  1092|        code { background: #f0f0f0; padding: 2px 4px; border-radius: 4px; }
  1093|        pre { background: #f5f5f5; padding: 12px; border-radius: 8px; overflow-x: auto; }
  1094|        .katex { font-size: 1.1em; }
  1095|        </style>
  1096|        </head>
  1097|        <body><div id="content"></div></body>
  1098|        <script>
  1099|        const md = `\(escaped)`;
  1100|        document.getElementById('content').innerHTML = marked.parse(md);
  1101|        renderMathInElement(document.body, { delimiters: [
  1102|            {left: '$$', right: '$$', display: true},
  1103|            {left: '$', right: '$', display: false}
  1104|        ]});
  1105|        </script>
  1106|        </html>
  1107|        """
  1108|    }
  1109|}
  1110|```
  1111|
  1112|**Verification:** 传入含 `$E=mc^2$` 的文本 → 渲染为公式
  1113|
  1114|---
  1115|
  1116|### ✅ Task 3.7: 错题搜索与筛选
  1117|
  1118|**Objective:** 搜索框 + 筛选 Picker
  1119|
  1120|**Files:**
  1121|- Modify: `MistakeMate/Views/MistakeBook/MistakeListView.swift`
  1122|
  1123|功能：
  1124|- 顶部搜索栏（`.searchable` modifier）
  1125|- 科目筛选（多选或单选 Picker）
  1126|- 错误类型筛选
  1127|
  1128|**Key:** 使用 `@Query` 配合动态 predicate 或过滤 `filter` 方法
  1129|
  1130|**Verification:** 输入关键词 → 列表过滤，选科目 → 只显示该科目
  1131|
  1132|---
  1133|
  1134|### ✅ Task 3.8: 错题删除 + 滑动操作
  1135|
  1136|**Objective:** 滑动删除 + 确认对话框
  1137|
  1138|**Files:**
  1139|- Modify: `MistakeListView` → `.swipeActions`
  1140|
  1141|```swift
  1142|.swipeActions(edge: .trailing) {
  1143|    Button(role: .destructive) {
  1144|        modelContext.delete(mistake)
  1145|        try? modelContext.save()
  1146|    } label: {
  1147|        Label("删除", systemImage: "trash")
  1148|    }
  1149|}
  1150|```
  1151|
  1152|**Verification:** 滑动 → 删除 → 列表更新
  1153|
  1154|---
  1155|
  1156|## Phase 4: AI 助手 [6 tasks]
  1157|
  1158|### ✅ Task 4.1: 对话列表视图
  1159|
  1160|**Objective:** 会话列表 + 新建对话
  1161|
  1162|**Files:**
  1163|- Modify: `MistakeMate/Views/Chat/ChatListView.swift`
  1164|
  1165|功能：
  1166|- `@Query` 会话列表（按 updatedAt 倒序）
  1167|- 每条显示：标题、最后一条消息摘要、时间
  1168|- 新建对话按钮
  1169|- 删除对话（滑动）
  1170|
  1171|**Verification:** 列表显示已有会话
  1172|
  1173|---
  1174|
  1175|### ✅ Task 4.2: 对话详情视图 — 基础
  1176|
  1177|**Objective:** 聊天界面 + 消息气泡
  1178|
  1179|**Files:**
  1180|- Create: `MistakeMate/Views/Chat/ChatDetailView.swift`
  1181|- Create: `MistakeMate/Views/Chat/ChatBubbleView.swift`
  1182|
  1183|功能：
  1184|- 消息列表（用户右对齐蓝色、AI 左对齐灰色）
  1185|- MarkdownWebView 渲染 AI 回复
  1186|- 底部输入栏：TextField + 图片按钮 + 提示词库按钮 + 录音按钮 + 发送按钮
  1187|- 支持附件预览：图片缩略图、语音时长卡片
  1188|- 下拉提示词库可在输入区上方展开
  1189|- 发送 → 调用 `GeminiService.chat` → 保存 Message → 刷新
  1190|
  1191|**Verification:** 发送消息 → AI 回复 → 对话持久化
  1192|
  1193|---
  1194|
  1195|### Task 4.3: 对话多模态附件（图片）
  1196|
  1197|**Objective:** 支持发送图片给 AI
  1198|
  1199|**Files:**
  1200|- Modify: `ChatDetailView` → 添加图片选择按钮
  1201|- Reuse: `MistakeMate/Views/Components/ImagePicker.swift`
  1202|
  1203|**Interaction:**
  1204|- 输入框左侧显示图片按钮
  1205|- 选图后在输入框上方显示缩略图预览，可移除
  1206|- 无文字时也允许直接发送图片
  1207|
  1208|**Verification:** 选图 → 发送 → AI 正确分析图片
  1209|
  1210|---
  1211|
  1212|### Task 4.4: 语音输入与音频附件
  1213|
  1214|**Objective:** 按住录音发送语音给 AI
  1215|
  1216|**Files:**
  1217|- Create: `MistakeMate/Services/AudioRecorderService.swift`
  1218|- Modify: `ChatDetailView` → 添加录音按钮、录音时长 UI、录音附件预览
  1219|- Modify: `GeminiService.swift` → `chat(...)` 支持音频 Data part
  1220|
  1221|**Implementation:**
  1222|- 使用 `AVAudioRecorder` 录制 `m4a`
  1223|- 交互为“按住录音，松开发送”
  1224|- 录音中显示红点 + 计时器
  1225|- 录音结束后生成 `audioData` + `audioDuration`
  1226|- 若用户未输入文字，仍允许直接发送语音
  1227|
  1228|**Verification:** 按住录音 3 秒 → 松开 → 自动发送 → AI 根据语音内容回复
  1229|
  1230|---
  1231|
  1232|### ✅ Task 4.5: 提示词库下拉面板 + 定制 CRUD
  1233|
  1234|**Objective:** 参考原 web 版实现提示词库下拉面板，并支持新增、编辑、删除定制提示词
  1235|
  1236|**Files:**
  1237|- Create: `MistakeMate/Views/Chat/PromptLibraryDropdown.swift`
  1238|- Create: `MistakeMate/Views/Chat/PromptEditorSheet.swift`
  1239|- Modify: `ChatDetailView` → 添加“提示词库”按钮与下拉面板
  1240|- Modify: `PromptTemplate.swift` → 使用 `lastUsedAt` 做最近使用排序
  1241|
  1242|**Implementation:**
  1243|- 输入区附近显示“提示词库”按钮，点击展开下拉面板
  1244|- 面板分两块：`我的定制` + `默认分类提示词`
  1245|- 点击任意提示词后，将内容填入输入框，默认不自动发送
  1246|- 定制提示词支持新增、编辑、删除
  1247|- 定制提示词按 `lastUsedAt` 倒序展示
  1248|
  1249|**Default prompt categories:**
  1250|- 解题助手
  1251|- 背诵复习
  1252|- 提分训练
  1253|
  1254|**Verification:**
  1255|- 点击“提示词库” → 面板展开/收起正常
  1256|- 点击提示词 → 内容填入输入框
  1257|- 新增/编辑/删除定制提示词均立即生效
  1258|- 最近使用的定制提示词排在最前
  1259|
  1260|---
  1261|
  1262|### ✅ Task 4.6: 对话结束后更新标题
  1263|
  1264|**Objective:** AI 自动生成对话标题
  1265|
  1266|首轮对话后，用 Gemini 生成 10 字以内的标题，更新 ChatSession.title。
  1267|
  1268|**Verification:** 新对话首轮后标题不再是"新对话"
  1269|
  1270|---
  1271|
  1272|## Phase 5: 设置 + 附加功能 [6 tasks]
  1273|
  1274|### ✅ Task 5.1: API Key 配置页面
  1275|
  1276|**Objective:** 输入/测试/保存 API Key
  1277|
  1278|**Files:**
  1279|- Create: `MistakeMate/Views/Settings/APIKeyView.swift`
  1280|
  1281|**Verification:** 输入 Key → 测试 → 成功 → 保存到 Keychain
  1282|
  1283|---
  1284|
  1285|### ✅ Task 5.2: 学习档案与科目管理页面
  1286|
  1287|**Objective:** 配置当前年级，并增删改查科目
  1288|
  1289|**Files:**
  1290|- Create: `MistakeMate/Views/Settings/StudyProfileView.swift`
  1291|- Create: `MistakeMate/Views/Settings/SubjectManageView.swift`
  1292|- Modify: `AppSettings.swift` 或 `SettingsStore.swift` → 保存当前年级
  1293|
  1294|**Implementation:**
  1295|- 提供年级选择器，如：七年级 / 八年级 / 九年级 / 高一 / 高二 / 高三
  1296|- 年级修改后，后续错题分析与相似题生成自动使用新配置
  1297|- 科目管理保持原有 CRUD
  1298|
  1299|**Verification:** 修改年级 → 新的错题分析 prompt 使用新年级；添加新科目 → 错题录入可选新科目
  1300|
  1301|---
  1302|
  1303|### Task 5.3: 错题复习模式
  1304|
  1305|**Objective:** 随机抽题闪卡复习
  1306|
  1307|**Files:**
  1308|- Create: `MistakeMate/Views/MistakeBook/MistakeReviewView.swift`
  1309|
  1310|功能：
  1311|- 科目选择 → 随机抽题
  1312|- 先显示题目 → 点击翻面 → 显示答案/分析/防错金句
  1313|- "下一题"按钮
  1314|- 进度计数（3/15）
  1315|
  1316|**Verification:** 进入复习 → 题目随机 → 翻面显示分析
  1317|
  1318|---
  1319|
  1320|### Task 5.4: 举一反三练习集生成与保存
  1321|
  1322|**Objective:** 基于单条错题生成 3~5 道相似题，并默认保存为可重复查看的练习集
  1323|
  1324|**Files:**
  1325|- Create: `MistakeMate/Models/PracticeSet.swift`
  1326|- Create: `MistakeMate/Models/PracticeItem.swift`
  1327|- Modify: `MistakeMate/Services/GeminiService.swift` → 新增 `generateSimilarExercises(...)`
  1328|- Create: `MistakeMate/Views/MistakeBook/SimilarExercisesView.swift`
  1329|- Modify: `MistakeMate/Views/MistakeBook/MistakeDetailView.swift` → 添加“举一反三”按钮与历史练习集入口
  1330|
  1331|**Implementation:**
  1332|- 输入：错题内容、知识点、丢分点、当前年级配置
  1333|- 输出：3~5 道相似题，每题包含 `question`、`hint`、`answer`、`explanation`、`difficulty`
  1334|- 每次生成后默认保存一个 `PracticeSet`
  1335|- `PracticeSet` 记录 `gradeSnapshot`，确保升级年级后旧练习仍保留生成时上下文
  1336|- 练习页支持“查看提示”“查看答案”“再来一组”
  1337|- 再来一组时新建一组 `PracticeSet`，不覆盖旧记录
  1338|- 历史练习集支持删除，删除前弹确认
  1339|- 练习集支持状态：未开始 / 进行中 / 已完成 / 已归档
  1340|
  1341|**Verification:**
  1342|- 进入错题详情 → 点击“举一反三” → 成功生成并保存一组练习集
  1343|- 返回错题详情可看到历史练习集数量
  1344|- 点击历史练习集可重新进入并继续练习
  1345|- 再来一组后新增第二组，不覆盖第一组
  1346|- 删除某组练习集后数量立即更新，且删除前有确认弹窗
  1347|
  1348|---
  1349|
  1350|### Task 5.5: PDF 导出
  1351|
  1352|**Objective:** 选中错题导出为 PDF
  1353|
  1354|**Files:**
  1355|- Create: `MistakeMate/Services/PDFExporter.swift`
  1356|
  1357|使用 UIKit 的 `UIGraphicsPDFRenderer` 生成 PDF。
  1358|
  1359|**Verification:** 导出 → 分享 Sheet 出现 → 可保存/分享 PDF
  1360|
  1361|---
  1362|
  1363|### ✅ Task 5.6: 设置页面 + 关于页面
  1364|
  1365|**Objective:** 完整的设置导航
  1366|
  1367|**Files:**
  1368|- Modify: `MistakeMate/Views/Settings/SettingsView.swift`
  1369|
  1370|导航项：
  1371|- API Key 配置
  1372|- 学习档案（当前年级）
  1373|- 科目管理
  1374|- 数据统计（错题总数、各科目数量）
  1375|- 关于（版本号、开源许可）
  1376|
  1377|**Verification:** 所有设置入口可点击跳转
  1378|
  1379|---
  1380|
  1381|## Phase 6: 打磨 [3 tasks]
  1382|
  1383|### Task 6.1: UI 风格统一
  1384|
  1385|**Objective:** 全局配色、字体、圆角风格
  1386|
  1387|参考 study-sprint 配色：
  1388|- 背景: `#F5F5F0`
  1389|- 主色: `#5A5A40`
  1390|- 文字: `#333333`
  1391|- 次要文字: `#8E9299`
  1392|- 卡片: 白色 + `rounded-xl` + 轻阴影
  1393|
  1394|**Files:** 调整所有 View 的配色
  1395|
  1396|---
  1397|
  1398|### Task 6.2: 错误处理 + Toast
  1399|
  1400|**Objective:** 网络错误、API 错误提示
  1401|
  1402|创建 Toast 组件，API 调用失败时弹出提示。
  1403|
  1404|---
  1405|
  1406|### Task 6.3: App Icon + 启动图
  1407|
  1408|**Objective:** 生成 App 图标（SF Symbols 或简单图片）
  1409|
  1410|---
  1411|
  1412|## 可测试性检查清单
  1413|
  1414|- [ ] 无 API Key 时，错题录入提示"请先配置 API Key"
  1415|- [ ] 图片过大时自动压缩
  1416|- [ ] 空错题本显示占位引导
  1417|- [ ] 科目筛选 + 搜索联动正确
  1418|- [ ] 对话历史持久化，杀进程重启不丢失
  1419|- [ ] API 超时（30s）后显示错误而不是一直转圈
  1420|- [ ] 删除科目不级联删除错题（nullify）
  1421|
  1422|---
  1423|
  1424|## 已知风险
  1425|
  1426|1. **marked.js + KaTeX CDN**：离线时 WebView 无法加载 CDN 资源。解决方案：首次启动预下载到本地，或使用本地 bundle
  1427|2. **Gemini API 地域限制**：国内可能需要代理才能访问 `generativelanguage.googleapis.com`
  1428|3. **SwiftData 多线程**：`ModelContext` 不是线程安全的，确保所有操作在主线程或使用 `@MainActor`
  1429|