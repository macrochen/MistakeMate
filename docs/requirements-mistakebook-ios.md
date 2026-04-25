# 错题助手 iOS App — 需求文档

> 版本: v1.0 | 日期: 2026-04-25 | 作者: Hermes Agent

---

## 1. 项目概述

### 1.1 项目背景

基于现有 study-sprint（Web 端备考冲刺工具）的错题本 + AI 助手功能经验，开发一款纯本地 iOS 错题管理 App。

### 1.2 核心定位

**以 AI 驱动的个人错题管理工具。** 拍照即录入，Gemini 自动识别错题、分析错因、给出防错提醒。内置 AI 问答助手，可基于错题历史提供针对性辅导。

### 1.3 目标用户

- 个人使用，不上架 App Store
- 无需账号系统、无需网络同步
- 最低支持 iOS 17.0（SwiftData 要求）

---

## 2. 技术选型

| 层级 | 技术 | 理由 |
|------|------|------|
| UI 框架 | SwiftUI | 声明式、代码量少、与 SwiftData 天然集成 |
| 数据持久化 | SwiftData | iOS 17+ 原生方案，零配置、自动 iCloud 可选 |
| AI 服务 | Google Gemini API (`generative-ai-swift`) | 多模态支持，直接调 API |
| 图片处理 | PhotosUI + UIKit interop | 拍照/相册选取 |
| 网络层 | URLSession + async/await | 轻量，无需第三方 |
| 架构模式 | MVVM | 适合 SwiftUI + SwiftData 组合 |
| 最低版本 | iOS 17.0 | SwiftData 硬性要求 |

---

## 3. 功能需求

### 3.1 错题本（MistakeBook）— 核心模块

#### 3.1.1 错题录入

- **拍照录入**：调用系统相机拍照 → 压缩图片 → 发送给 Gemini 识别
  - Gemini 自动识别图片中所有题目，区分对错
  - 对每道错题输出：题目内容、错误类型、解题分析、防错金句
  - 支持多题拆分（一张图多道错题 → 多条记录）
- **相册录入**：从相册选择已有截图/照片，流程同上
- **手动录入**：纯文本输入错题内容，可选配图片


#### 3.1.2 错题管理

- **列表视图**：按时间倒序展示，每条显示科目标签、错误类型、题目摘要
- **筛选**：按科目、错误类型（不会/不熟/粗心/审题错/记忆错乱）筛选
- **搜索**：全文搜索错题内容
- **详情查看**：完整题目、分析过程、防错金句、原图
- **编辑**：修改科目、内容、分析等字段
- **删除**：滑动删除，带确认

#### 3.1.3 错题复习

- **随机复习**：从错题本随机抽题，类似闪卡
- **按科目复习**：选定科目后随机出题
- **复习模式**：先看题目 → 点击显示答案/分析

#### 3.1.4 举一反三巩固

- **相似题生成**：在错题详情页提供"举一反三"按钮，基于当前错题生成 3~5 道相似题
- **练习集保存**：每次生成后默认保存为一组独立的"练习集"，可重复查看和继续练习
- **题目梯度**：优先生成同知识点、同题型，难度从基础到进阶逐步提升
- **题目结构**：每道题包含题目、提示、答案、解析
- **针对性巩固**：相似题围绕当前错题的丢分点和知识点展开
- **重新生成**：支持一键再生成一组新的练习集
- **历史练习集**：可查看某道错题已经生成过的历史练习集
- **练习集删除**：支持删除某一组已生成练习集，删除前必须二次确认
- **状态管理**：练习集支持未开始 / 进行中 / 已完成 / 已归档

### 3.2 AI 问答助手（Chat）

- 类 ChatGPT 对话界面
- 支持纯文本对话
- **图片附件**：支持拍照或从相册上传图片，让 AI 分析题目内容
- **语音输入**：按住录音按钮录制语音，松开自动发送。Gemini 多模态可直接理解音频内容（参考 study-sprint 的 MediaRecorder 方案，iOS 端使用 AVAudioRecorder）
- **上下文感知**：可引用错题本中的错题作为对话上下文
- 对话历史本地持久化
- 支持新建对话、切换历史对话
- **提示词库下拉面板**：参考原 web 版交互，输入区附近通过下拉面板展开提示词库
- **默认提示词库**：按分类组织，如"解题助手 / 背诵复习 / 提分训练"
- **我的定制提示词**：支持新增、编辑、删除、点击填入输入框
- **提示词使用记录**：记录最近使用时间，定制提示词按最近使用优先展示

### 3.3 设置（Settings）

- **Gemini API Key 配置**：输入并验证 Key
  - 测试连接按钮
  - Key 存储在 Keychain（安全）
- **学习档案**：学生年级可配置，用于 AI 分析和题目生成
  - 年级由用户手动设置和随时修改
  - AI prompt 始终读取当前配置，禁止写死为"七年级"
- **科目管理**：自定义科目名称和颜色
  - 默认：语文、数学、英语、物理、化学、生物、历史、地理、政治
- **默认错误类型**：不会 / 会但不熟 / 粗心 / 审题错 / 记忆错乱
- **关于页面**：版本信息

### 3.4 数据导出

- 导出为 PDF（按科目/时间筛选）
- 分享到其他 App（系统分享 Sheet）

---

## 4. 数据模型

### 4.1 SwiftData Models

```swift
@Model
final class Subject {
    var name: String
    var colorHex: String          // "#FF6B6B"
    var sortOrder: Int
    
    @Relationship(deleteRule: .nullify)
    var mistakes: [Mistake]?
}

@Model
final class AppSettings {
    var currentGrade: String      // 当前年级，由用户配置
    var createdAt: Date
    var updatedAt: Date
}

@Model
final class Mistake {
    var content: String           // 题目内容
    var type: String              // 错误类型
    var textbookUnit: String?     // 对应课本单元
    var knowledgePoint: String?   // 对应知识点
    var scoreLossPoint: String?   // 主要丢分点
    var analysis: String          // 解题分析
    var preventionRule: String    // 防错金句
    var socraticQuestions: [String] // 苏格拉底式引导问题
    var source: String?           // 来源（试卷名/练习册）
    var notes: String?            // 额外备注
    var imageData: Data?          // 原图（压缩后 JPEG）
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship
    var subject: Subject?
}

@Model
final class ChatSession {
    var title: String             // 对话标题
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .cascade)
    var messages: [ChatMessage]?
}

@Model
final class ChatMessage {
    var role: String              // "user" / "assistant" / "system"
    var content: String
    var imageData: Data?          // 图片附件
    var audioData: Data?          // 语音附件（audio/m4a）
    var audioDuration: Double?    // 语音时长（秒）
    var createdAt: Date
    
    @Relationship
    var session: ChatSession?
}

@Model
final class PromptTemplate {
    var title: String             // 提示词标题
    var content: String           // 实际填入输入框的内容
    var category: String          // 默认: 我的定制
    var createdAt: Date
    var updatedAt: Date
    var lastUsedAt: Date?
}

@Model
final class PracticeSet {
    var title: String             // 如：数学-等差数列-第1组
    var gradeSnapshot: String     // 生成当时的年级快照
    var status: String            // 未开始 / 进行中 / 已完成 / 已归档
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship
    var mistake: Mistake?
    
    @Relationship(deleteRule: .cascade)
    var items: [PracticeItem]?
}

@Model
final class PracticeItem {
    var question: String
    var hint: String?
    var answer: String
    var explanation: String
    var difficulty: String
    var userAnswer: String?
    var isCompleted: Bool
    var sortOrder: Int
    
    @Relationship
    var practiceSet: PracticeSet?
}
```

### 4.2 数据关系

```
Subject ──1:N──> Mistake
Mistake ──1:N──> PracticeSet
PracticeSet ──1:N──> PracticeItem
AppSettings ── 单例配置，保存当前年级
ChatSession ──1:N──> ChatMessage
PromptTemplate ── 独立存储，用于提示词库与最近使用排序
```

---

## 5. UI 设计

### 5.1 导航结构

```
TabView
├── 错题本 (MistakeBook)
│   ├── 列表视图 (默认)
│   ├── 详情视图 (NavigationLink)
│   ├── 录入视图 (Sheet)
│   └── 复习模式 (Sheet)
├── AI助手 (Chat)
│   ├── 对话列表
│   ├── 对话详情
│   └── 新建对话
└── 设置 (Settings)
    ├── API Key 配置
    ├── 科目管理
    └── 关于
```

### 5.2 设计风格

- **配色**：暖色系为主（米白背景 `#F5F5F0`，主色调 `#5A5A40`，与 study-sprint 一致）
- **字体**：系统默认（SF Pro），标题可用衬线体
- **圆角卡片**：`rounded-xl` 风格，Shadow 轻阴影
- **图标**：SF Symbols
- **动画**：Navigation 过渡动画，列表加载渐入

### 5.3 关键交互

- 错题列表支持左右滑动（删除/编辑）
- 录入时显示 Gemini 分析进度（Loading + 步骤提示）
- AI 对话支持 Markdown 渲染（数学公式用 LaTeX）
- 长按错题卡片 → 弹出操作菜单（编辑/删除/加入复习/复制）

---

## 6. Gemini API 集成

### 6.1 API 调用场景

| 场景 | 模型 | 输入 | 输出 |
|------|------|------|------|
| 错题识别 | `gemini-2.0-flash` | 图片 + 提示词 | JSON（mistakes 数组） |
| 错题分析 | `gemini-2.0-flash` | 错题图片/文本 + 当前年级配置 + 提示词 | JSON（含教材单元、知识点、引导问题） |
| 相似题生成 | `gemini-2.0-flash` | 错题内容 + 丢分点 + 知识点 + 当前年级配置 | JSON（相似题数组） |
| AI 对话 | `gemini-2.0-flash` | 对话历史 + 文本/图片/语音 | 纯文本/Markdown |

### 6.2 错题识别 / 分析 Prompt 结构

```
系统指令：你是一个极其专业的错题分析专家。
用户输入：[错题图片或文字] + 年级 + 可选备注

核心要求：
1. 识别题目内容与学生出错位置
2. 判断主要丢分点
3. 把丢分点对应到课本具体单元和知识点
4. 给出清晰的解题分析
5. 用苏格拉底式提问，一步步引导孩子自己走向正确解题
6. 语言要适配当前设置的年级理解能力
7. 年级来自用户配置，不写死任何具体年级

要求输出 JSON：
{
  "mistakes": [
    {
      "content": "题目完整内容",
      "type": "不会 / 会但不熟 / 粗心 / 审题错 / 记忆错乱",
      "textbookUnit": "课本具体单元",
      "knowledgePoint": "具体知识点",
      "scoreLossPoint": "主要丢分点",
      "analysis": "解题步骤和正确答案",
      "preventionRule": "防错金句",
      "socraticQuestions": [
        "第1步引导提问",
        "第2步引导提问",
        "第3步引导提问"
      ]
    }
  ]
}
```

### 6.3 API Key 管理

- 存储位置：iOS Keychain（非 UserDefaults，确保安全）
- 验证方式：调用 Gemini API 发送 "Hi" 测试连接
- Key 格式校验：非空即可，错误由 API 返回捕获

---

## 7. 非功能需求

### 7.1 性能

- 图片压缩：拍照后压缩至最长边 1200px、JPEG 质量 0.7
- 错题列表：SwiftData `@Query` 自动响应式，支持 >1000 条流畅滚动
- AI 请求：30 秒超时，失败后显示错误提示

### 7.2 离线支持

- 所有功能离线可用（除了需要网络调 Gemini API 的部分）
- 错题查看、搜索、复习完全离线

### 7.3 安全性

- API Key 存 Keychain
- 无网络传输用户数据（仅发送当前请求的图片/文本给 Gemini）

### 7.4 数据容量

- 图片存储：单张 ≤ 500KB（压缩后）
- 总数据量预估：1000 条错题约 50-100MB（含图片）

---

## 8. 与 study-sprint 的差异总结

| 维度 | study-sprint | 错题助手 |
|------|-------------|---------|
| 平台 | Web (React + Vite) | iOS (SwiftUI) |
| 存储 | Firebase Firestore | SwiftData（本地） |
| 认证 | Google 登录 | 无（本地 App） |
| 功能 | 考试冲刺、每日计划、错题本、AI助手、知识库 | 错题本 + AI助手 |
| 图片 | 前端压缩后存 Firestore | 本地 Data 字段 |
| AI | 前端直调 Gemini | iOS 端直调 Gemini |

---

## 9. 开发阶段

### ✅ Phase 1：基础框架（MVP）

- [x] Xcode 项目初始化、SwiftData 配置
- [x] 科目管理（CRUD）
- [x] 错题数据模型 + 基础列表

### ✅ Phase 2：AI 集成

- [x] Gemini API 封装层
- [x] 错题拍照录入 + AI 识别
- [x] 手动录入

### Phase 3：AI 助手

- [ ] 对话界面
- [ ] 对话持久化
- [ ] 上下文引用错题

### Phase 4：完善

- [ ] 错题复习模式
- [ ] PDF 导出
- [ ] 搜索筛选
- [ ] 设置页面完善

---

## 10. 开放问题

1. **App 名称**：待定（错题助手 / MistakeMate / ErrorLog ?）
2. **数学公式渲染**：SwiftUI 中渲染 LaTeX 的方案？（KatexSwift / SwiftLaTeX / 或直接用图片渲染）
3. **是否需要 iCloud 同步**：当前不需求，但 SwiftData 天然支持，可后续开启
4. **教材版本**：若后续需要更精确映射"课本具体单元"，可以按科目补充教材版本配置
