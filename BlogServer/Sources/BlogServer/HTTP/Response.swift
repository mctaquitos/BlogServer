import Foundation
import NIOHTTP1

struct Response {
    var status: HTTPResponseStatus
    var headers: HTTPHeaders
    var body: String

    static func json<T: Encodable>(_ value: T, status: HTTPResponseStatus = .ok) -> Response {
        let data = (try? JSONEncoder().encode(value)) ?? Data("{}".utf8)
        let body = String(decoding: data, as: UTF8.self)
        var headers = HTTPHeaders()
        headers.add(name: "Content-Type", value: "application/json; charset=utf-8")
        return Response(status: status, headers: headers, body: body)
    }

    static func html(_ body: String, status: HTTPResponseStatus = .ok) -> Response {
        var headers = HTTPHeaders()
        headers.add(name: "Content-Type", value: "text/html; charset=utf-8")
        return Response(status: status, headers: headers, body: body)
    }

    static func notFound() -> Response {
        Response.html("<h1>404 Not Found</h1>", status: .notFound)
    }
}
