import Foundation

enum Jira {
	final class Client {
		private let host: URL
		private let restClient: RestClient

		init(host: URL, credentials: Credentials, session: URLSession) throws {
			self.host = host
			restClient = RestClient(
				endpoint: host.appendingPathComponent("/rest/api/2"),
				session: session,
				codingStrategy: RestClient.JsonCoding(),
				authStrategy: try RestClient.BasicAuth(
					username: credentials.username,
					password: credentials.token
				)
			)
		}

		func url(for issueKey: IssueKey) -> URL {
			host.appendingPathComponent("browse").appendingPathComponent(issueKey.value)
		}

		func issue(for key: IssueKey) -> Async.Task<Issue, RestClient.Error> {
			restClient.request(
				Issue.self,
				method: "GET",
				path: "/issue/\(key)"
			)
		}

		func searchIssues(query: Jira.Query) -> Async.Task<SearchResults, RestClient.Error> {
			do {
				return restClient.request(
					SearchResults.self,
					method: "GET",
					path: "/search",
					parameters: [
						"jql": try query.compile()
					]
				)
			} catch {
				return Async.justError(valueType: SearchResults.self, error: RestClient.Error.wrongRequest(error))
			}
		}
	}
}
