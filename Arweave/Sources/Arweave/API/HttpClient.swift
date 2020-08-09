import Foundation
import Moya

extension String: Error { }

struct HttpClient {
    static let provider = MoyaProvider<API>()
    
    static func request(target: API,
                        success successCallback: @escaping (Response) -> Void,
                        error errorCallback: @escaping (Swift.Error) -> Void) {
        
        provider.request(target) { (result) in
            switch result {
            case .success(let moyaResponse):
                do {
                    let filteredResponse = try moyaResponse.filterSuccessfulStatusCodes()
                    successCallback(filteredResponse)
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