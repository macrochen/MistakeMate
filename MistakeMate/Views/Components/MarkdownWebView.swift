import SwiftUI
import WebKit

struct MarkdownWebView: UIViewRepresentable {
    let markdown: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let templatePath = Bundle.main.path(forResource: "markdown-template", ofType: "html"),
              let template = try? String(contentsOfFile: templatePath, encoding: .utf8) else {
            webView.loadHTMLString("<p style='color:red'>模板加载失败</p>", baseURL: nil)
            return
        }

        let escaped = markdown
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")

        let html = template.replacingOccurrences(of: "__MARKDOWN_CONTENT__", with: escaped)
        webView.loadHTMLString(html, baseURL: nil)
    }
}
