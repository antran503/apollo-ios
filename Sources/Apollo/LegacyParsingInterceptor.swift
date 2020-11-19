import Foundation

/// An interceptor which parses code using the legacy parsing system.
public class LegacyParsingInterceptor: ApolloPostNetworkInterceptor {
  
  public enum LegacyParsingError: Error, LocalizedError {
    case couldNotParseToLegacyJSON(data: Data)
    
    public var errorDescription: String? {
      switch self {
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
  
  public func handleResponse<Operation: GraphQLOperation>(
    chain: RequestChain,
    request: HTTPRequest<Operation>,
    response: HTTPResponse<Operation>,
    completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void) {
    
    do {
      let deserialized = try? JSONSerializationFormat.deserialize(data: response.rawData)
      let json = deserialized as? JSONObject
      guard let body = json else {
        throw LegacyParsingError.couldNotParseToLegacyJSON(data: response.rawData)
      }
      
      let graphQLResponse = GraphQLResponse(operation: request.operation, body: body)
      response.legacyResponse = graphQLResponse
      
      switch request.cachePolicy {
      case .fetchIgnoringCacheCompletely:
        // There is no cache, so we don't need to get any info on dependencies. Use fast parsing.
        let fastResult = try graphQLResponse.parseResultFast()
        response.parsedResponse = fastResult
        chain.proceedWithHandlingResponse(request: request,
                                          response: response,
                                          completion: completion)
      default:
        graphQLResponse.parseResultWithCompletion(cacheKeyForObject: self.cacheKeyForObject) { parsingResult in
          switch parsingResult {
          case .failure(let error):
            chain.handleErrorAsync(error,
                                   request: request,
                                   response: response,
                                   completion: completion)
          case .success(let (parsedResult, _)):
            response.parsedResponse = parsedResult
            chain.proceedWithHandlingResponse(request: request,
                                              response: response,
                                              completion: completion)
          }
        }
      }
    } catch {
      chain.handleErrorAsync(error,
                             request: request,
                             response: response,
                             completion: completion)
    }
  }
}
