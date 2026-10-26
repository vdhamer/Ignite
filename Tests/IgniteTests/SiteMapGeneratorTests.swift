//
// SiteMapGeneratorTests.swift
// Ignite
// https://www.github.com/twostraws/Ignite
// See LICENSE for license information.
//

import XCTest
@testable import Ignite

/// Tests for the sitemap XML, which has to parse as XML for a crawler to read any of it.
///
/// FORK TEST, added alongside the escaping fix in ``SiteMapGenerator``. A path holding a literal `&`
/// used to make the whole file malformed, and because a crawler rejects a sitemap as a unit, one
/// expertise page named "Black & white" silently cost the site every other entry too.
///
/// Written with XCTest because this fork is on XCTest. Upstream has since moved to Swift Testing, in
/// `Tests/IgniteTesting/Publishing/SiteMapGenerator.swift`, so the version shaped for their tree is
/// deliberately not duplicated here: it lives in twostraws/Ignite#891, verified against their `main`
/// at ebc296e. When this fork is updated to a current Ignite, take the test from there rather than
/// porting this file, and check first whether the fix arrived on its own.
final class SiteMapGeneratorTests: ElementTest {

    /// Parsing is the assertion that matters: checking for a substring would pass on a file no
    /// crawler could read.
    func testSiteMapWithAmpersandInPathIsWellFormedXML() throws {
        publishingContext.addToSiteMap("/expertises/Black %26 white", priority: 1)
        publishingContext.addToSiteMap("/expertises/Black & white", priority: 1)

        let xml = SiteMapGenerator(context: publishingContext).generateSiteMap()

        XCTAssertNoThrow(try XMLDocument(xmlString: xml),
                         "The sitemap must parse as XML, otherwise a crawler discards all of it")
        XCTAssertTrue(xml.contains("Black &amp; white"),
                      "A literal ampersand in a path has to reach the XML escaped")
        XCTAssertFalse(xml.contains("Black & white"),
                       "No unescaped ampersand may survive into the XML")
    }

    /// The escaping must not touch a path that was already percent-encoded, which is what the
    /// generator sees for a space.
    func testPercentEncodedPathIsUnchanged() throws {
        publishingContext.addToSiteMap("/expertises/Black%20and%20white", priority: 1)

        let xml = SiteMapGenerator(context: publishingContext).generateSiteMap()

        XCTAssertTrue(xml.contains("/expertises/Black%20and%20white"),
                      "Percent-encoded characters must pass through untouched")
    }

    /// A page is written to `<path>/index.html`, so the server redirects the slashless URL to the slashed one.
    /// A sitemap entry must name the final URL, or Search Console reports "Page with redirect".
    func testPageEntriesEndInSlash() throws {
        publishingContext.addToSiteMap("/en/clubs/fgWaalre", priority: 0.9)
        publishingContext.addToSiteMap("/en/clubs/", priority: 0.9)

        let xml = SiteMapGenerator(context: publishingContext).generateSiteMap()

        XCTAssertTrue(xml.contains("/en/clubs/fgWaalre/</loc>"), "A slashless path must gain its slash")
        XCTAssertFalse(xml.contains("/en/clubs//</loc>"), "A path that already ends in a slash must not gain a second one")
    }
}
