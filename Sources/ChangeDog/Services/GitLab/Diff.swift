extension GitLab {
	struct Diff: Decodable {
		let commits: [Commit]
	}
}
