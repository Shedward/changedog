extension String {
	func prependToEachLine(_ prefix: String) -> String {
		split(separator: "\n")
			.map { "\(prefix)\($0)" }
			.joined(separator: "\n")
	}
}
