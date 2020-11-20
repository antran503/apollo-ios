import Foundation

public class AutomaticPersistedQueryInterceptor: ApolloInterceptor {
  
  public enum APQError: LocalizedError {
    case noParsedResponse
    case persistedQueryRetryFailed(operationName: String)
    
    public var errorDescription: String? {
      switch self {
      case .noParsedResponse:
        return "The Automatic Persisted Query Interceptor was called before a response was received. Double-check the order of your interceptors."
      case .persistedQueryRetryFailed(let operationName):
        return "Persisted query retry failed for operation \"\(operationName)\"."
      }
    }
  }
  
  /// Designated initializer
  public init() {}
  
  public func interceptAsync<Operation: GraphQLOperation>(
    chain: RequestChain<Operation>,
    request: HTTPRequest<Operation>,
    completion: @escaping (HTTPResponse<Operation>) -> Void) {
    
    guard
      let jsonRequest = request as? JSONRequest,
      jsonRequest.autoPersistQueries else {
        // Not a request that handles APQs, continue without adding more to the completion handler
        chain.proceedAsync(request: request,
                           completion: completion)
        return
    }
    
    
    chain.proceedAsync(
      request: request,
      completion: { httpResponse in
        guard let result = httpResponse.parsedResponse else {
          // This is in the wrong order - this needs to be parsed before we can check it.
          chain.handleErrorAsync(APQError.noParsedResponse,
                                 request: request,
                                 response: httpResponse)
          return
        }

        guard let errors = result.errors else {
          // No errors were returned so no retry is necessary, continue along.
          completion(httpResponse)
          return
        }
        
        let errorMessages = errors.compactMap { $0.message }
        guard errorMessages.contains("PersistedQueryNotFound") else {
          // The errors were not APQ errors, continue along.
          completion(httpResponse)
          return
        }
        
        guard !jsonRequest.isPersistedQueryRetry else {
          // We already retried this and it didn't work.
          chain.handleErrorAsync(APQError.persistedQueryRetryFailed(operationName: jsonRequest.operation.operationName),
                                 request: jsonRequest,
                                 response: httpResponse)
          return
        }
        
        // We need to retry this query with the full body.
        jsonRequest.isPersistedQueryRetry = true
        chain.retry(request: jsonRequest)
      })
  }
}
