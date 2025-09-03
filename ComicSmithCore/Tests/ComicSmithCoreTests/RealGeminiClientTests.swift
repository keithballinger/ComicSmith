import XCTest
@testable import ComicSmithCore

final class RealGeminiClientTests: XCTestCase {

    var urlSession: URLSession!
    var client: RealGeminiClient!

    override func setUpWithError() throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        urlSession = URLSession(configuration: configuration)
        client = RealGeminiClient(apiKey: "FAKE_KEY", urlSession: urlSession)
    }

    func testGenerateWithTextResponse() async throws {
        // 1. Define the mock response
        let jsonResponse = """
        {
            "candidates": [
                {
                    "content": {
                        "parts": [
                            { "text": "Hello, world!" }
                        ],
                        "role": "model"
                    }
                }
            ]
        }
        """
        let data = jsonResponse.data(using: .utf8)
        MockURLProtocol.responseHandler = {
            request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        // 2. Call the client
        let response = try await client.generate(messages: [], tools: [])

        // 3. Assert the result
        XCTAssertEqual(response.assistantText, "Hello, world!")
        XCTAssertNil(response.toolCalls)
    }

    func testGenerateWithToolCallResponse() async throws {
        // 1. Define the mock response
        let jsonResponse = """
        {
            "candidates": [
                {
                    "content": {
                        "parts": [
                            {
                                "functionCall": {
                                    "name": "add_page",
                                    "args": {
                                        "panel_count": "6"
                                    }
                                }
                            }
                        ],
                        "role": "model"
                    }
                }
            ]
        }
        """
        let data = jsonResponse.data(using: .utf8)
        MockURLProtocol.responseHandler = {
            request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }

        // 2. Call the client
        let response = try await client.generate(messages: [], tools: [])

        // 3. Assert the result
        XCTAssertNil(response.assistantText)
        XCTAssertNotNil(response.toolCalls)
        XCTAssertEqual(response.toolCalls?.count, 1)
        XCTAssertEqual(response.toolCalls?.first?.name, "add_page")
        XCTAssertEqual(response.toolCalls?.first?.argumentsJSON, "{\"panel_count\":\"6\"}")
    }

    func testGenerateWithHTTPError() async throws {
        // 1. Define the mock error response
        MockURLProtocol.responseHandler = {
            request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, nil)
        }

        // 2. Call the client and assert it throws
        do {
            _ = try await client.generate(messages: [], tools: [])
            XCTFail("Client should have thrown an error for HTTP status 500")
        } catch let error as ToolError {
            XCTAssertEqual(error.code, "http_error")
        } catch {
            XCTFail("Client threw an unexpected error type: \(error)")
        }
    }
}