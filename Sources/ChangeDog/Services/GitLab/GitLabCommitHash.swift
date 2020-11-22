public extension GitLab {
	struct CommitHash: Decodable, ExpressibleByStringLiteral {
		public let hash: String

		public init(stringLiteral value: StringLiteralType) {
			hash = value
		}

		public init(from decoder: Decoder) throws {
			let valueContainer = try decoder.singleValueContainer()
			hash = try valueContainer.decode(String.self)
		}
	}
}
