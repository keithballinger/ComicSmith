import Foundation

public final class PersistenceService {
    private let fileManager: FileManager
    private let projectRoot: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // Define project subdirectories and files
    private var pagesURL: URL { projectRoot.appendingPathComponent("pages") }
    private var bibleURL: URL { projectRoot.appendingPathComponent("bible") }
    private var issueManifestURL: URL { projectRoot.appendingPathComponent("issue.json") }

    public init(projectRoot: URL, fileManager: FileManager = .default) {
        self.projectRoot = projectRoot
        self.fileManager = fileManager
        self.encoder.outputFormatting = .prettyPrinted // For human-readable files
    }

    public func save(issue: Issue, references: [ReferenceEntry]) throws {
        try createDirectories()

        // 1. Save pages
        for page in issue.pages {
            let pageURL = pagesURL.appendingPathComponent("\(page.id).json")
            let data = try encoder.encode(page)
            try atomicSave(data: data, to: pageURL)
        }

        // 2. Save references, grouped by kind
        let refsByKind = Dictionary(grouping: references, by: { $0.kind })
        for (kind, refs) in refsByKind {
            let refURL = bibleURL.appendingPathComponent("\(kind).json")
            let data = try encoder.encode(refs)
            try atomicSave(data: data, to: refURL)
        }

        // 3. Save the main issue manifest
        let manifest = IssueManifest(title: issue.title, pageIDs: issue.pages.map { $0.id })
        let manifestData = try encoder.encode(manifest)
        try atomicSave(data: manifestData, to: issueManifestURL)
    }

    public func load() throws -> (issue: Issue, references: [ReferenceEntry]) {
        // 1. Load main issue manifest
        let manifestData = try Data(contentsOf: issueManifestURL)
        let manifest = try decoder.decode(IssueManifest.self, from: manifestData)

        // 2. Load pages in the correct order
        var pages: [Page] = []
        for pageID in manifest.pageIDs {
            let pageURL = pagesURL.appendingPathComponent("\(pageID).json")
            let pageData = try Data(contentsOf: pageURL)
            let page = try decoder.decode(Page.self, from: pageData)
            pages.append(page)
        }

        // 3. Load all references
        var allReferences: [ReferenceEntry] = []
        let bibleContents = try fileManager.contentsOfDirectory(at: bibleURL, includingPropertiesForKeys: nil)
        for refURL in bibleContents where refURL.pathExtension == "json" {
            let refData = try Data(contentsOf: refURL)
            let refs = try decoder.decode([ReferenceEntry].self, from: refData)
            allReferences.append(contentsOf: refs)
        }
        
        let issue = Issue(title: manifest.title, pages: pages)
        
        return (issue, allReferences)
    }

    private func createDirectories() throws {
        try fileManager.createDirectory(at: pagesURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: bibleURL, withIntermediateDirectories: true)
    }
    
    private func atomicSave(data: Data, to url: URL) throws {
        let tempURL = projectRoot.appendingPathComponent(UUID().uuidString)
        try data.write(to: tempURL, options: .atomic)
        _ = try fileManager.replaceItemAt(url, withItemAt: tempURL)
    }
}

// A private struct for the issue manifest file (issue.json)
private struct IssueManifest: Codable {
    var title: String
    var pageIDs: [String]
}
