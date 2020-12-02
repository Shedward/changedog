import Foundation

extension Jira {
	struct IssueKey: Decodable, Hashable {
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

		static func extract(from string: String) throws -> [IssueKey] {
			let regex = try NSRegularExpression(pattern: "[A-Z]{2,10}-[0-9]{1,}")

			let matchesRanges = regex.matches(
				in: string,
				range: NSRange(string.startIndex..., in: string)
			)

			let matches = try matchesRanges.compactMap { result throws -> Jira.IssueKey? in
				guard let range = Range(result.range, in: string) else { return nil }
				return try Jira.IssueKey(value: String(string[range]))
			}

			return matches
		}
	}
}
