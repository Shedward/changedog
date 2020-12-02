import Foundation

extension Async.Task {
	enum WaitingResult {
		case timeout
		case finished(Result)
	}

	func wait(timeout: DispatchTime = .now() + .seconds(60)) -> WaitingResult {
		var externalResult: Result?
		let dispatchGroup = DispatchGroup()
		dispatchGroup.enter()
		complete { result in
			externalResult = result
			dispatchGroup.leave()
		}
		let result = dispatchGroup.wait(timeout: timeout)

		switch result {
		case .success:
			guard let externalResult = externalResult else {
				fatalError("Result should be determined after Async.Task.wait leave it's dispatch group.")
			}

			return  .finished(externalResult)
		case .timedOut:
			return .timeout
		}
	}
}
