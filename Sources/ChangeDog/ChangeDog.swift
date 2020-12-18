import Foundation
import ArgumentParser

struct ChangeDog: ParsableCommand {
	enum Error: Swift.Error {
		case wrongConfigurationPath
		case gitlabTokenNotSpecified
		case jiraCredentialsNotSpecified
		case cantReadConfiguration(Swift.Error)
		case failedToParseConfiguration(Swift.Error)
	}

	@Argument
	var configPath: String

	@Option
	var jiraUsername: String?

	@Option
	var jiraPassword: String?

	@Option
	var gitlabToken: String?

	@Option
	var slackChannel: String?

	@Option
	var daysCount: Int = 1

	@Option
	var dryRun: Bool = false

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

		guard let gitlabToken = self.gitlabToken ?? configuration.gitlabToken else {
			throw Error.gitlabTokenNotSpecified
		}

		guard
			let jiraUsername = self.jiraUsername ?? configuration.jiraUsername,
			let jiraPassword = self.jiraPassword ?? configuration.jiraPassword
		else {
			throw Error.jiraCredentialsNotSpecified
		}

		let session = URLSession.shared

		let jiraClient = try Jira.Client(
			host: configuration.jiraHost,
			credentials: Jira.Credentials(username: jiraUsername, token: jiraPassword),
			session: session
		)
		let gitlabClient = GitLab.Client(
			host: configuration.gitlabHost,
			projectId: GitLab.ProjectId(id: configuration.gitlabProjectId),
			token: gitlabToken,
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
			slackChannel: slackChannel ?? configuration.slackChannel,
			showTagMessageRule: configuration.showTagMessageRule,
			daysCount: daysCount,
			dryRun: dryRun
		)

		action.mainTask().complete { result in
			switch result {
			case .success:
				print("Done")
				Self.exit()
			case .failure(let error):
				Self.exit(withError: error)
			}
		}

		dispatchMain()
	}
}
