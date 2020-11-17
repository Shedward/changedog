extension GitLab {
	struct Commit: Decodable {
		let id: CommitHash
		let title: String
		let message: String
	}
}
