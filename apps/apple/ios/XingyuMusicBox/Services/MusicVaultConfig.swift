import Foundation

struct OpenApiCredential: Equatable {
    let accessKey: String
    let secretKey: String
}

struct MusicVaultConfig: Equatable {
    static let defaultBaseURLString = "http://192.168.31.101:8080"
    static let openAPIPathPrefix = "/api/open/v1"

    let baseURL: URL
    let credential: OpenApiCredential?

    static var `default`: MusicVaultConfig {
        if let local = MusicVaultConfig.localOpenApiConfig() {
            return local
        }
        return MusicVaultConfig(baseURLString: defaultBaseURLString)
    }

    init(baseURL: URL, credential: OpenApiCredential? = nil) {
        self.baseURL = baseURL
        self.credential = credential
    }

    init(baseURLString: String, credential: OpenApiCredential? = nil) {
        guard let url = URL(string: baseURLString) else {
            self.baseURL = URL(string: Self.defaultBaseURLString)!
            self.credential = credential
            return
        }
        self.baseURL = url
        self.credential = credential
    }

    private static func localOpenApiConfig() -> MusicVaultConfig? {
        guard let url = Bundle.main.url(forResource: "OpenApiConfig", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),
              let dictionary = plist as? [String: Any] else {
            return nil
        }

        let baseURLString = (dictionary["baseUrl"] as? String)?.nilIfBlank ?? defaultBaseURLString
        let accessKey = (dictionary["accessKey"] as? String)?.nilIfBlank
        let secretKey = (dictionary["secretKey"] as? String)?.nilIfBlank
        let credential = accessKey.flatMap { accessKey in
            secretKey.map { OpenApiCredential(accessKey: accessKey, secretKey: $0) }
        }
        return MusicVaultConfig(baseURLString: baseURLString, credential: credential)
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
