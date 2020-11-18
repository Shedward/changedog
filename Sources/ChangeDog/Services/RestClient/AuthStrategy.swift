import Foundation

protocol AuthStrategy {
	func decorateRequest(_ request: URLRequest, completion: @escaping (Result<URLRequest, Error>) -> Void)
}

extension RestClient {
	struct NoAuth: AuthStrategy {
		func decorateRequest(_ request: URLRequest, completion: @escaping (Result<URLRequest, Swift.Error>) -> Void) {
			completion(.success(request))
		}
	}

	struct StaticAuthToken: AuthStrategy {
		let headerField: String
		let authToken: String

		init(_ authToken: String, inHTTPHeaderField headerField: String) {
			self.authToken = authToken
			self.headerField = headerField
		}

		func decorateRequest(_ request: URLRequest, completion: @escaping (Result<URLRequest, Swift.Error>) -> Void) {
			var request = request
			request.addValue(authToken, forHTTPHeaderField: headerField)
			completion(.success(request))
		}
	}
}
