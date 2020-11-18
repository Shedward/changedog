import Foundation

extension GitLab {
	struct Tag: Decodable {
		let name: String
		let message: String?
		let commit: Commit
	}
}
