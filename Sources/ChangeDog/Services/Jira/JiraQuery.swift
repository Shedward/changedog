protocol Compiling {
	func compile() throws -> String
}

extension Jira {
	struct Query: Compiling {
		enum Field: String, Compiling {
			case issue = "issue"

			func compile() throws -> String {
				rawValue
			}
		}

		enum Operator: String, Compiling {
			case equal = "="
			case notEqual = "!="
			case `in` = "in"
			case notIn = "not in"

			func compile() throws -> String {
				rawValue
			}
		}

		enum Value: Compiling {
			case single(String)
			case multiple([String])

			func compile() throws -> String {
				switch self {
				case .single(let value):
					return value
				case .multiple(let values):
					return "("
						+ values.map { "\"\($0)\"" }.joined(separator: ",")
						+ ")"
				}
			}
		}

		struct Rule: Compiling {
			let field: Field
			let `operator`: Operator
			let value: Value

			func compile() throws -> String {
				"\(try field.compile()) \(try `operator`.compile()) \(try value.compile())"
			}
		}

		enum Keyword: String, Compiling {
			case and = "AND"
			case or = "OR"
			case not = "NOT"
			case empty = "EMPTY"
			case null = "NULL"
			case orderBy = "ORDER BY"

			func compile() throws -> String {
				rawValue
			}
		}

		let rule: Rule

		static func issuesWithIds(_ ids: [Jira.IssueKey]) -> Query {
			Query(rule: Rule(field: .issue, operator: .in, value: .multiple(ids.map { $0.value })))
		}

		func compile() throws -> String {
			try rule.compile()
		}
	}
}
