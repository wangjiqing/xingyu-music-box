import Foundation

struct OpenApiCredential: Codable, Equatable {
    let accessKey: String
    let secretKey: String
}

struct MusicVaultConfig: Codable, Equatable {
    static let defaultBaseURLString = ""
    static let endpointPlaceholder = "https://your-music-vault.example.com"
    static let openAPIPathPrefix = "/api/open/v1"

    let baseURL: URL?
    let credential: OpenApiCredential?

    static var `default`: MusicVaultConfig {
        #if os(macOS)
        if let runtime = try? VaultConnectionConfigurationStore.shared.loadMusicVaultConfig() {
            return runtime
        }
        if let user = MusicVaultConfig.userOpenApiConfig() {
            return user
        }
        #else
        if let runtime = try? VaultConnectionConfigurationStore.shared.loadMusicVaultConfig() {
            return runtime
        }
        if let stored = try? VaultConnectionConfigurationStore.shared.loadConfiguration(), stored.isConfigured {
            return MusicVaultConfig(baseURLString: stored.baseURLString)
        }
        #endif
        #if DEBUG
        if let local = MusicVaultConfig.localOpenApiConfig() {
            return local
        }
        #endif
        return MusicVaultConfig(baseURLString: defaultBaseURLString)
    }

    #if os(macOS)
    static var sharedConfigurationURL: URL {
        URL(fileURLWithPath: "/Library/Application Support", isDirectory: true)
            .appendingPathComponent("XingyuMusicBox", isDirectory: true)
            .appendingPathComponent("OpenApiConfig.plist", isDirectory: false)
    }

    static var userConfigurationURL: URL? {
        guard let supportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        return supportURL
            .appendingPathComponent("XingyuMusicBox", isDirectory: true)
            .appendingPathComponent("OpenApiConfig.plist", isDirectory: false)
    }

    static var userConfigurationPath: String {
        writableConfigurationURL()?.path
            ?? existingConfigurationURLs().first?.path
            ?? sharedConfigurationURL.path
    }
    #endif

    init(baseURL: URL?, credential: OpenApiCredential? = nil) {
        self.baseURL = baseURL
        self.credential = credential
    }

    init(baseURLString: String, credential: OpenApiCredential? = nil) {
        let baseURLString = baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !baseURLString.isEmpty else {
            self.baseURL = nil
            self.credential = credential
            return
        }
        guard let url = URL(string: baseURLString) else {
            self.baseURL = nil
            self.credential = credential
            return
        }
        self.baseURL = url
        self.credential = credential
    }

    #if os(macOS)
    static func saveUserConfiguration(baseURLString: String, accessKey: String, secretKey: String) throws {
        let baseURLString = try VaultConnectionConfigurationStore.normalizedBaseURLString(baseURLString)
        let accessKey = accessKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let secretKey = secretKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !accessKey.isEmpty, !secretKey.isEmpty else {
            throw MusicVaultConfigurationError.missingCredential
        }
        _ = try VaultConnectionConfigurationStore.shared.save(
            baseURLString: baseURLString,
            accessKey: accessKey,
            secretKey: secretKey
        )
        guard let url = writableConfigurationURL() ?? userConfigurationURL else {
            throw MusicVaultConfigurationError.configurationPathUnavailable
        }

        let config = StoredMusicVaultConfig(
            baseURLString: baseURLString,
            accessKey: accessKey,
            secretKey: secretKey
        )
        let data = try PropertyListEncoder().encode(config)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o700],
            ofItemAtPath: url.deletingLastPathComponent().path
        )
        try data.write(to: url, options: .atomic)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: url.path
        )
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
        for url in existingConfigurationURLs() {
            guard let config = loadUserOpenApiConfig(from: url) else { continue }
            return config
        }
        return nil
    }

    private static func loadUserOpenApiConfig(from url: URL) -> MusicVaultConfig? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = PropertyListDecoder()
        if let stored = try? decoder.decode(StoredMusicVaultConfig.self, from: data) {
            let credential = stored.accessKey.flatMap { accessKey in
                stored.secretKey.map { OpenApiCredential(accessKey: accessKey, secretKey: $0) }
            }
            if credential == nil,
               let runtime = try? VaultConnectionConfigurationStore.shared.loadMusicVaultConfig(),
               runtime.baseURL?.absoluteString == MusicVaultConfig(baseURLString: stored.baseURLString).baseURL?.absoluteString,
               runtime.credential?.accessKey == stored.accessKey {
                return runtime
            }
            return MusicVaultConfig(
                baseURLString: stored.baseURLString,
                credential: credential
            )
        }

        guard let legacy = try? decoder.decode(LegacyMusicVaultConfig.self, from: data) else {
            return nil
        }
        if let credential = legacy.credential {
            try? saveUserConfiguration(
                baseURLString: legacy.baseURL.absoluteString,
                accessKey: credential.accessKey,
                secretKey: credential.secretKey
            )
        }
        return MusicVaultConfig(
            baseURL: legacy.baseURL,
            credential: legacy.credential
        )
    }

    private static func existingConfigurationURLs() -> [URL] {
        [sharedConfigurationURL, userConfigurationURL]
            .compactMap { $0 }
            .filter { FileManager.default.fileExists(atPath: $0.path) }
    }

    private static func writableConfigurationURL() -> URL? {
        let fileManager = FileManager.default
        let sharedDirectoryURL = sharedConfigurationURL.deletingLastPathComponent()

        if fileManager.fileExists(atPath: sharedDirectoryURL.path),
           fileManager.isWritableFile(atPath: sharedDirectoryURL.path) {
            return sharedConfigurationURL
        }

        if fileManager.fileExists(atPath: sharedConfigurationURL.path),
           fileManager.isWritableFile(atPath: sharedConfigurationURL.path) {
            return sharedConfigurationURL
        }

        return userConfigurationURL
    }
    #endif
}

#if os(macOS)
private struct StoredMusicVaultConfig: Codable {
    let baseURLString: String
    let accessKey: String?
    let secretKey: String?
}

private struct LegacyMusicVaultConfig: Codable {
    let baseURL: URL
    let credential: OpenApiCredential?
}

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
