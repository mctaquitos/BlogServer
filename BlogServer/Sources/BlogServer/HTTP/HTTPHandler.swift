import NIO
import NIOHTTP1

final class HTTPHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart

    private var head: HTTPRequestHead?

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let part = unwrapInboundIn(data)

        switch part {
        case .head(let requestHead):
            self.head = requestHead
        case .body:
            break
        case .end:
            guard let head = self.head else { return }
            Logger.info("\(head.method.rawValue) \(head.uri)")
            let response = Router.route(head)
            write(response, on: context)
            self.head = nil
        }
    }

    private func write(_ response: Response, on context: ChannelHandlerContext) {
        var headers = response.headers
        headers.add(name: "Content-Length", value: "\(response.body.utf8.count)")
        headers.add(name: "Connection", value: "close")

        let head = HTTPResponseHead(version: .http1_1, status: response.status, headers: headers)

        context.write(wrapOutboundOut(.head(head)), promise: nil)
        var buffer = context.channel.allocator.buffer(capacity: response.body.utf8.count)
        buffer.writeString(response.body)
        context.write(wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
        context.writeAndFlush(wrapOutboundOut(.end(nil))).whenComplete { _ in
            context.close(promise: nil)
        }
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        Logger.error("Pipeline error: \(error)")
        context.close(promise: nil)
    }
}
