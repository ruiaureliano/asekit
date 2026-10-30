import XCTest
@testable import ASEKit

final class ASETests: XCTestCase {
    func testRoundTripRGBPalette() throws {
        let palette = ASEPalette(name: "Brand", colors: [ASEColor(name: "Blue", red: 0.1, green: 0.2, blue: 0.9)])
        let decoded = try ASEReader.read(data: ASEWriter.data(for: palette))
        XCTAssertEqual(decoded.name, palette.name)
        XCTAssertEqual(decoded.colors.count, 1)
        XCTAssertEqual(decoded.colors[0].name, "Blue")
        XCTAssertEqual(decoded.colors[0].red, 0.1, accuracy: 0.0001)
        XCTAssertEqual(decoded.colors[0].green, 0.2, accuracy: 0.0001)
        XCTAssertEqual(decoded.colors[0].blue, 0.9, accuracy: 0.0001)
    }

    func testRejectsInvalidHeader() {
        XCTAssertThrowsError(try ASEReader.read(data: Data("nope".utf8))) { error in
            XCTAssertEqual(error as? ASEError, .invalidHeader)
        }
    }
}
