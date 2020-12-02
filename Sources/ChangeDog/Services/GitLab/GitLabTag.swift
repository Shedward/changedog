import Foundation

extension GitLab {
	struct Tag: Decodable {
		typealias Name = String

		let name: Name
		let message: String?
		let commit: Commit
	}
}
