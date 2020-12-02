extension Async.Task {
	func then<NextResult>(
		_ nextTask: @escaping (Success) -> Async.Task<NextResult, Error>
	) -> Async.Task<NextResult, Error> {
		.init { [self] completion in
			self.complete { result in
				switch result {
				case .success(let success):
					nextTask(success).complete(completion)
				case .failure(let error):
					completion(.failure(error))
				}
			}
		}
	}
}
