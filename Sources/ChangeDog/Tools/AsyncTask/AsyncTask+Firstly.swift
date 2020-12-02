extension Async {
	static func firstly<Success, Error: Swift.Error>(_ createFirstTask: () -> Task<Success, Error>) -> Task<Success, Error> {
		createFirstTask()
	}
}
