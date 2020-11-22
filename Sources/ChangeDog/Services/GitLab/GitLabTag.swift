import Foundation

public extension GitLab {
	struct Tag: Decodable {
		public let name: String
		public let message: String?
		public let commit: Commit
	}
}
