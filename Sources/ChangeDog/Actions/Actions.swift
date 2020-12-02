
protocol Action {
	func mainTask() -> Async.Task<Void, Swift.Error>
}

enum Actions {
}
