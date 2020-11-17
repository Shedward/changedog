extension GitLab {
	enum Error: Swift.Error {
		case noData(Swift.Error?)
		case networkError(Swift.Error)
		case serialisationError(Swift.Error)
		case failedToComposeUrl
	}
}
