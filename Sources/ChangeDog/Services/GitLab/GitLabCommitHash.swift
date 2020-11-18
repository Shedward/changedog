extension GitLab {
	struct CommitHash: Decodable, ExpressibleByStringLiteral {
		let hash: String

		init(stringLiteral value: StringLiteralType) {
			hash = value
		}

		init(from decoder: Decoder) throws {
			let valueContainer = try decoder.singleValueContainer()
			hash = try valueContainer.decode(String.self)
		}
	}
}
