import Foundation
import Security

struct VaultConnectionConfiguration: Codable, Equatable {
    let baseURLString: String
    let accessKey: String
    let isConfigured: Bool

    var baseURL: URL? {
        URL(string: baseURLString)
    }
}

enum VaultConnectionConfigurationError: LocalizedError, Equatable {
    case invalidBaseURL
    case missingBaseURL
    case incompleteCredential
    case missingRuntimeSecretKey
    case configurationDirectoryUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return "服务地址必须以 http:// 或 https:// 开头。"
        case .missingBaseURL:
            return "服务地址不能为空。"
        case .incompleteCredential:
            return "Access Key 和 Secret Key 必须成对填写。"
        case .missingRuntimeSecretKey:
            return "Secret Key 仅保存在本次运行内存中，请重新输入后再连接。"
        case .configurationDirectoryUnavailable:
            return "无法定位应用配置目录。"
        }
    }
}

final class VaultConnectionConfigurationStore {
    static let shared = VaultConnectionConfigurationStore()

    private let fileManager: FileManager
    private let encoder = PropertyListEncoder()
    private let decoder = PropertyListDecoder()
    private var runtimeSecretKey: String?

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func loadConfiguration() throws -> VaultConnectionConfiguration? {
        guard let url = configurationURL(createDirectory: false),
              fileManager.fileExists(atPath: url.path) else {
            return nil
        }
        let data = try Data(contentsOf: url)
        return try decoder.decode(VaultConnectionConfiguration.self, from: data)
    }

    func loadMusicVaultConfig() throws -> MusicVaultConfig? {
        guard let configuration = try loadConfiguration(), configuration.isConfigured else {
            return nil
        }
        guard let secretKey = runtimeSecretKey?.nilIfBlank else {
            return nil
        }
        return MusicVaultConfig(
            baseURLString: configuration.baseURLString,
            credential: OpenApiCredential(accessKey: configuration.accessKey, secretKey: secretKey)
        )
    }

    func hasRuntimeSecretKey() -> Bool {
        runtimeSecretKey?.nilIfBlank != nil
    }

    func save(baseURLString: String, accessKey: String, secretKey: String) throws -> VaultConnectionConfiguration {
        let normalizedBaseURL = try Self.normalizedBaseURLString(baseURLString)
        let accessKey = accessKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let secretKey = secretKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !accessKey.isEmpty, !secretKey.isEmpty else {
            throw VaultConnectionConfigurationError.incompleteCredential
        }

        runtimeSecretKey = secretKey
        let configuration = VaultConnectionConfiguration(
            baseURLString: normalizedBaseURL,
            accessKey: accessKey,
            isConfigured: true
        )
        try save(configuration)
        return configuration
    }

    func clear() throws {
        runtimeSecretKey = nil
        if let url = configurationURL(createDirectory: false), fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
        deleteLegacyKeychainSecretIfPresent()
    }

    static func normalizedBaseURLString(_ value: String) throws -> String {
        var trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw VaultConnectionConfigurationError.missingBaseURL
        }
        while trimmed.count > 1 && trimmed.hasSuffix("/") {
            trimmed.removeLast()
        }
        guard let components = URLComponents(string: trimmed),
              let scheme = components.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              components.host?.nilIfBlank != nil,
              URL(string: trimmed) != nil else {
            throw VaultConnectionConfigurationError.invalidBaseURL
        }
        return trimmed
    }

    private func save(_ configuration: VaultConnectionConfiguration) throws {
        guard let url = configurationURL(createDirectory: true) else {
            throw VaultConnectionConfigurationError.configurationDirectoryUnavailable
        }
        let data = try encoder.encode(configuration)
        try data.write(to: url, options: .atomic)
    }

    private func configurationURL(createDirectory: Bool) -> URL? {
        guard let supportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let directory = supportURL.appendingPathComponent("XingyuMusicBox", isDirectory: true)
        if createDirectory, !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory.appendingPathComponent("VaultConnectionConfig.plist", isDirectory: false)
    }

    private func deleteLegacyKeychainSecretIfPresent() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.xingyu.musicbox.openapi",
            kSecAttrAccount as String: "xingyu-music-vault-secret-key"
        ]
        SecItemDelete(query as CFDictionary)
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
