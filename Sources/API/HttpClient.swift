import Foundation

extension String: Error { }

public struct HttpResponse {
    public let data: Data
    public let statusCode: Int
}

struct HttpClient {

    static func request(_ target: Arweave.Request) async throws -> HttpResponse {
        
        var request = URLRequest(url: target.url)
        request.httpMethod = target.method
        request.httpBody = target.body
        request.allHTTPHeaderFields = target.headers
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode ?? 0
        
        if case .transactionStatus = target.route {}
        
        return HttpResponse(data: data, statusCode: statusCode)
    }
}
