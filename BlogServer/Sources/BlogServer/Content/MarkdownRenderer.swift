import Foundation

enum MarkdownRenderer {
    static func render(_ markdown: String) -> String {
        var html = ""
        let lines = markdown.split(whereSeparator: \ .isNewline, omittingEmptySubsequences: false)
        var inParagraph = false

        func close() { if inParagraph { html += "</p>\n"; inParagraph = false } }

        for lineSub in lines {
            let line = String(lineSub)
            if line.trimmingCharacters(in: .whitespaces).isEmpty { close(); continue }
            if line.hasPrefix("# ") {
                close(); html += "<h1>\(escape(String(line.dropFirst(2))))</h1>\n"
            } else if line.hasPrefix("## ") {
                close(); html += "<h2>\(escape(String(line.dropFirst(3))))</h2>\n"
            } else {
                if !inParagraph { html += "<p>"; inParagraph = true } else { html += " " }
                html += escape(line)
            }
        }
        close(); return html
    }

    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "<", with: "&lt;")
         .replacingOccurrences(of: ">", with: "&gt;")
    }
}
