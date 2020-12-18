import Foundation

struct Configuration: Decodable {
	let gitlabHost: URL
	let gitlabToken: String?
	let gitlabProjectId: String

	let jiraHost: URL
	let jiraUsername: String?
	let jiraPassword: String?

	let slackHost: URL
	let slackChannel: String?

	let showTagMessageRule: Actions.GenerateReleaseSummary.ShowTagMessageRule
}
