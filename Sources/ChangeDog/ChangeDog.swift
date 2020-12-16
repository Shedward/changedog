import Foundation
import ArgumentParser

struct ChangeDog: ParsableCommand {
	enum Error: Swift.Error {
		case wrongConfigurationPath
		case cantReadConfiguration(Swift.Error)
		case failedToParseConfiguration(Swift.Error)
	}

	@Argument var configPath: String

	func run() throws {
		let url = URL(fileURLWithPath: configPath)

		let data: Data
		switch Result(catching: { try Data(contentsOf: url) }) {
		case .success(let successData):
			data = successData
		case .failure(let error):
			throw Error.cantReadConfiguration(error)
		}

		let configuration: Configuration
		let configurationResult = Result {
			try JSONDecoder().decode(Configuration.self, from: data)
		}
		switch configurationResult {
		case .success(let successConfiguration):
			configuration = successConfiguration
		case .failure(let error):
			throw Error.failedToParseConfiguration(error)
		}

		let session = URLSession.shared

		let jiraClient = try Jira.Client(
			host: configuration.jiraHost,
			credentials: configuration.jiraCredentials,
			session: session
		)
		let gitlabClient = GitLab.Client(
			host: configuration.gitlabHost,
			projectId: configuration.gitlabProject,
			token: configuration.gitlabToken,
			session: session
		)

		let slackClient = Slack.Client(
			slackWebhookUrl: configuration.slackHost,
			session: session
		)

		let action = Actions.GenerateReleaseSummary(
			gitlabClient: gitlabClient,
			jiraClient: jiraClient,
			slackClient: slackClient,
			channel: configuration.slackChannel,
			maxReleaseCount: configuration.maxReleaseCount
		)

		action.mainTask().complete { result in
			switch result {
			case .success:
				print("Done")
			case .failure(let error):
				print("Failed with error: \(error)")
			}
			Self.exit()
		}

		dispatchMain()
	}
}
