extension Jira {
	struct Issue: Decodable {
		let key: IssueKey
		let summary: String

		private enum IssueCodingKeys: CodingKey {
			case key
			case fields
		}

		private enum FieldsCodingKeys: String, CodingKey {
			case summary = "summary"
			case issueType = "issuetype"
			case priority = "priority"
		}

		private enum FieldCodingKeys: CodingKey {
			case name
		}

		init(from decoder: Decoder) throws {
			let issueContainer = try decoder.container(keyedBy: IssueCodingKeys.self)
			let fieldsContainer = try issueContainer.nestedContainer(keyedBy: FieldsCodingKeys.self, forKey: .fields)

			let keyString = try issueContainer.decode(String.self, forKey: .key)
			key = try IssueKey(value: keyString)
			summary = try fieldsContainer.decode(String.self, forKey: .summary)
		}
	}
}
