struct AdjacentsSequence<Base: Sequence>: Sequence {
	typealias Pair = (Base.Element, Base.Element)
	typealias Element = Pair

	struct Iterator: IteratorProtocol {
		typealias Element = Pair

		private let baseIterator: AnyIterator<Base.Element>
		private var previousElement: Base.Element?

		init(baseIterator: AnyIterator<Base.Element>) {
			self.baseIterator = baseIterator
			previousElement = baseIterator.next()
		}

		mutating func next() -> Pair? {
			guard
				let previousElement = previousElement,
				let currentElement = baseIterator.next()
			else {
				return nil
			}

			self.previousElement = currentElement
			return (previousElement, currentElement)
		}
	}

	private let base: Base

	init(_ base: Base) {
		self.base = base
	}

	func makeIterator() -> Iterator {
		Iterator(baseIterator: AnyIterator(base.makeIterator()))
	}
}

extension Sequence {
	func adjacents() -> AdjacentsSequence<Self> {
		AdjacentsSequence(self)
	}
}
