extension Async.Task {
	func map<NewSuccess, NewError>(
		_ transform: @escaping (Result) -> Async.Task<NewSuccess, NewError>.Result
	) -> Async.Task<NewSuccess, NewError> {
		.init { [self] completion in
			self.complete { result in
				completion(transform(result))
			}
		}
	}

	func mapSuccess<NewSuccess>(
		_ transform: @escaping (Success) -> NewSuccess
	) -> Async.Task<NewSuccess, Error> {
		map { $0.map(transform) }
	}

	func mapError<NewError>(
		_ transform: @escaping (Error) -> NewError
	) -> Async.Task<Success, NewError> {
		map { $0.mapError(transform) }
	}

	func replaceError(
		_ transform: @escaping (Error) -> Success
	) -> Async.Task<Success, Never> {
		map { $0.flatMapError { .success(transform($0)) } }
	}

	func mapToResult() -> Async.Task<Swift.Result<Success, Error>, Never> {
		map { result in
			.success(result)
		}
	}

	func completeSuccess(_ completion: @escaping (Success) -> Void) {
		complete { result in
			switch result {
			case .success(let success):
				completion(success)
			case .failure:
				break
			}
		}
	}

	func completeErrorError(_ completion: @escaping (Error) -> Void) {
		complete { result in
			switch result {
			case .success:
				break
			case .failure(let error):
				completion(error)
			}
		}
	}
}

extension Async.Task where Error == Never {
	func withErrorType<NewError>(_ type: NewError.Type) -> Async.Task<Success, NewError> {
		map { result in
			switch result {
			case .success(let success):
				return .success(success)
			}
		}
	}
}
