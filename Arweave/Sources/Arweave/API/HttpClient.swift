import Foundation
import Moya

extension String: Error { }

struct HttpClient {
    static let provider = MoyaProvider<API>()

    static func request(_ target: API,
                        callbackQueue: DispatchQueue? = .none,
                        shouldFilterStatusCodes: Bool = true,
                        completion: @escaping (Result<Response, Error>) -> Void) {

        provider.request(target, callbackQueue: callbackQueue) { result in
            switch result {
            case .success(let moyaResponse):
                do {
                    let response = shouldFilterStatusCodes ? try moyaResponse.filterSuccessfulStatusCodes() : moyaResponse
                    completion(.success(response))
                } catch {
                    let error = NSError(domain: "com.arweave.sdk", code: 0, userInfo: [NSLocalizedDescriptionKey: "Bad response code: \(moyaResponse.statusCode)"])
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
