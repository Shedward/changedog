import Foundation

extension Jira {
	struct IssueKey: Decodable {
		enum Error: Swift.Error {
			case wrongIssueKeyFormat
		}

		let value: String

		init(value: String) throws {
			self.value = value
		}

		init(from decoder: Decoder) throws {
			let valueContainer = try decoder.singleValueContainer()
			value = try valueContainer.decode(String.self)
		}
	}
}
