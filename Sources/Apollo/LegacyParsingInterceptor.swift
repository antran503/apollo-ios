import Foundation

/// An interceptor which parses code using the legacy parsing system.
public class LegacyParsingInterceptor: ApolloInterceptor {
  
  public enum LegacyParsingError: Error, LocalizedError {
    case noResponseToParse
    case couldNotParseToLegacyJSON(data: Data)
    
    public var errorDescription: String? {
      switch self {
      case .noResponseToParse:
        return "The Codable Parsing Interceptor was called before a response was received to be parsed. Double-check the order of your interceptors."
      case .couldNotParseToLegacyJSON(let data):
        var errorStrings = [String]()
        errorStrings.append("Could not parse data to legacy JSON format.")
        if let dataString = String(bytes: data, encoding: .utf8) {
          errorStrings.append("Data received as a String was:")
          errorStrings.append(dataString)
        } else {
          errorStrings.append("Data of count \(data.count) also could not be parsed into a String.")
        }
        
        return errorStrings.joined(separator: " ")
      }
    }
  }
  
  public var cacheKeyForObject: CacheKeyForObject?

  /// Designated Initializer
  public init(cacheKeyForObject: CacheKeyForObject? = nil) {
    self.cacheKeyForObject = cacheKeyForObject
  }
  
  public func interceptAsync<Operation: GraphQLOperation>(
    chain: RequestChain<Operation>,
    request: HTTPRequest<Operation>,
    completion: @escaping (HTTPResponse<Operation>) -> Void) {
    
    debugPrint("LEGACY PARSING INTERCEPTOR")
    
    chain.proceedAsync(
      request: request,
      completion: { httpResponse in
        
        debugPrint("LEGACY PARSING RESPONSE")
        do {
          let deserialized = try? JSONSerializationFormat.deserialize(data: httpResponse.rawData)
          let json = deserialized as? JSONObject
          guard let body = json else {
            throw LegacyParsingError.couldNotParseToLegacyJSON(data: httpResponse.rawData)
          }
          
          let graphQLResponse = GraphQLResponse(operation: request.operation, body: body)
          httpResponse.legacyResponse = graphQLResponse
          
          switch request.cachePolicy {
          case .fetchIgnoringCacheCompletely:
            // There is no cache, so we don't need to get any info on dependencies. Use fast parsing.
            let fastResult = try graphQLResponse.parseResultFast()
            httpResponse.parsedResponse = fastResult
            completion(httpResponse)
          default:
            graphQLResponse.parseResultWithCompletion(cacheKeyForObject: self.cacheKeyForObject) { parsingResult in
              switch parsingResult {
              case .failure(let error):
                chain.handleErrorAsync(error,
                                       request: request,
                                       response: httpResponse)
              case .success(let (parsedResult, _)):
                httpResponse.parsedResponse = parsedResult
                completion(httpResponse)
              }
            }
          }
        } catch {
          chain.handleErrorAsync(error,
                                 request: request,
                                 response: httpResponse)
        }
      })
  }
}
