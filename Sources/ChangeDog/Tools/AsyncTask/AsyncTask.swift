enum Async {
	struct Task<Success, Error: Swift.Error> {
		typealias Result = Swift.Result<Success, Error>
		typealias Block = (_ finish: @escaping (Result) -> Void) -> Void

		private let block: Block

		init(_ block: @escaping Block) {
			self.block = block
		}

		func complete(_ completion: @escaping (Result) -> Void) {
			block(completion)
		}
	}
}
