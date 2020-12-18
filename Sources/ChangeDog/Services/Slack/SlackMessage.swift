extension Slack {
	struct Message: Encodable {
		let channel: String?
		let username: String
		let iconUrl: String?
		let iconEmoji: String?
		let text: String
	}
}
