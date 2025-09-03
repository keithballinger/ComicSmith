import XCTest
@testable import ComicSmithCore

final class ScriptParserTests: XCTestCase {

    func testPanelDescriptionUpdate() {
        // 1. Arrange
        var issue = Issue(title: "Test Issue")
        var page = Page(title: "Page 1")
        let panel = Panel(description: "Old description.")
        page.panels.append(panel)
        issue.pages.append(page)
        
        let script = """
        Page 1 (Page 1)
        Panel 1: New description.
        """
        
        // 2. Act
        let plan = ScriptParser.parse(script: script, currentIssue: issue)
        
        // 3. Assert
        XCTAssertEqual(plan.mutations.count, 1)
        XCTAssertEqual(plan.mutations.first, .updatePanelDescription(pageID: page.id, panelID: panel.id, newDescription: "New description."))
    }

    func testBalloonCreationOnEmptyPanel() {
        // 1. Arrange
        var issue = Issue(title: "Test Issue")
        var page = Page(title: "Page 1")
        let panel = Panel(description: "A panel.")
        page.panels.append(panel)
        issue.pages.append(page)
        
        let script = """
        Page 1 (Page 1)
        Panel 1: A panel.
        Dialogue (Hero): I'm a hero!
        SFX: KABOOM
        """
        
        // 2. Act
        let plan = ScriptParser.parse(script: script, currentIssue: issue)
        
        // 3. Assert
        let expectedSpeech = Mutation.createBalloon(onPageID: page.id, onPanelID: panel.id, kind: "speech", speaker: "Hero", text: "I'm a hero!")
        let expectedSfx = Mutation.createBalloon(onPageID: page.id, onPanelID: panel.id, kind: "sfx", speaker: nil, text: "KABOOM")
        
        XCTAssertEqual(plan.mutations.count, 2)
        XCTAssertTrue(plan.mutations.contains(expectedSpeech))
        XCTAssertTrue(plan.mutations.contains(expectedSfx))
    }
    
    func testBalloonDeleteAndRecreate() {
        // 1. Arrange
        var issue = Issue(title: "Test Issue")
        var page = Page(title: "Page 1")
        var panel = Panel(description: "A panel with a balloon.")
        let oldBalloon = Balloon(kind: "speech", speaker: "Hero", text: "Old line", order: 1)
        panel.balloons.append(oldBalloon)
        page.panels.append(panel)
        issue.pages.append(page)
        
        let script = """
        Page 1 (Page 1)
        Panel 1: A panel with a balloon.
        Caption: A new caption.
        """
        
        // 2. Act
        let plan = ScriptParser.parse(script: script, currentIssue: issue)
        
        // 3. Assert
        let expectedDelete = Mutation.deleteBalloon(onPageID: page.id, fromPanelID: panel.id, balloonID: oldBalloon.id)
        let expectedCreate = Mutation.createBalloon(onPageID: page.id, onPanelID: panel.id, kind: "caption", speaker: nil, text: "A new caption.")
        
        XCTAssertEqual(plan.mutations.count, 2)
        XCTAssertTrue(plan.mutations.contains(expectedDelete), "The plan should contain a delete mutation for the old balloon.")
        XCTAssertTrue(plan.mutations.contains(expectedCreate), "The plan should contain a create mutation for the new balloon.")
    }
    
    func testPageCreate() {
        // 1. Arrange
        let issue = Issue(title: "Test Issue") // Starts with no pages
        
        let script = """
        Page 1 (New Page)
        Panel 1: A new beginning.
        """
        
        // 2. Act
        let plan = ScriptParser.parse(script: script, currentIssue: issue)
        
        // 3. Assert
        let expectedMutation = Mutation.createPage(atIndex: 0, panelCount: 1, title: "New Page")
        XCTAssertEqual(plan.mutations.count, 1)
        XCTAssertEqual(plan.mutations.first, expectedMutation)
    }
    
    func testPageDelete() {
        // 1. Arrange
        var issue = Issue(title: "Test Issue")
        let pageToDelete = Page(title: "Page To Delete")
        issue.pages.append(pageToDelete)
        
        let script = """
        """ // Empty script
        
        // 2. Act
        let plan = ScriptParser.parse(script: script, currentIssue: issue)
        
        // 3. Assert
        let expectedMutation = Mutation.deletePage(pageID: pageToDelete.id)
        XCTAssertEqual(plan.mutations.count, 1)
        XCTAssertEqual(plan.mutations.first, expectedMutation)
    }
}
