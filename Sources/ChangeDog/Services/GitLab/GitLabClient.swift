import Foundation

public enum GitLab {
	public final class Client {
		private let restClient: RestClient

		public init(host: URL, project: Project, token: String, session: URLSession) {
			self.restClient = RestClient(
				endpoint: host.appendingPathComponent("/api/v4/project/\(project.id)"),
				session: session,
				decoder: {
					let decoder = JSONDecoder()
					decoder.keyDecodingStrategy = .convertFromSnakeCase
					let formatter = DateFormatter()
					formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
					decoder.dateDecodingStrategy = .formatted(formatter)
					return decoder
				}(),
				authStrategy: RestClient.StaticTokenAuth(token: token, inHTTPHeaderField: "Private-Token")
			)
		}

		public func tags(completion: @escaping (Result<[Tag], RestClient.Error>) -> Void) {
			restClient.request(
				[Tag].self,
				method: "GET",
				path: "/repository/tags",
				completion: completion
			)
		}

		public func diff(
			from fromCommitHash: CommitHash,
			to toCommitHash: CommitHash,
			completion: @escaping (Result<Diff, RestClient.Error>) -> Void
		) {
			restClient.request(
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
	}
}
