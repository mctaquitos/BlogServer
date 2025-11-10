import Foundation

struct Config {
    let host: String
    let port: Int
    let contentDirectory: String

    static func load() -> Config {
        let env = ProcessInfo.processInfo.environment
        let host = env["BLOGSERVER_HOST"] ?? "0.0.0.0"
        let port = Int(env["BLOGSERVER_PORT"] ?? "") ?? 8080
        let cliContentDir = CommandLine.arguments.dropFirst().first
        let contentDir = cliContentDir ?? env["BLOGSERVER_CONTENT_DIR"] ?? "Content"
        return Config(host: host, port: port, contentDirectory: contentDir)
    }
}
