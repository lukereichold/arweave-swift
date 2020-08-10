import Foundation
import Moya

extension String: Error { }

struct HttpClient {
    static let provider = MoyaProvider<API>()

    static func request(_ target: API,
                        shouldFilterStatusCodes: Bool = true,
                        success successCallback: @escaping (Response) -> Void,
                        error errorCallback: @escaping (Swift.Error) -> Void) {

        provider.request(target) { result in
            switch result {
            case .success(let moyaResponse):
                do {
                    let response = shouldFilterStatusCodes ? try moyaResponse.filterSuccessfulStatusCodes() : moyaResponse
                    successCallback(response)
                } catch {
                    let error = NSError(domain: "com.arweave.sdk", code: 0, userInfo: [NSLocalizedDescriptionKey: "Bad response code: \(moyaResponse.statusCode)"])
                    errorCallback(error)
                }
            case .failure(let error):
                errorCallback(error)
            }
        }
    }
}
