import Foundation

protocol CodingStrategy {
	var encodingContentType: String { get }
	var decodingContentType: String { get }

	func encode<T: Encodable>(_ value: T) throws -> Data
	func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}

extension RestClient {
	struct JsonCoding: CodingStrategy {
		let encoder: JSONEncoder
		let decoder: JSONDecoder

		let encodingContentType: String = "application/json"
		let decodingContentType: String = "application/json"

		init(encoder: JSONEncoder = .init(), decoder: JSONDecoder = .init()) {
			self.encoder = encoder
			self.decoder = decoder
		}

		func encode<T>(_ value: T) throws -> Data where T : Encodable {
			try encoder.encode(value)
		}

		func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
			try decoder.decode(T.self, from: data)
		}
	}

	struct UrlEncodedJSONPayloadCoding: CodingStrategy {
		enum Error: Swift.Error {
			case failedToEncodeModelToJSON(Swift.Error)
			case failedToEncodePayloadToUTF8
			case failedToEncodePayloadToPercentEncoding
			case failedToEncodePayloadToData
			case failedToEncodeEmptyJSON
			case decodingNotSupported
		}

		let encodingContentType: String = "application/x-www-form-urlencoded"
		let decodingContentType: String = "application/json"

		let encoder: JSONEncoder
		let decoder: JSONDecoder
		let payloadAllowedCharacters: CharacterSet = {
			var set = CharacterSet.urlQueryAllowed
			set.remove(charactersIn: ":/?#[]@!$&'()*+,;=")
			return set
		}()

		init(encoder: JSONEncoder = .init(), decoder: JSONDecoder = .init()) {
			self.encoder = encoder
			self.decoder = decoder
		}

		func encode<T>(_ value: T) throws -> Data where T : Encodable {
			do {
				let modelData = try encoder.encode(value)
				guard let modelString = String(data: modelData, encoding: .utf8) else {
					throw Error.failedToEncodePayloadToUTF8
				}

				var urlComponents = URLComponents()
				urlComponents.queryItems = [
					URLQueryItem(name: "payload", value: modelString.addingPercentEncoding(withAllowedCharacters: payloadAllowedCharacters))
				]

				guard let query = urlComponents.query else {
					throw Error.failedToEncodePayloadToPercentEncoding
				}

				guard let payloadData = query.data(using: .utf8) else {
					throw Error.failedToEncodePayloadToData
				}

				return payloadData
			} catch {
				throw Error.failedToEncodeModelToJSON(error)
			}
		}

		func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
			let emptyJson = "{}"

			guard let data = emptyJson.data(using: .utf8) else {
				throw Error.failedToEncodeEmptyJSON
			}
			return try decoder.decode(T.self, from: data)
		}
	}
}
