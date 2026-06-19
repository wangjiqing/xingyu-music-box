import Foundation

struct OpenApiCredential: Codable, Equatable {
    let accessKey: String
    let secretKey: String
}

struct MusicVaultConfig: Codable, Equatable {
    static let defaultBaseURLString = "https://www.oceanofstars.com.cn:18443"
    static let openAPIPathPrefix = "/api/open/v1"

    let baseURL: URL
    let credential: OpenApiCredential?

    static var `default`: MusicVaultConfig {
        #if os(macOS)
        if let user = MusicVaultConfig.userOpenApiConfig() {
            return user
        }
        #endif
        if let local = MusicVaultConfig.localOpenApiConfig() {
            return local
        }
        return MusicVaultConfig(baseURLString: defaultBaseURLString)
    }

    #if os(macOS)
    static var userConfigurationURL: URL? {
        guard let supportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        return supportURL
            .appendingPathComponent("XingyuMusicBox", isDirectory: true)
            .appendingPathComponent("OpenApiConfig.plist", isDirectory: false)
    }

    static var userConfigurationPath: String {
        userConfigurationURL?.path ?? "Application Support/XingyuMusicBox/OpenApiConfig.plist"
    }
    #endif

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

    #if os(macOS)
    static func saveUserConfiguration(baseURLString: String, accessKey: String, secretKey: String) throws {
        let baseURLString = baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        let accessKey = accessKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let secretKey = secretKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard URL(string: baseURLString) != nil else {
            throw MusicVaultConfigurationError.invalidBaseURL
        }
        guard !accessKey.isEmpty, !secretKey.isEmpty else {
            throw MusicVaultConfigurationError.missingCredential
        }
        guard let url = userConfigurationURL else {
            throw MusicVaultConfigurationError.configurationPathUnavailable
        }

        let config = MusicVaultConfig(
            baseURLString: baseURLString,
            credential: OpenApiCredential(accessKey: accessKey, secretKey: secretKey)
        )
        let data = try PropertyListEncoder().encode(config)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: url, options: .atomic)
    }
    #endif

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

    #if os(macOS)
    private static func userOpenApiConfig() -> MusicVaultConfig? {
        guard let url = userConfigurationURL,
              let data = try? Data(contentsOf: url),
              let config = try? PropertyListDecoder().decode(MusicVaultConfig.self, from: data) else {
            return nil
        }
        return config
    }
    #endif
}

#if os(macOS)
enum MusicVaultConfigurationError: LocalizedError {
    case invalidBaseURL
    case missingCredential
    case configurationPathUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return "星语音库连接地址无效。"
        case .missingCredential:
            return "请同时填写 Access Key 和 Secret Key。"
        case .configurationPathUnavailable:
            return "无法定位用户配置目录。"
        }
    }
}
#endif

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
