import Foundation

struct MusicVaultConfig: Equatable {
    static let defaultBaseURLString = "http://192.168.31.101:8080"
    static let openAPIPathPrefix = "/api/open/v1"

    let baseURL: URL
    let apiToken: String?

    static var `default`: MusicVaultConfig {
        MusicVaultConfig(baseURLString: defaultBaseURLString)
    }

    init(baseURL: URL, apiToken: String? = nil) {
        self.baseURL = baseURL
        self.apiToken = apiToken?.nilIfBlank
    }

    init(baseURLString: String, apiToken: String? = nil) {
        guard let url = URL(string: baseURLString) else {
            self.baseURL = URL(string: Self.defaultBaseURLString)!
            self.apiToken = apiToken?.nilIfBlank
            return
        }
        self.baseURL = url
        self.apiToken = apiToken?.nilIfBlank
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
