import Foundation

enum GitLab {
	final class Client {
		private let session: URLSession
		private let apiURL: URL
		private let token: String
		private let decoder: JSONDecoder
		private let project: Project

		init(host: URL, project: Project, token: String, session: URLSession) {
			self.session = session
			self.apiURL = host.appendingPathComponent("/api/v4")
			self.token = token
			self.project = project
			decoder = JSONDecoder()
			decoder.keyDecodingStrategy = .convertFromSnakeCase
			let formatter = DateFormatter()
			formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
			decoder.dateDecodingStrategy = .formatted(formatter)
		}

		func tags(completion: @escaping (Result<[Tag], GitLab.Error>) -> Void) {
			request(
				[Tag].self,
				method: "GET",
				path: "/repository/tags",
				completion: completion
			)
		}

		func diff(
			from fromCommitHash: CommitHash,
			to toCommitHash: CommitHash,
			completion: @escaping (Result<Diff, GitLab.Error>) -> Void
		) {
			request(
				Diff.self,
				method: "GET",
				path: "/repository/compare",
				parameters: [
					"from": fromCommitHash.hash,
					"to": toCommitHash.hash
				],
				completion: completion
			)
		}

		private func request<T: Decodable>(
			_ type: T.Type,
			method: String,
			path: String,
			parameters: [String: String]? = nil,
			completion: @escaping (Result<T, GitLab.Error>) -> Void
		)  {
			var url = apiURL
				.appendingPathComponent("/projects/\(project.id)")
				.appendingPathComponent(path)

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
			request.setValue(token, forHTTPHeaderField: "Private-Token")

			let task = session.dataTask(with: request) { data, response, error in
				guard let data = data else { return completion(.failure(.noData(error))) }

				do {
					let response = try self.decoder.decode(T.self, from: data)
					completion(.success(response))
				} catch {
					completion(.failure(.serialisationError(error)))
				}
			}
			task.resume()
		}
	}
}
