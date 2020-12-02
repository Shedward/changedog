import Dispatch

extension Async {

	enum GroupTaskStatus<Success, Error: Swift.Error> {
		case inProgress
		case succeeded(Success)
		case failed(Error)

		func asResult() -> Result<Success, Error>? {
			switch self {
			case .inProgress:
				return nil
			case .succeeded(let success):
				return .success(success)
			case .failed(let error):
				return .failure(error)
			}
		}
	}

	struct ParallelTaskGroup<Success, Error: Swift.Error> {
		let tasks: [Task<Success, Error>]

		func complete(_ completion: @escaping ([Result<Success, Error>]) -> Void) {
			let dispatchGroup = DispatchGroup()
			var statuses: [GroupTaskStatus<Success, Error>] = .init(repeating: .inProgress, count: tasks.count)

			tasks.enumerated().forEach { index, task in
				dispatchGroup.enter()
				task.complete { taskResult in
					switch taskResult {
					case .success(let success):
						statuses[index] = .succeeded(success)
					case .failure(let failure):
						statuses[index] = .failed(failure)
					}
					dispatchGroup.leave()
				}
			}

			dispatchGroup.notify(queue: .main) {
				let results = statuses.compactMap { $0.asResult() }
				assert(statuses.count == results.count, "All tasks in ParallelTaskGroup should be finished in notify.")
				completion(results)
			}
		}

		func asTask() -> Async.Task<[Result<Success, Error>], Never> {
			.init { completion in
				self.complete { results in
					completion(.success(results))
				}
			}
		}
	}

	static func forEach<Success, Error, ItemsSequence: Sequence>(
		in items: ItemsSequence,
		_ task: (ItemsSequence.Element) -> Task<Success, Error>
	) -> Async.Task<[Swift.Result<Success, Error>], Never> {
		Async.ParallelTaskGroup(tasks: items.map(task)).asTask()
	}
}
