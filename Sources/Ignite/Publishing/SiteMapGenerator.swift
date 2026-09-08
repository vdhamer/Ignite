//
// SiteMapGenerator.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import Foundation

struct SiteMapGenerator {
    var context: PublishingContext

    /// Escapes the characters that cannot appear literally in XML character data.
    ///
    /// FORK CHANGE, kept as a reminder of an upstream bug: `generateSiteMap()` interpolated the path
    /// straight into `<loc>`, so a single path containing `&` made the whole sitemap malformed and a
    /// crawler discards the entire file rather than the one entry. `&` is legal in a URL path segment
    /// (RFC 3986 sub-delims), so the URL was correct and only the XML was wrong; escaping here rather
    /// than percent-encoding the path keeps the generated links untouched. Still present upstream as
    /// of Sept 2026.
    ///
    /// `&` is replaced first, otherwise the ampersands introduced by the later replacements would
    /// themselves be escaped.
    private func xmlEscaped(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    func generateSiteMap() -> String {
        let locations = context.siteMap.map {
            let location = xmlEscaped(context.site.url.absoluteString + $0.path)
            return "<url><loc>\(location)</loc><priority>\($0.priority)</priority></url>"
        }.joined()

        return """
        <?xml version="1.0" encoding="UTF-8"?>\
        <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\
        \(locations)\
        </urlset>
        """
    }
}
