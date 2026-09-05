//
//  NewsView.swift
//  BillsNow
//

import SwiftUI

struct NewsView: View {
    @StateObject private var vm = NewsViewModel()

    var body: some View {
        List {
            ForEach(vm.results) { result in
                Section {
                    if let error = result.error {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text("Couldn't load this feed: \(error)")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 6)
                    } else if result.items.isEmpty {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Loading…")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 6)
                    } else {
                        ForEach(result.items) { item in
                            NewsRow(item: item, sourceName: result.source.name)
                        }
                    }
                } header: {
                    Label(result.source.name, systemImage: "dot.radiowaves.left.and.right")
                        .font(.caption.weight(.bold))
                        .textCase(.none)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Bills News")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if vm.isLoading {
                    ProgressView()
                } else {
                    Button { Task { await vm.refresh() } } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Refresh news")
                }
            }
        }
        .task { await vm.loadIfNeeded() }
        .refreshable { await vm.refresh() }
    }
}

private struct NewsRow: View {
    let item: RSSItem
    let sourceName: String

    var body: some View {
        Link(destination: URL(string: item.link)!) {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                if !item.summary.isEmpty {
                    Text(item.summary)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }

                HStack(spacing: 6) {
                    if let published = item.published {
                        Text(Self.relativeFormatter.localizedString(for: published, relativeTo: Date()))
                    }
                    Text("·")
                    Text(sourceName)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .accessibilityHint("Opens the article in Safari")
    }

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f
    }()
}
