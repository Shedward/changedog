extension Actions {
	struct GenerateReleaseSummary: Action {
		enum Error: Swift.Error {
			case failedToGetTags(RestClient.Error)
			case failedToGetDiff(RestClient.Error)
			case failedToFindIssues(RestClient.Error)
			case failedToSendReport(RestClient.Error)
		}

		let gitlabClient: GitLab.Client
		let jiraClient: Jira.Client
		let slackClient: Slack.Client
		let channel: String
		let maxReleaseCount: Int

		let username = "ChangeDog"
		let iconEmoji = ":dog:"

		init(
			gitlabClient: GitLab.Client,
			jiraClient: Jira.Client,
			slackClient: Slack.Client,
			channel: String,
			maxReleaseCount: Int
		) {
			self.gitlabClient = gitlabClient
			self.jiraClient = jiraClient
			self.slackClient = slackClient
			self.channel = channel
			self.maxReleaseCount = maxReleaseCount
		}

		func mainTask() -> Async.Task<Void, Swift.Error> {
			Async
				.firstly {
					self.gitlabClient.tags()
						.mapError { Error.failedToGetTags($0) }
				}
				.then { tags -> Async.Task<String, Error> in
					self.releases(for: tags).withErrorType(Error.self)
				}
				.then { report -> Async.Task<Void, Error> in
					let message = Slack.Message(
						channel: channel,
						username: username,
						iconUrl: nil,
						iconEmoji: iconEmoji,
						text: report
					)
					return self.slackClient.send(message: message)
						.mapError { Error.failedToSendReport($0) }
				}
				.mapError { $0 }
		}


		private func releases(
			for tags: [GitLab.Tag]
		) -> Async.Task<String, Never> {
			let processingTags = tags.prefix(maxReleaseCount + 1).adjacents()
			return Async
				.forEach(in: processingTags) { tags -> Async.Task<String, Never> in
					self.issuesInRelease(fromTag: tags.1, toTag: tags.0)
				}
				.mapSuccess { results in
					if results.isEmpty {
						return "Нет релизов"
					} else {
						return results
							.compactMap { result -> String? in
								try? result.get()
							}
							.joined(separator: "\n\n")
					}
				}
		}

		private func issuesInRelease(
			fromTag: GitLab.Tag,
			toTag: GitLab.Tag
		) -> Async.Task<String, Never> {
			Async
				.firstly {
					gitlabClient
						.diff(from: fromTag, to: toTag)
						.mapError { Error.failedToGetDiff($0) }
						.mapSuccess { diff in
							self.extractIssues(tag: toTag, from: diff)
						}
				}
				.then { issues -> Async.Task<Jira.SearchResults, Error> in
					if issues.isEmpty {
						return Async.justValue(value: Jira.SearchResults(issues: []), errorType: Error.self)
					} else {
						return self.jiraClient.searchIssues(query: .issuesWithIds(issues))
							.mapError { Error.failedToFindIssues($0) }
					}
				}
				.map { searchResult -> Result<String, Never> in
					let description: String

					switch searchResult {
					case .success(let success):
						description = self.formatIssuesReport(for: toTag, issues: success.issues)
					case .failure(let error):
						description = self.formatFailureReport(for: toTag, error: error)
					}

					return .success(description)
				}
		}

		private func extractIssues(tag: GitLab.Tag, from diff: GitLab.Diff) -> [Jira.IssueKey] {
			let issuesFromTag = (try? Jira.IssueKey.extract(from: tag.message ?? "")) ?? []
			let issues = diff.commits.flatMap { commit -> [Jira.IssueKey] in
				let titleIssues =
					(try? Jira.IssueKey.extract(from: commit.title)) ?? []
				let messageIssues =
					(try? Jira.IssueKey.extract(from: commit.message)) ?? []
				return titleIssues + messageIssues
			}
			return Array(Set(issues + issuesFromTag))
		}

		private func formatIssuesReport(for tag: GitLab.Tag, issues: [Jira.Issue]) -> String {
			var output = "Tag: \(tag.name)\n"

			if issues.isEmpty {
				if let tagMessage = tag.message {
					output += addTabToMultilineString(tagMessage) + "\n"
				} else {
					output += "\tНет тасок и описания"
				}
			} else {
				if let tagMessage = tag.message {
					output += addTabToMultilineString(tagMessage) + "\n"
				}
				output += "\n\tУпомянутые задачи:\n"
				output += issues
					.map { issue in
						addTabToMultilineString("\(issue.key.value): \(issue.summary)")
					}
					.joined(separator: "\n")
			}

			return output
		}

		private func formatFailureReport(for tag: GitLab.Tag, error: Swift.Error) -> String {
			var output = "Tag: \(tag.name)\n"
			output.append(addTabToMultilineString("Не удалось получить задачи: \(error)"))
			return output
		}

		private func addTabToMultilineString(_ string: String) -> String {
			string
				.split(separator: "\n")
				.map { "\t\($0)" }
				.joined(separator: "\n")
		}
	}
}
