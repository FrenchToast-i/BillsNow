//
//  NewsViewModel.swift
//  BillsNow
//

import Combine
import Foundation

public struct NewsSource: Identifiable, Equatable {
    public var id: String { url }
    public let name: String
    public let url: String
}

public enum BillsNewsSources {
    /// Verified-working Bills feeds. WGRZ is the local NBC affiliate in
    /// Buffalo; Buffalo Rumblings is the SB Nation Bills site.
    public static let all: [NewsSource] = [
        NewsSource(name: "WGRZ — Buffalo", url: "https://www.wgrz.com/feeds/syndication/rss/sports"),
        NewsSource(name: "Buffalo Rumblings", url: "https://www.buffalorumblings.com/rss/current.xml"),
    ]
}

public struct NewsFeedResult: Identifiable, Equatable {
    public var id: String { source.url }
    public let source: NewsSource
    public let items: [RSSItem]
    public let error: String?
}

@MainActor
final class NewsViewModel: ObservableObject {
    @Published var results: [NewsFeedResult] = []
    @Published var isLoading = false

    private var loadedOnce = false

    func loadIfNeeded() async {
        guard !loadedOnce else { return }
        loadedOnce = true
        await refresh()
    }

    func refresh() async {
        isLoading = results.isEmpty
        defer { isLoading = false }

        var newResults = [NewsFeedResult]()
        await withTaskGroup(of: NewsFeedResult.self) { group in
            for source in BillsNewsSources.all {
                group.addTask {
                    await Self.fetch(source: source)
                }
            }
            for await result in group {
                newResults.append(result)
            }
        }
        // Keep deterministic order (source list order).
        newResults.sort { a, b in
            (BillsNewsSources.all.firstIndex(of: a.source) ?? 0) <
                (BillsNewsSources.all.firstIndex(of: b.source) ?? 0)
        }
        results = newResults
    }

    private static func fetch(source: NewsSource) async -> NewsFeedResult {
        guard let url = URL(string: source.url) else {
            return NewsFeedResult(source: source, items: [], error: "Bad feed URL.")
        }
        var request = URLRequest(url: url)
        request.setValue("BillsNow/1.0 (iPad)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 20
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return NewsFeedResult(source: source, items: [], error: "Feed unavailable (HTTP error).")
            }
            let items = RSSParser.parse(data: data)
            return NewsFeedResult(source: source, items: items, error: nil)
        } catch {
            return NewsFeedResult(source: source, items: [], error: error.localizedDescription)
        }
    }
}
