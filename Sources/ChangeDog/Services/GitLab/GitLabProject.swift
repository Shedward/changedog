import Foundation

extension GitLab {
	struct Project: Decodable {
		let id: Int
		let name: String
		let webUrl: URL

		func compareUrl(from fromTag: Tag, to toTag: Tag) -> URL {
			webUrl.appendingPathComponent("-/compare/\(fromTag.name)...\(toTag.name)")
		}
	}
}
