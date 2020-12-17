import Foundation

final class RestClient {
	enum Error: Swift.Error {
		case noData(Swift.Error?)
		case networkError(Swift.Error)
		case encodingError(Swift.Error)
		case decodingError(Swift.Error)
		case authError(Swift.Error)
		case wrongRequest(Swift.Error)
		case wrongResponse
		case failedToComposeUrl

		struct HTTPError {
			let code: Int
			let responseData: String?
		}
		case httpError(HTTPError)
	}

	private struct Request<Body: Encodable> {
		let method: String
		let path: String?
		let parameters: [String: String]?
		let body: Body?

		init(method: String, path: String? = nil, parameters: [String: String]? = nil, body: Body? = nil) {
			self.method = method
			self.path = path
			self.parameters = parameters
			self.body = body
		}
	}

	private struct EmptyBody: Encodable, Decodable {}

	private let authStrategy: AuthStrategy
	private let codingStrategy: CodingStrategy
	private let endpoint: URL
	private let session: URLSession

	init(
		endpoint: URL,
		session: URLSession,
		codingStrategy: CodingStrategy,
		authStrategy: AuthStrategy
	) {
		self.authStrategy = authStrategy
		self.codingStrategy = codingStrategy
		self.endpoint = endpoint
		self.session = session
	}

	func request(
		method: String,
		path: String? = nil,
		parameters: [String: String]? = nil
	) -> Async.Task<Void, RestClient.Error>  {
		makeTask(
			EmptyBody.self,
			Request(
				method: method,
				path: path,
				parameters: parameters,
				body: Optional<EmptyBody>.none
			)
		)
		.mapSuccess { _ in Void() }
	}

	func request<RequestBody: Encodable>(
		method: String,
		path: String? = nil,
		parameters: [String: String]? = nil,
		body: RequestBody
	) -> Async.Task<Void, RestClient.Error>  {
		makeTask(
			EmptyBody.self,
			Request(
				method: method,
				path: path,
				parameters: parameters,
				body: body
			)
		)
		.mapSuccess { _ in Void() }
	}

	func request<ResponseBody: Decodable>(
		_ type: ResponseBody.Type,
		method: String,
		path: String? = nil,
		parameters: [String: String]? = nil
	) -> Async.Task<ResponseBody, RestClient.Error>  {
		makeTask(
			ResponseBody.self,
			Request(
				method: method,
				path: path,
				parameters: parameters,
				body: Optional<EmptyBody>.none
			)
		)
	}

	func request<RequestBody: Encodable, ResponseBody: Decodable>(
		_ type: ResponseBody.Type,
		method: String,
		path: String? = nil,
		parameters: [String: String]? = nil,
		body: RequestBody
	) -> Async.Task<ResponseBody, RestClient.Error>  {
		makeTask(
			ResponseBody.self,
			Request(
				method: method,
				path: path,
				parameters: parameters,
				body: body
			)
		)
	}

	private func makeTask<RequestBody: Encodable, ResponseBody: Decodable>(
		_ type: ResponseBody.Type,
		_ request: Request<RequestBody>
	) -> Async.Task<ResponseBody, RestClient.Error> {
		.init { completion in
			self.makeRequest(type, request, completion: completion)
		}
	}

	private func makeRequest<RequestBody: Encodable, ResponseBody: Decodable>(
		_ type: ResponseBody.Type,
		_ request: Request<RequestBody>,
		completion: @escaping (Result<ResponseBody, RestClient.Error>) -> Void
	)  {
		var url = endpoint

		if let path = request.path {
			url = url.appendingPathComponent(path)
		}

		if let parameters = request.parameters {
			var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
			components?.queryItems = parameters.map { key, value in URLQueryItem(name: key, value: value) }
			guard let urlWithParameters = components?.url else {
				return completion(.failure(.failedToComposeUrl))
			}

			url = urlWithParameters
		}

		var urlRequest = URLRequest(url: url)
		urlRequest.httpMethod = request.method
		urlRequest.addValue(codingStrategy.encodingContentType, forHTTPHeaderField: "Content-Type")
		urlRequest.addValue(codingStrategy.decodingContentType, forHTTPHeaderField: "Accept")

		do {
			urlRequest.httpBody = try request.body.flatMap { try self.codingStrategy.encode($0) }
		} catch {
			return completion(.failure(.encodingError(error)))
		}

		authStrategy.decorateRequest(urlRequest) { requestResult in
			switch requestResult {
			case .success(let request):
				let task = self.session.dataTask(with: request) { data, response, error in
					switch self.requestResult(for: response, data: data) {
					case .success:
						guard let data = data else { return completion(.failure(.noData(error))) }

						do {
							let response = try self.codingStrategy.decode(ResponseBody.self, from: data)
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
			var responseString = data.flatMap { String(data: $0, encoding: .utf8) }
			let errorBodySizeLimit = 250
			if let fullResponseString = responseString, fullResponseString.count > errorBodySizeLimit {
				responseString = fullResponseString.prefix(errorBodySizeLimit) + "..."
			}
			return .failure(.httpError(.init(code: response.statusCode, responseData: responseString)))
		}
	}
}
