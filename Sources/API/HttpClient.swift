import Foundation

extension String: Error { }

public struct HttpResponse {
    let data: Data
    let statusCode: Int
}

struct HttpClient {

    static func request(_ target: Arweave.Request) async throws -> HttpResponse {
        
        var request = URLRequest(url: target.url)
        request.httpMethod = target.method
        request.httpBody = target.body
        if request.httpMethod?.uppercased() == "POST" {
            request.allHTTPHeaderFields = target.headers
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        let httpResponse = response as? HTTPURLResponse
        let statusCode = httpResponse?.statusCode ?? 0
        
        if case .transactionStatus = target.route {}
        else if statusCode != 200 {
            throw "Bad response code \(statusCode)"
        }
        
        return HttpResponse(data: data, statusCode: statusCode)
    }
}
