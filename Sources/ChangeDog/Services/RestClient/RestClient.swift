import Foundation

final class RestClient {
	enum Error: Swift.Error {
		case noData(Swift.Error?)
		case networkError(Swift.Error)
		case encodingError(Swift.Error)
		case decodingError(Swift.Error)
		case authError(Swift.Error)
		case wrongResponse
		case failedToComposeUrl

		struct HTTPError {
			let code: Int
			let responseData: String?
		}
		case httpError(HTTPError)
	}

	private struct EmptyBody: Encodable, Decodable { }

	private let authStrategy: AuthStrategy
	private let endpoint: URL
	private let encoder: JSONEncoder
	private let decoder: JSONDecoder
	private let session: URLSession

	init(
		endpoint: URL,
		session: URLSession,
		encoder: JSONEncoder = .init(),
		decoder: JSONDecoder = .init(),
		authStrategy: AuthStrategy
	) {
		self.authStrategy = authStrategy
		self.endpoint = endpoint
		self.encoder = encoder
		self.decoder = decoder
		self.session = session
	}

	func request(
		method: String,
		path: String,
		parameters: [String: String]? = nil,
		completion: @escaping (Result<Void, RestClient.Error>) -> Void
	)  {
		makeRequest(
			EmptyBody.self,
			method: method,
			path: path,
			parameters: parameters,
			body: Optional<EmptyBody>.none
		) { result in
			completion(result.map { _ in Void() })
		}
	}

	func request<Request: Encodable>(
		method: String,
		path: String,
		parameters: [String: String]? = nil,
		body: Request,
		completion: @escaping (Result<Void, RestClient.Error>) -> Void
	)  {
		makeRequest(
			EmptyBody.self,
			method: method,
			path: path,
			parameters: parameters,
			body: body
		) { result in
			completion(result.map { _ in Void() })
		}
	}

	func request<Response: Decodable>(
		_ type: Response.Type,
		method: String,
		path: String,
		parameters: [String: String]? = nil,
		completion: @escaping (Result<Response, RestClient.Error>) -> Void
	)  {
		makeRequest(
			type,
			method: method,
			path: path,
			parameters: parameters,
			body: Optional<EmptyBody>.none,
			completion: completion
		)
	}

	func request<Request: Encodable, Response: Decodable>(
		_ type: Response.Type,
		method: String,
		path: String,
		parameters: [String: String]? = nil,
		body: Request,
		completion: @escaping (Result<Response, RestClient.Error>) -> Void
	)  {
		makeRequest(
			type,
			method: method,
			path: path,
			parameters: parameters,
			body: body,
			completion: completion
		)
	}

	private func makeRequest<Request: Encodable, Response: Decodable>(
		_ type: Response.Type,
		method: String,
		path: String,
		parameters: [String: String]? = nil,
		body: Request?,
		completion: @escaping (Result<Response, RestClient.Error>) -> Void
	)  {
		var url = endpoint.appendingPathComponent(path)

		if let parameters = parameters {
			var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
			components?.queryItems = parameters.map { key, value in URLQueryItem(name: key, value: value) }
			guard let urlWithParameters = components?.url else {
				return completion(.failure(.failedToComposeUrl))
			}

			url = urlWithParameters
		}

		var request = URLRequest(url: url)
		request.httpMethod = method

		do {
			request.httpBody = try body.flatMap { try self.encoder.encode($0) }
		} catch {
			return completion(.failure(.encodingError(error)))
		}

		authStrategy.decorateRequest(request) { requestResult in
			switch requestResult {
			case .success(let request):
				let task = self.session.dataTask(with: request) { data, response, error in
					switch self.requestResult(for: response, data: data) {
					case .success:
						guard let data = data else { return completion(.failure(.noData(error))) }

						do {
							let response = try self.decoder.decode(Response.self, from: data)
							return completion(.success(response))
						} catch {
							return completion(.failure(.decodingError(error)))
						}
					case .failure(let error):
						return completion(.failure(error))
					}
				}
				task.resume()
			case .failure(let error):
				return completion(.failure(.authError(error)))
			}
		}
	}

	private func requestResult(for response: URLResponse?, data: Data?) -> Result<Void, Error> {
		guard let response = response as? HTTPURLResponse else {
			return .failure(.wrongResponse)
		}

		switch response.statusCode {
		case 100...299:
			return .success(())
		default:
			let responseData = data.flatMap { String(data: $0, encoding: .utf8) }
			return .failure(.httpError(.init(code: response.statusCode, responseData: responseData)))
		}
	}
}
