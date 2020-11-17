import Foundation
import ArgumentParser

struct ChangeDog: ParsableCommand {
	func run() throws {
		let dispatchGroup = DispatchGroup()

		let gitlabClient = GitLab.Client(
			host: URL(string: "https://gitlab.m2.ru")!,
			project: .init(id: "146"),
			token: "_",
			session: .shared
		)

		dispatchGroup.enter()
		gitlabClient.diff(
			from: "1.8.1",
			to: "1.9.0"
		) { result in
			print(result.map { $0.commits.map { $0.message } })
			dispatchGroup.leave()
		}

		dispatchGroup.notify(queue: .main) {
			Self.exit()
		}

		dispatchMain()
	}
}
