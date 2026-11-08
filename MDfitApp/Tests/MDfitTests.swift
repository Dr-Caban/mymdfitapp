import XCTest
@testable import MDfit

final class MDfitTests: XCTestCase {

    func testPainPatternLookup() {
        let lowerBackPatterns = PainPattern.patterns(for: .lowerBack)
        XCTAssertFalse(lowerBackPatterns.isEmpty, "Should find patterns for lower back")
    }

    func testProtocolLookup() {
        let backProtocols = Program.protocolsForRegion(.lowerBack)
        XCTAssertFalse(backProtocols.isEmpty, "Should find protocols for lower back")
    }

    func testExerciseSamples() {
        XCTAssertFalse(Exercise.samples.isEmpty, "Should have sample exercises")
    }
}
