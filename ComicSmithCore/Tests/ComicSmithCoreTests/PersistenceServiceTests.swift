import XCTest
@testable import ComicSmithCore

final class PersistenceServiceTests: XCTestCase {

    var tempDirectory: URL!
    var persistenceService: PersistenceService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Create a unique temporary directory for each test
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        persistenceService = PersistenceService(projectRoot: tempDirectory)
    }

    override func tearDownWithError() throws {
        // Clean up the temporary directory after each test
        try FileManager.default.removeItem(at: tempDirectory)
        tempDirectory = nil
        persistenceService = nil
        try super.tearDownWithError()
    }

    func testSaveAndLoadRoundtrip() throws {
        // 1. Create sample data
        let character1 = ReferenceEntry(kind: "character", name: "Hero")
        let location1 = ReferenceEntry(kind: "location", name: "City Center")
        let sampleReferences = [character1, location1]

        var page1 = Page(title: "The Beginning")
        var panel1 = Panel(description: "A hero appears.")
        let balloon1 = Balloon(kind: "speech", speaker: "Hero", text: "I'm here!", order: 1)
        panel1.balloons.append(balloon1)
        page1.panels.append(panel1)
        
        var sampleIssue = Issue(title: "My First Issue")
        sampleIssue.pages.append(page1)

        // 2. Save the data
        try persistenceService.save(issue: sampleIssue, references: sampleReferences)

        // 3. Load the data back
        let loaded = try persistenceService.load()
        let loadedIssue = loaded.issue
        let loadedReferences = loaded.references

        // 4. Assert that the loaded data is equal to the original data
        XCTAssertEqual(loadedIssue, sampleIssue, "The loaded issue should be identical to the saved issue.")
        XCTAssertEqual(Set(loadedReferences), Set(sampleReferences), "The loaded references should be identical to the saved references.")
    }
}
