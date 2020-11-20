import Foundation

/// An interceptor to check the response code returned with a request.
public class ResponseCodeInterceptor: ApolloInterceptor {
  
  public enum ResponseCodeError: Error, LocalizedError {
    case invalidResponseCode(response: HTTPURLResponse?, rawData: Data?)
    
    public var errorDescription: String? {
      switch self {
      case .invalidResponseCode(let response, let rawData):
        var errorStrings = [String]()
        if let code = response?.statusCode {
          errorStrings.append("Received a \(code) error.")
        } else {
          errorStrings.append("Did not receive a valid status code.")
        }
        
        if
          let data = rawData,
          let dataString = String(bytes: data, encoding: .utf8) {
          errorStrings.append("Data returned as a String was:")
          errorStrings.append(dataString)
        } else {
          errorStrings.append("Data was nil or could not be transformed into a string.")
        }
        
        return errorStrings.joined(separator: " ")
      }
    }
  }
  
  /// Designated initializer
  public init() {}
  
  public func interceptAsync<Operation: GraphQLOperation>(
    chain: RequestChain<Operation>,
    request: HTTPRequest<Operation>,
    completion: @escaping (HTTPResponse<Operation>) -> Void) {

    chain.proceedAsync(
      request: request,
      completion: { httpResponse in
        guard httpResponse.httpResponse.apollo.isSuccessful else {
          let error = ResponseCodeError.invalidResponseCode(response: httpResponse.httpResponse,
                                                            rawData: httpResponse.rawData)
          
          chain.handleErrorAsync(error,
                                 request: request,
                                 response: httpResponse)
          return
        }
        
        completion(httpResponse)
      })
  }
}
