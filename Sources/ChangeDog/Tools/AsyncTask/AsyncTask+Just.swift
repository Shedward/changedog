extension Async {
	static func justValue<Success, Error: Swift.Error>(
		value: Success,
		errorType: Error.Type
	) -> Async.Task<Success, Error> {
		.init { completion in
			completion(.success(value))
		}
	}

	static func justError<Success, Error: Swift.Error>(
		valueType: Success.Type,
		error: Error
	) -> Async.Task<Success, Error> {
		.init { completion in
			completion(.failure(error))
		}
	}
}
