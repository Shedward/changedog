public extension GitLab {
	struct Diff: Decodable {
		public let commits: [Commit]
	}
}
