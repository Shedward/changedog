import Foundation

enum GitLab {
	final class Client {
		private let host: URL
		private let restClient: RestClient

		init(host: URL, project: ProjectId, token: String, session: URLSession) {
			self.host = host
			self.restClient = RestClient(
				endpoint: host.appendingPathComponent("/api/v4/projects/\(project.id)"),
				session: session,
				codingStrategy: RestClient.JsonCoding(
					decoder: {
						let decoder = JSONDecoder()
						 decoder.keyDecodingStrategy = .convertFromSnakeCase
						 let formatter = DateFormatter()
						 formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
						 decoder.dateDecodingStrategy = .formatted(formatter)
						 return decoder
					 }()
				),
				authStrategy: RestClient.StaticTokenAuth(token: token, inHTTPHeaderField: "Private-Token")
			)
		}

		func tags() -> Async.Task<[Tag], RestClient.Error> {
			restClient.request(
				[Tag].self,
				method: "GET",
				path: "/repository/tags"
			)
		}

		func diff(
			from fromCommitHash: CommitHash,
			to toCommitHash: CommitHash
		) -> Async.Task<Diff, RestClient.Error> {
			restClient.request(
				Diff.self,
				method: "GET",
				path: "/repository/compare",
				parameters: [
					"from": fromCommitHash.hash,
					"to": toCommitHash.hash
				]
			)
		}

		func diff(
			from fromTag: Tag,
			to toTag: Tag
		) -> Async.Task<Diff, RestClient.Error> {
			restClient.request(
				Diff.self,
				method: "GET",
				path: "/repository/compare",
				parameters: [
					"from": fromTag.name,
					"to": toTag.name
				]
			)
		}
	}
}
