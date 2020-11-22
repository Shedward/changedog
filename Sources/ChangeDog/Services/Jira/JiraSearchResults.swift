extension Jira {
	struct SearchResults: Decodable {
		let issues: [Issue]
	}
}
