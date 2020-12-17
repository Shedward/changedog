import Foundation

struct Configuration: Decodable {
	enum Error: Swift.Error {
		case cantDecodeUrl(String, forKey: CodingKey)
	}

	let gitlabHost: URL
	let gitlabProject: GitLab.ProjectId
	let gitlabToken: String

	let jiraHost: URL
	let jiraCredentials: Jira.Credentials

	let slackHost: URL

	let slackChannel: String
	let showTagMessageRule: Actions.GenerateReleaseSummary.ShowTagMessageRule

	private enum ConfigurationKey: String, CodingKey {
		case gitlabHost = "gitlabHost"
		case gitlabProjectId = "gitlabProjectId"
		case gitlabToken = "gitlabToken"

		case jiraHost = "jiraHost"
		case jiraUsername = "jiraUsername"
		case jiraToken = "jiraToken"

		case slackHost = "slackHost"
		case slackChannel = "slackChannel"
		case showTagMessage = "showTagMessage"
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: ConfigurationKey.self)

		gitlabHost = try Self.decodeUrl(in: container, forKey: .gitlabHost)
		gitlabProject = GitLab.ProjectId(id: try container.decode(String.self, forKey: .gitlabProjectId))
		gitlabToken = try container.decode(String.self, forKey: .gitlabToken)

		jiraHost = try Self.decodeUrl(in: container, forKey: .jiraHost)
		jiraCredentials = Jira.Credentials(
			username: try container.decode(String.self, forKey: .jiraUsername),
			token: try container.decode(String.self, forKey: .jiraToken)
		)

		slackHost = try Self.decodeUrl(in: container, forKey: .slackHost)
		slackChannel = try container.decode(String.self, forKey: .slackChannel)

		showTagMessageRule = (try? container.decode(Actions.GenerateReleaseSummary.ShowTagMessageRule.self, forKey: .showTagMessage))
			?? .always
	}

	private static func decodeUrl(in container: KeyedDecodingContainer<ConfigurationKey>, forKey key: ConfigurationKey) throws -> URL {
		let urlString = try container.decode(String.self, forKey: key)
		guard let url = URL(string: urlString) else {
			throw Error.cantDecodeUrl(urlString, forKey: key)
		}
		return url
	}
}
