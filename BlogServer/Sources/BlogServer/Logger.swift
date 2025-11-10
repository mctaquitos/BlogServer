import Foundation

enum Logger {
    static func info(_ message: String) {
        print("[INFO] \(timestamp()) \(message)")
    }

    static func error(_ message: String) {
        fputs("[ERROR] \(timestamp()) \(message)\n", stderr)
    }

    private static func timestamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f.string(from: Date())
    }
}
