import Foundation

public class CodableParsingInterceptor<FlexDecoder: FlexibleDecoder>: ApolloInterceptor {
  
  public enum CodableParsingError: Error, LocalizedError {
    case noResponseToParse
    
    public var errorDescription: String? {
      switch self {
      case .noResponseToParse:
        return "The Codable Parsing Interceptor was called before a response was received to be parsed. Double-check the order of your interceptors."
      }
    }
  }

  let decoder: FlexDecoder
  
  var isCancelled: Bool = false
  
  public init(decoder: FlexDecoder) {
    self.decoder = decoder
  }
  
  public func interceptAsync<Operation: GraphQLOperation>(
    chain: RequestChain<Operation>,
    request: HTTPRequest<Operation>,
    completion: @escaping (HTTPResponse<Operation>) -> Void) {

    chain.proceedAsync(request: request) { httpResponse in
      do {
        let parsedData = try GraphQLResult<Operation.Data>(from: httpResponse.rawData, decoder: self.decoder)
        httpResponse.parsedResponse = parsedData
        completion(httpResponse)
      } catch {
        chain.handleErrorAsync(error,
                               request: request,
                               response: httpResponse)
      }
    }
  }
}
