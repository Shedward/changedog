extension String {
	func prependToEachLine(_ prefix: String) -> String {
		split(separator: "\n")
			.map { "\(prefix)\($0)" }
			.joined(separator: "\n")
	}

	func maskingMarkdown() -> String {
		replacingOccurrences(of: "*", with: "﹡")
			.replacingOccurrences(of: "_", with: "⎽")
			.replacingOccurrences(of: "`", with: "'")
			.replacingOccurrences(of: ">", with: "＞")
			.replacingOccurrences(of: "<", with: "＜")
	}
}
