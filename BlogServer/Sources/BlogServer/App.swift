import NIO
import NIOHTTP1
import Foundation

enum App {
    static func run() throws {
        let config = Config.load()
        DataStore.configure(contentDirectory: config.contentDirectory)

        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        defer { try? group.syncShutdownGracefully() }

        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(.backlog, value: 256)
            .serverChannelOption(.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline().flatMap {
                    channel.pipeline.addHandler(HTTPHandler())
                }
            }
            .childChannelOption(.socketOption(.so_reuseaddr), value: 1)
            .childChannelOption(.maxMessagesPerRead, value: 16)
            .childChannelOption(.recvAllocator, value: AdaptiveRecvByteBufferAllocator())

        let channel = try bootstrap.bind(host: config.host, port: config.port).wait()
        Logger.info("BlogServer running on \(config.host):\(config.port), content=\(config.contentDirectory)")
        try channel.closeFuture.wait()
    }
}
