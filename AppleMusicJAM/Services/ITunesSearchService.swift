import Foundation

/// Service for searching the iTunes catalog via the public Apple Search API.
final class ITunesSearchService {

    // MARK: - Singleton

    /// Shared singleton instance.
    static let shared = ITunesSearchService()

    private init() {}

    // MARK: - Errors

    /// Errors that can occur during an iTunes search request.
    enum SearchError: LocalizedError {
        case invalidURL
        case networkError(Error)
        case decodingError(Error)
        case emptyQuery

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid search URL."
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .decodingError(let error):
                return "Failed to decode response: \(error.localizedDescription)"
            case .emptyQuery:
                return "Search query cannot be empty."
            }
        }
    }

    // MARK: - Public Methods

    /// Searches the iTunes catalog for songs matching the given term.
    ///
    /// - Parameters:
    ///   - term: The search query string.
    ///   - limit: Maximum number of results to return. Defaults to 25.
    ///   - country: The ISO 3166-1 alpha-2 country code for the storefront. Defaults to `"IT"`.
    /// - Returns: An array of `Song` objects matching the query.
    /// - Throws: `SearchError` if the request fails.
    func search(term: String, limit: Int = 25, country: String = "IT") async throws -> [Song] {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw SearchError.emptyQuery
        }

        guard let encodedTerm = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw SearchError.invalidURL
        }

        let urlString = "https://itunes.apple.com/search?term=\(encodedTerm)&entity=song&limit=\(limit)&country=\(country)"
        guard let url = URL(string: urlString) else {
            throw SearchError.invalidURL
        }

        let data: Data
        do {
            let (responseData, _) = try await URLSession.shared.data(from: url)
            data = responseData
        } catch {
            throw SearchError.networkError(error)
        }

        do {
            let response = try JSONDecoder().decode(ITunesSearchResponse.self, from: data)
            return response.results
        } catch {
            throw SearchError.decodingError(error)
        }
    }
}
