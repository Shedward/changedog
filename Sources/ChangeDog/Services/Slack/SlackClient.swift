import Foundation

enum Slack {
	final class Client {
		enum Error: Swift.Error {
			case failedToEncodePayloadToUTF8
		}

		private let restClient: RestClient
		private let payloadEncoder: JSONEncoder = {
			let encoder = JSONEncoder()
			encoder.keyEncodingStrategy = .convertToSnakeCase
			return encoder
		}()

		init(slackWebhookUrl: URL, session: URLSession) {
			restClient = RestClient(
				endpoint: slackWebhookUrl,
				session: session,
				codingStrategy: RestClient.UrlEncodedJSONPayloadCoding(
					encoder: {
						let encoder = JSONEncoder()
						encoder.keyEncodingStrategy = .convertToSnakeCase
						return encoder
					}()
				),
				authStrategy: RestClient.NoAuth()
			)
		}

		func send(message: Message) -> Async.Task<Void, RestClient.Error> {
			restClient.request(
				method: "POST",
				body: message
			)
		}
	}
}
