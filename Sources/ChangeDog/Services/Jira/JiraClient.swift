import Foundation

enum Jira {
	final class Client {
		private let restClient: RestClient

		init(host: URL, credentials: Credentials, session: URLSession) throws {
			restClient = RestClient(
				endpoint: host.appendingPathComponent("/rest/api/2"),
				session: session,
				authStrategy: try RestClient.BasicAuth(
					username: credentials.username,
					password: credentials.token
				)
			)
		}

		func issue(for key: IssueKey, completion: @escaping (Result<Issue, RestClient.Error>) -> Void) {
			restClient.request(
				Issue.self,
				method: "GET",
				path: "/issue/\(key)",
				completion: completion
			)
		}

		func searchIssues(query: String, completion: @escaping (Result<SearchResults, RestClient.Error>) -> Void) {
			restClient.request(
				SearchResults.self,
				method: "GET",
				path: "/search",
				parameters: [
					"jql": query
				],
				completion: completion
			)
		}
	}
}
