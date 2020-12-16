extension Actions {
	struct GenerateReleaseSummary: Action {
		enum Error: Swift.Error {
			case failedToGetTags(RestClient.Error)
			case failedToGetProject(RestClient.Error)
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
				.then { tags -> Async.Task<(GitLab.Project, [GitLab.Tag]), Error> in
					self.gitlabClient.project()
						.mapSuccess { project in (project, tags) }
						.mapError { Error.failedToGetProject($0) }
				}
				.then { project, tags -> Async.Task<String?, Error> in
					self.releases(for: project, tags: tags).withErrorType(Error.self)
				}
				.then { report -> Async.Task<Void, Error> in
					if let report = report {
						let message = Slack.Message(
							channel: channel,
							username: username,
							iconUrl: nil,
							iconEmoji: iconEmoji,
							text: report
						)
						return self.slackClient.send(message: message)
							.mapError { Error.failedToSendReport($0) }
					} else {
						return Async.justValue(value: (), errorType: Error.self)
					}
				}
				.mapError { $0 }
		}


		private func releases(
			for project: GitLab.Project,
			tags: [GitLab.Tag]
		) -> Async.Task<String?, Never> {
			let processingTags = tags.prefix(maxReleaseCount + 1).adjacents()
			return Async
				.forEach(in: processingTags) { tags -> Async.Task<String, Never> in
					self.issuesInRelease(project: project, fromTag: tags.1, toTag: tags.0)
				}
				.mapSuccess { results in
					if results.isEmpty {
						return nil
					} else {
						return self.releasesReport(project: project, tagReports: results)
					}
				}
		}

		private func releasesReport(project: GitLab.Project, tagReports: [Result<String, Never>]) -> String {
			var output: String = "🎉   Новые изменения в *\(project.name)*:\n\n\n"
			output += tagReports
				.compactMap { result -> String? in
					try? result.get()
				}
				.joined(separator: "\n\n")
			return output
		}

		private func issuesInRelease(
			project: GitLab.Project,
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
						description = self.formatIssuesReport(
							project: project,
							from: fromTag,
							to: toTag,
							issues: success.issues
						)
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

		private func formatIssuesReport(
			project: GitLab.Project,
			from fromTag: GitLab.Tag,
			to toTag: GitLab.Tag,
			issues: [Jira.Issue]
		) -> String {
			let tagName = toTag.name.maskingMarkdown()
			let tagUrl = project.compareUrl(from: fromTag, to: toTag)
			var output = "🏷   *<\(tagUrl)|\(tagName)>*\n"

			if issues.isEmpty {
				if let tagMessage = toTag.message {
					output += tagMessage
						.maskingMarkdown()
						.prependToEachLine(">")
					output += "\n"
				} else {
					output += "\tНет тасок и описания"
				}
			} else {
				if let tagMessage = toTag.message {
					output += tagMessage
						.maskingMarkdown()
						.prependToEachLine(">")
					output += "\n"
				}
				output += issues
					.map { issue in
						var issueDescription: String = ""
						issueDescription += "◦  "
						let issueUrl = jiraClient.url(for: issue.key)
						issueDescription += "<\(issueUrl)|\(issue.key.value.maskingMarkdown())>"
						issueDescription += ": \(issue.summary.maskingMarkdown())"
						issueDescription += " [_\(issue.status.maskingMarkdown())_]"
						return issueDescription.prependToEachLine("\t")
					}
					.joined(separator: "\n")
			}

			output += "\n"
			return output
		}

		private func formatFailureReport(for tag: GitLab.Tag, error: Swift.Error) -> String {
			var output = "*Tag: \(tag.name.maskingMarkdown())*\n"
			output += "Не удалось получить задачи: \(error)".prependToEachLine("\t")
			output += "\n"
			return output
		}
	}
}
