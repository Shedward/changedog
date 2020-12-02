extension GitLab {
	struct Commit: Decodable {
		let shortId: CommitHash
		let title: String
		let message: String
	}
}
