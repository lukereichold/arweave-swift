import Foundation

extension String {
    var base64URLEncoded: String {
        Data(utf8).base64URLEncodedString()
    }
}
