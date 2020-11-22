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

	struct StaticTokenAuth: AuthStrategy {
		let headerField: String
		let authToken: String

		init(token: String, inHTTPHeaderField headerField: String) {
			self.authToken = token
			self.headerField = headerField
		}

		func decorateRequest(_ request: URLRequest, completion: @escaping (Result<URLRequest, Swift.Error>) -> Void) {
			var request = request
			request.addValue(authToken, forHTTPHeaderField: headerField)
			completion(.success(request))
		}
	}

	struct BasicAuth: AuthStrategy {
		enum Error: Swift.Error {
			case failedToEncodeUserAndPassword
		}

		let staticAuthTokenStrategy: StaticTokenAuth

		init(username: String, password: String) throws {
			let payload = "\(username):\(password)"

			guard let data = payload.data(using: .utf8) else {
				throw Error.failedToEncodeUserAndPassword
			}

			let basicToken = data.base64EncodedString(options: .lineLength64Characters)
			staticAuthTokenStrategy = StaticTokenAuth(token: "Basic \(basicToken)", inHTTPHeaderField: "Authorization")
		}

		func decorateRequest(_ request: URLRequest, completion: @escaping (Result<URLRequest, Swift.Error>) -> Void) {
			staticAuthTokenStrategy.decorateRequest(request, completion: completion)
		}
	}
}
