extension Jira {
	struct Issue: Decodable {
		let key: IssueKey
		let summary: String
		let status: String

		private enum IssueCodingKey: CodingKey {
			case key
			case fields
		}

		private enum FieldListCodingKey: String, CodingKey {
			case summary = "summary"
			case issueType = "issuetype"
			case priority = "priority"
			case status = "status"
		}

		private enum FieldCodingKey: CodingKey {
			case name
		}

		init(from decoder: Decoder) throws {
			let issueContainer = try decoder.container(keyedBy: IssueCodingKey.self)
			let fieldsContainer = try issueContainer.nestedContainer(keyedBy: FieldListCodingKey.self, forKey: .fields)

			let keyString = try issueContainer.decode(String.self, forKey: .key)
			key = try IssueKey(value: keyString)
			summary = try fieldsContainer.decode(String.self, forKey: .summary)
			status = try Self.decodeFieldName(in: fieldsContainer, forKey: .status)
		}

		private static func decodeFieldName(
			in container: KeyedDecodingContainer<FieldListCodingKey>,
			forKey: FieldListCodingKey
		) throws -> String {
			let fieldContainer = try container.nestedContainer(keyedBy: FieldCodingKey.self, forKey: forKey)
			return try fieldContainer.decode(String.self, forKey: .name)
		}
	}
}
