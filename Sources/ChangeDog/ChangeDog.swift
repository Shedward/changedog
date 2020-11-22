import Foundation
import ArgumentParser

struct ChangeDog: ParsableCommand {
	func run() throws {
		let dispatchGroup = DispatchGroup()

		let jiraClient = try Jira.Client(
			host: URL(string: "https://jira.m2.ru")!,
			credentials: .init(username: "maltsevvn", token: "_"),
			session: .shared
		)

		dispatchGroup.enter()
		let query = Jira.Query.issuesWithIds([try .init(value: "MOB-2759")])
		jiraClient.searchIssues(query: try query.compile()) { result in
			print(result)
			dispatchGroup.leave()
		}

		dispatchGroup.notify(queue: .main) {
			Self.exit()
		}

		dispatchMain()
	}
}
