import Foundation
import XCTest

// A mock URLProtocol for intercepting URLSession requests and returning canned responses.
class MockURLProtocol: URLProtocol {
    // A static handler that tests can set to define the response for a given request.
    static var responseHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?

    override class func canInit(with request: URLRequest) -> Bool {
        // We can handle all requests.
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        // Required override, but we don't need to modify the request.
        return request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.responseHandler else {
            XCTFail("Response handler not set for MockURLProtocol")
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if let data = data {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {
        // Required override, but nothing to do here.
    }
}
