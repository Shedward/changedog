import Foundation

extension Actions {
	struct GenerateReleaseSummary: Action {
		enum Error: Swift.Error {
			case failedToGetTags(RestClient.Error)
			case failedToGetProject(RestClient.Error)
			case failedToGetDiff(RestClient.Error)
			case failedToFindIssues(RestClient.Error)
			case failedToSendReport(RestClient.Error)
		}

		enum ShowTagMessageRule: String, Decodable {
			case always = "always"
			case never = "never"
			case onlyWhenNoTasks = "onlyWhenNoTasks"

			func shouldShowTagMessage(for issues: [Jira.Issue]) -> Bool {
				switch self {
				case .always:
					return true
				case .never:
					return false
				case .onlyWhenNoTasks:
					return issues.isEmpty
				}
			}
		}

		let gitlabClient: GitLab.Client
		let jiraClient: Jira.Client
		let slackClient: Slack.Client
		let slackChannel: String?
		let showTagMessageRule: ShowTagMessageRule
		let daysCount: Int
		let dryRun: Bool

		let username = "ChangeDog"
		let iconEmoji = ":dog:"

		init(
			gitlabClient: GitLab.Client,
			jiraClient: Jira.Client,
			slackClient: Slack.Client,
			slackChannel: String?,
			showTagMessageRule: ShowTagMessageRule,
			daysCount: Int,
			dryRun: Bool
		) {
			self.gitlabClient = gitlabClient
			self.jiraClient = jiraClient
			self.slackClient = slackClient
			self.slackChannel = slackChannel
			self.showTagMessageRule = showTagMessageRule
			self.daysCount = daysCount
			self.dryRun = dryRun
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
							channel: slackChannel,
							username: username,
							iconUrl: nil,
							iconEmoji: iconEmoji,
							text: report
						)
						print(report)
						if dryRun {
							print("This is a --dry-run, nothing was send")
							return Async.justValue(value: (), errorType: Error.self)
						} else {
							print("Sent to \(slackChannel ?? "Slack")")
							return self.slackClient.send(message: message)
								.mapError { Error.failedToSendReport($0) }
						}
					} else {
						print("Nothing new")
						return Async.justValue(value: (), errorType: Error.self)
					}
				}
				.mapError { $0 }
		}

		private func tagsToShow(tags: [GitLab.Tag]) -> [GitLab.Tag] {
			guard let dayBefore = Calendar.current.date(
				byAdding: .day,
				value: -daysCount,
				to: Date(),
				wrappingComponents: true
			)
			else {
				return []
			}

			let foundLastReleaseFromDayBefore = tags.firstIndex { tag -> Bool in
				tag.commit.createdAt < dayBefore
			}

			guard let lastReleaseFromDayBefore = foundLastReleaseFromDayBefore else {
				return []
			}

			return Array(tags[...lastReleaseFromDayBefore])
		}

		private func releases(
			for project: GitLab.Project,
			tags: [GitLab.Tag]
		) -> Async.Task<String?, Never> {
			let processingTags = self.tagsToShow(tags: tags).adjacents()
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
			var output: String = "🎉   Новые изменения в *<\(project.webUrl)|\(project.nameWithNamespace.maskingMarkdown())>*:\n\n\n"
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
						description = self.formatFailureReport(
							project: project,
							from: fromTag,
							to: toTag,
							error: error
						)
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
			let tagUrl = project.urlForCompare(from: fromTag, to: toTag)
			var output = "🏷   *<\(tagUrl)|\(tagName)>*\n"

			let haveTagMessage: Bool
			if let tagMessage = toTag.message, showTagMessageRule.shouldShowTagMessage(for: issues) {
				output += tagMessage
					.maskingMarkdown()
					.prependToEachLine(">")
				output += "\n"
				haveTagMessage = true
			} else {
				haveTagMessage = false
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

			if !haveTagMessage && issues.isEmpty {
				output += "Нет ни задач ни описания в теге.\n"
			}

			output += "\n"
			return output
		}

		private func formatFailureReport(
			project: GitLab.Project,
			from fromTag: GitLab.Tag,
			to toTag: GitLab.Tag,
			error: Swift.Error
		) -> String {
			let tagName = toTag.name.maskingMarkdown()
			let tagUrl = project.urlForCompare(from: fromTag, to: toTag)
			var output = "🏷   *<\(tagUrl)|\(tagName)>*\n"
			output += "Не удалось получить задачи: \n"
			output += "```"
			output += "\(error)".prependToEachLine("\t")
			output += "```"
			output += "\n"
			return output
		}
	}
}
