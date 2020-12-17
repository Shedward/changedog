import Foundation

struct Configuration: Decodable {
	let gitlabHost: URL
	let gitlabProjectId: String
	let jiraHost: URL

	let slackHost: URL

	let slackChannel: String
	let showTagMessageRule: Actions.GenerateReleaseSummary.ShowTagMessageRule
}
