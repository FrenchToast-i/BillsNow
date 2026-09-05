//
//  RSSParser.swift
//  Shared
//
//  Minimal dependency-free feed reader that handles the two syndication
//  flavors used by the bundled sources: RSS 2.0 (WGRZ) and Atom
//  (Buffalo Rumblings). Built on Foundation's XMLParser.
//

import Foundation

public struct RSSItem: Identifiable, Equatable {
    public var id: String { link }
    public let title: String
    public let link: String
    public let published: Date?
    public let summary: String
}

public enum RSSParser {
    public static func parse(data: Data) -> [RSSItem] {
        let delegate = RSSDelegate()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.shouldProcessNamespaces = false
        parser.shouldReportNamespacePrefixes = false
        parser.parse()
        return delegate.items
    }
}

// MARK: - Delegate

private final class RSSDelegate: NSObject, XMLParserDelegate {
    var items: [RSSItem] = []

    private var isAtom = false
    private var inItem = false
    private var currentTitle = ""
    private var currentLink = ""
    private var currentDateRaw = ""
    private var currentSummary = ""
    private var currentElement = ""
    private var elementText = ""
    private var pendingHref = ""

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName.lowercased()
        elementText = ""

        if currentElement == "feed" { isAtom = true }
        if (isAtom && currentElement == "entry") || (!isAtom && currentElement == "item") {
            inItem = true
            currentTitle = ""; currentLink = ""; currentDateRaw = ""; currentSummary = ""
        }
        if inItem, currentElement == "link" {
            // Atom carries the URL as an attribute.
            if let href = attributeDict["href"], !href.isEmpty {
                pendingHref = href
            } else if let rel = attributeDict["rel"], rel != "alternate" {
                pendingHref = ""
            }
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if inItem { elementText += string }
    }

    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        if inItem, let s = String(data: CDATABlock, encoding: .utf8) {
            elementText += s
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        guard inItem else {
            if !isAtom, elementName.lowercased() == "channel" { /* nothing */ }
            return
        }
        let name = elementName.lowercased()
        let value = elementText.trimmingCharacters(in: .whitespacesAndNewlines)

        switch name {
        case "title":
            currentTitle = value
        case "link":
            if !value.isEmpty { currentLink = value } else if !pendingHref.isEmpty { currentLink = pendingHref }
        case "pubdate", "published", "updated", "date", "dc:date", "created":
            if currentDateRaw.isEmpty { currentDateRaw = value }
        case "description", "summary", "content", "content:encoded":
            if currentSummary.isEmpty {
                currentSummary = (name == "description" || name == "summary" || name == "content:encoded" || name == "content")
                    ? Self.plainText(fromHTML: value) : value
            }
        case "guid":
            if currentLink.isEmpty { currentLink = value }
        case "item", "entry":
            finishItem()
        default:
            break
        }
        elementText = ""
    }

    private func finishItem() {
        defer { inItem = false }
        let title = currentTitle.isEmpty ? "(Untitled)" : currentTitle
        guard !currentLink.isEmpty else { return }
        items.append(RSSItem(title: title,
                             link: currentLink,
                             published: Self.parseDate(currentDateRaw),
                             summary: currentSummary))
    }

    // MARK: Cleaning

    /// Removes tags/CDATA/entities so HTML summaries render as plain text.
    static func plainText(fromHTML html: String) -> String {
        var text = html
        text = text.replacingOccurrences(of: "<![CDATA[", with: " ")
        text = text.replacingOccurrences(of: "]]>", with: " ")
        // Remove tag content but keep nothing between paired tags.
        var cleaned = ""
        var inTag = false
        for ch in text {
            if ch == "<" { inTag = true; cleaned += " " ; continue }
            if ch == ">" { inTag = false; continue }
            if !inTag { cleaned.append(ch) }
        }
        cleaned = cleaned
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
        let collapsed = cleaned.split(whereSeparator: { $0 == " " || $0 == "\n" || $0 == "\t" }).joined(separator: " ")
        return String(collapsed.prefix(280))
    }

    // MARK: Dates

    static func parseDate(_ raw: String) -> Date? {
        let value = raw.trimmingCharacters(in: .whitespaces)
        guard !value.isEmpty else { return nil }

        let iso = ISO8601DateFormatter()
        if let d = iso.date(from: value) { return d }

        // RFC 822 / RFC 1123 variants.
        let rfc = DateFormatter()
        rfc.locale = Locale(identifier: "en_US_POSIX")
        rfc.timeZone = TimeZone(identifier: "GMT")
        let formats = [
            "EEE, dd MMM yyyy HH:mm:ss Z",
            "EEE, dd MMM yyyy HH:mm:ss zzz",
            "EEE, dd MMM yyyy HH:mm Z",
            "dd MMM yyyy HH:mm:ss Z",
            "yyyy-MM-dd'T'HH:mm:ssXXXXX",
            "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX",
        ]
        for format in formats {
            rfc.dateFormat = format
            if let d = rfc.date(from: value) { return d }
        }
        return nil
    }
}
