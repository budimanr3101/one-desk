// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 ONE DESK contributors
import Foundation

enum LiveTranslateDirection: String, CaseIterable, Identifiable {
    case englishIndonesian, indonesianEnglish
    var id: String { rawValue }
    var label: String { self == .englishIndonesian ? "English → Indonesian" : "Indonesian → English" }
    var locale: String { self == .englishIndonesian ? "en-US" : "id-ID" }
    var pair: String { self == .englishIndonesian ? "en|id" : "id|en" }
}
enum LiveTranslateInput: String, CaseIterable, Identifiable {
    case microphone, systemAudio
    var id: String { rawValue }
    var label: String { self == .microphone ? "Microphone" : "System audio" }
}
enum LiveTranslateSupport {
    /// MyMemory accepts at most 500 UTF-8 bytes. Keep the latest spoken words,
    /// not a permanently frozen prefix of a long-running recognition session.
    static func excerpt(_ text: String, byteLimit: Int = 450) -> String {
        var result = ""; var bytes = 0
        for character in text.trimmingCharacters(in: .whitespacesAndNewlines).reversed() {
            let size = String(character).utf8.count
            guard bytes + size <= max(0, byteLimit) else { break }
            result.insert(character, at: result.startIndex); bytes += size
        }
        return result
    }
    static func request(text: String, direction: LiveTranslateDirection) -> URLRequest? {
        let text = excerpt(text)
        guard !text.isEmpty else { return nil }
        var components = URLComponents(string: "https://api.mymemory.translated.net/get")!
        components.queryItems = [URLQueryItem(name: "q", value: text), URLQueryItem(name: "langpair", value: direction.pair)]
        guard let url = components.url else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 20; request.cachePolicy = .reloadIgnoringLocalCacheData
        return request
    }
    static func decode(_ data: Data) throws -> String {
        struct Response: Decodable {
            struct Payload: Decodable { let translatedText: String }
            let responseData: Payload
            let responseStatus: Int
            let responseDetails: String?
        }
        let response = try JSONDecoder().decode(Response.self, from: data)
        guard response.responseStatus == 200, !response.responseData.translatedText.isEmpty else {
            throw NSError(domain: "LiveTranslate", code: response.responseStatus,
                          userInfo: [NSLocalizedDescriptionKey: response.responseDetails ?? "Translation unavailable or daily quota exceeded."])
        }
        return response.responseData.translatedText
    }
}
