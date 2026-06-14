import CryptoKit
import Foundation

enum OpenApiSigningError: LocalizedError {
    case missingCredential
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .missingCredential:
            return "OpenAPI AK/SK 未配置，请检查本地 OpenApiConfig.plist。"
        case .invalidURL:
            return "OpenAPI 签名请求地址无效。"
        }
    }
}

struct OpenApiHmacSigner {
    static let signatureVersion = "v1"

    let credential: OpenApiCredential
    var now: () -> Date = Date.init
    var nonce: () -> String = { UUID().uuidString }

    func signedHeaders(
        method: String,
        url: URL,
        body: Data? = nil
    ) throws -> [String: String] {
        let timestamp = String(Int64(now().timeIntervalSince1970 * 1000))
        let nonce = nonce()
        let bodyHash = Self.sha256Hex(body ?? Data())
        let canonical = [
            method.uppercased(),
            try Self.canonicalPathWithQuery(url: url),
            bodyHash,
            timestamp,
            nonce
        ].joined(separator: "\n")

        return [
            "X-Xingyu-Access-Key": credential.accessKey,
            "X-Xingyu-Timestamp": timestamp,
            "X-Xingyu-Nonce": nonce,
            "X-Xingyu-Signature-Version": Self.signatureVersion,
            "X-Xingyu-Signature": Self.hmacSha256Hex(secret: credential.secretKey, message: canonical)
        ]
    }

    static func canonicalPathWithQuery(url: URL) throws -> String {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw OpenApiSigningError.invalidURL
        }

        let path = components.percentEncodedPath.isEmpty ? "/" : components.percentEncodedPath
        let queryItems = components.queryItems ?? []
        guard !queryItems.isEmpty else {
            return path
        }

        let query = queryItems
            .map { QueryPart(name: $0.name, value: $0.value ?? "") }
            .sorted {
                if $0.name == $1.name {
                    return $0.value < $1.value
                }
                return $0.name < $1.name
            }
            .map { "\(Self.formEncoded($0.name))=\(Self.formEncoded($0.value))" }
            .joined(separator: "&")

        return query.isEmpty ? path : "\(path)?\(query)"
    }

    private static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private static func hmacSha256Hex(secret: String, message: String) -> String {
        let key = SymmetricKey(data: Data(secret.utf8))
        let signature = HMAC<SHA256>.authenticationCode(for: Data(message.utf8), using: key)
        return signature.map { String(format: "%02x", $0) }.joined()
    }

    private static func formEncoded(_ value: String) -> String {
        var allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")
        allowed.insert(charactersIn: "-._*")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
    }

    private struct QueryPart {
        let name: String
        let value: String
    }
}
