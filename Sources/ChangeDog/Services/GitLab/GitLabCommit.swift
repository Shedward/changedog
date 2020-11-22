public extension GitLab {
	struct Commit: Decodable {
		public let id: CommitHash
		public let title: String
		public let message: String
	}
}
