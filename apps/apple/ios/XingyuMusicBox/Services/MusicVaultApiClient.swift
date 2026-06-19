import Foundation

enum MusicVaultApiError: LocalizedError {
    case invalidBaseURL
    case invalidURL
    case invalidResponse
    case notModified
    case signingFailed(Error)
    case server(statusCode: Int, response: MusicVaultErrorResponse?)
    case decodingFailed
    case networkFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return "星语音库地址无效。"
        case .invalidURL:
            return "星语音库请求地址拼接失败。"
        case .invalidResponse:
            return "星语音库返回了无效响应。"
        case .notModified:
            return "资源未变化。"
        case .signingFailed(let error):
            return error.localizedDescription
        case .server(let statusCode, let response):
            if statusCode == 401 || statusCode == 403 {
                let message = response?.message ?? "OpenAPI 凭证无效或签名失败。"
                let timeHint = response?.code == "OPENAPI_UNAUTHORIZED" ? " 如果刚刚校准过凭证，请同时检查设备时间是否准确。" : ""
                return "星语音库认证失败（\(statusCode)）：\(message)\(timeHint)"
            }
            return response.map { "星语音库请求失败（\(statusCode)）：\($0.message)" }
                ?? "星语音库请求失败（\(statusCode)）。"
        case .decodingFailed:
            return "星语音库响应解析失败。"
        case .networkFailed:
            return "星语音库网络请求失败。"
        }
    }
}

final class MusicVaultApiClient {
    #if os(macOS)
    static private(set) var shared = MusicVaultApiClient()

    static func reloadSharedConfiguration() {
        shared = MusicVaultApiClient()
    }
    #else
    static let shared = MusicVaultApiClient()
    #endif

    private let config: MusicVaultConfig
    private let session: URLSession
    private let decoder = JSONDecoder()

    init(
        config: MusicVaultConfig = .default,
        session: URLSession = {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 10
            configuration.timeoutIntervalForResource = 30
            configuration.waitsForConnectivity = true
            return URLSession(configuration: configuration)
        }()
    ) {
        self.config = config
        self.session = session
    }

    func serverInfo() async throws -> MusicVaultServerInfo {
        try await get("/server/info")
    }

    func syncState() async throws -> MusicVaultSyncState {
        try await get("/sync/state")
    }

    func syncChanges(sinceVersion: Int64 = 0, limit: Int = 500) async throws -> MusicVaultSyncChanges {
        try await get("/sync/changes", queryItems: [
            URLQueryItem(name: "sinceVersion", value: String(sinceVersion)),
            URLQueryItem(name: "limit", value: String(limit))
        ])
    }

    func tracks(query: MusicVaultTrackListQuery = MusicVaultTrackListQuery()) async throws -> MusicVaultTrackPage {
        try await get("/tracks", queryItems: query.queryItems)
    }

    func track(id: Int64) async throws -> MusicVaultTrack {
        try await get("/tracks/\(id)")
    }

    func lyrics(trackId: Int64, ifNoneMatch etag: String? = nil) async throws -> MusicVaultConditionalResponse<MusicVaultLyrics> {
        try await getConditionalJSON("/tracks/\(trackId)/lyrics", ifNoneMatch: etag)
    }

    func lyricsMeta(trackId: Int64) async throws -> MusicVaultLyricsMeta {
        try await get("/tracks/\(trackId)/lyrics/meta")
    }

    func artwork(trackId: Int64, ifNoneMatch etag: String? = nil) async throws -> MusicVaultConditionalResponse<Data> {
        try await getConditionalData("/tracks/\(trackId)/artwork", ifNoneMatch: etag)
    }

    func artworkMeta(trackId: Int64) async throws -> MusicVaultArtworkMeta {
        try await get("/tracks/\(trackId)/artwork/meta")
    }

    func fetchArtwork(trackId: Int64, etag: String? = nil) async throws -> MusicVaultConditionalResponse<Data> {
        try await artwork(trackId: trackId, ifNoneMatch: etag)
    }

    func fetchArtworkMeta(trackId: Int64) async throws -> MusicVaultArtworkMeta {
        try await artworkMeta(trackId: trackId)
    }

    func audioStreamRequest(trackId: Int64) throws -> URLRequest {
        try makeRequest(path: "/tracks/\(trackId)/audio", acceptHeader: "audio/*,*/*")
    }

    func matchTrack(query: MusicVaultTrackMatchQuery) async throws -> MusicVaultTrackMatch {
        try await get("/match/track", queryItems: query.queryItems)
    }

    func absoluteURL(forOpenAPIPath path: String) -> URL? {
        guard path.hasPrefix("/") else { return nil }
        return URL(string: path, relativeTo: config.baseURL)?.absoluteURL
    }

    private func get<Value: Decodable>(_ path: String, queryItems: [URLQueryItem] = []) async throws -> Value {
        let request = try makeRequest(path: path, queryItems: queryItems)
        let (data, response) = try await data(for: request)
        try validate(response: response, data: data, allowNotModified: false)
        do {
            return try decoder.decode(Value.self, from: data)
        } catch {
            throw MusicVaultApiError.decodingFailed
        }
    }

    private func getConditionalJSON<Value: Decodable>(
        _ path: String,
        queryItems: [URLQueryItem] = [],
        ifNoneMatch etag: String?
    ) async throws -> MusicVaultConditionalResponse<Value> {
        var request = try makeRequest(path: path, queryItems: queryItems)
        if let etag = etag?.nilIfBlank {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }
        let (data, response) = try await data(for: request)
        let httpResponse = response as? HTTPURLResponse
        let responseEtag = httpResponse?.value(forHTTPHeaderField: "ETag")
        let contentType = httpResponse?.value(forHTTPHeaderField: "Content-Type")
        if (response as? HTTPURLResponse)?.statusCode == 304 {
            return MusicVaultConditionalResponse(value: nil, etag: responseEtag ?? etag, contentType: contentType, notModified: true)
        }
        try validate(response: response, data: data, allowNotModified: true)
        do {
            return MusicVaultConditionalResponse(value: try decoder.decode(Value.self, from: data), etag: responseEtag, contentType: contentType, notModified: false)
        } catch {
            throw MusicVaultApiError.decodingFailed
        }
    }

    private func getConditionalData(
        _ path: String,
        queryItems: [URLQueryItem] = [],
        ifNoneMatch etag: String?
    ) async throws -> MusicVaultConditionalResponse<Data> {
        var request = try makeRequest(path: path, queryItems: queryItems, acceptHeader: "image/*,*/*")
        if let etag = etag?.nilIfBlank {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }
        let (data, response) = try await data(for: request)
        let httpResponse = response as? HTTPURLResponse
        let responseEtag = httpResponse?.value(forHTTPHeaderField: "ETag")
        let contentType = httpResponse?.value(forHTTPHeaderField: "Content-Type")
        if (response as? HTTPURLResponse)?.statusCode == 304 {
            return MusicVaultConditionalResponse(value: nil, etag: responseEtag ?? etag, contentType: contentType, notModified: true)
        }
        try validate(response: response, data: data, allowNotModified: true)
        return MusicVaultConditionalResponse(value: data, etag: responseEtag, contentType: contentType, notModified: false)
    }

    private func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw MusicVaultApiError.networkFailed(error)
        }
    }

    private func makeRequest(
        path: String,
        queryItems: [URLQueryItem] = [],
        acceptHeader: String = "application/json"
    ) throws -> URLRequest {
        var components = URLComponents(url: config.baseURL.appendingOpenAPIPath(path), resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = components?.url else {
            throw MusicVaultApiError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(acceptHeader, forHTTPHeaderField: "Accept")
        #if os(macOS)
        request.setValue("XingyuMusicBox macOS", forHTTPHeaderField: "User-Agent")
        #else
        request.setValue("XingyuMusicBox iOS", forHTTPHeaderField: "User-Agent")
        #endif
        guard let credential = config.credential else {
            throw MusicVaultApiError.signingFailed(OpenApiSigningError.missingCredential)
        }
        do {
            let signer = OpenApiHmacSigner(credential: credential)
            let headers = try signer.signedHeaders(method: "GET", url: url)
            for (field, value) in headers {
                request.setValue(value, forHTTPHeaderField: field)
            }
        } catch {
            throw MusicVaultApiError.signingFailed(error)
        }
        return request
    }

    private func validate(response: URLResponse, data: Data, allowNotModified: Bool) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MusicVaultApiError.invalidResponse
        }
        if allowNotModified && httpResponse.statusCode == 304 {
            throw MusicVaultApiError.notModified
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw MusicVaultApiError.server(
                statusCode: httpResponse.statusCode,
                response: try? decoder.decode(MusicVaultErrorResponse.self, from: data)
            )
        }
    }
}

private extension URL {
    func appendingOpenAPIPath(_ path: String) -> URL {
        let relativePath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        var url = appendingPathComponent("api")
            .appendingPathComponent("open")
            .appendingPathComponent("v1")
        for component in relativePath.split(separator: "/") {
            url.appendPathComponent(String(component))
        }
        return url
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

}
