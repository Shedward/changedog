import Foundation

enum Slack {
	final class Client {
		private let restClient: RestClient

		init(slackWebhookUrl: URL, session: URLSession) {
			restClient = RestClient(
				endpoint: slackWebhookUrl,
				session: session,
				authStrategy: RestClient.NoAuth()
			)
		}

		func send(message: Message, completion: @escaping (Result<Void, RestClient.Error>) -> Void) {
			restClient.request(
				method: "POST",
				path: "",
				body: message,
				completion: completion
			)
		}
	}
}
