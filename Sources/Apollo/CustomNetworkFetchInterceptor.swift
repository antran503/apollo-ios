import Foundation

/// Protocol to allow non-`URLSessionClient` network clients to easily execute requests.
public protocol NetworkRequester {
  
  /// Takes a created `URLRequest` and executes it using a custom fetcher.
  ///
  /// - Parameters:
  ///   - request: The request to execute.
  ///   - completion: The completion closure to execute when the request is complete. On success, should return a tuple of non-nil `Data` (nil `Data` would be an error) and an `HTTPURLResponse`.
  func executeRequest(_ request: URLRequest, completion: @escaping  (Result<(Data, HTTPURLResponse), Error>) -> Void) -> Cancellable?
}

public class CustomNetworkFetchInterceptor: ApolloNetworkFetchInterceptor {
  
  let requester: NetworkRequester
  var currentTask: Cancellable?
  
  public init(requester: NetworkRequester) {
    self.requester = requester
  }
  
  public func fetchFromNetwork<Operation: GraphQLOperation>(
    chain: RequestChain,
    request: HTTPRequest<Operation>,
    completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void) {
    
    let urlRequest: URLRequest
    do {
      urlRequest = try request.toURLRequest()
    } catch {
      chain.handleErrorAsync(error,
                             request: request,
                             response: nil,
                             completion: completion)
      return
    }
    
    self.currentTask = self.requester.executeRequest(urlRequest) { [weak self] result in
      guard let self = self else {
        return
      }
      
      defer {
        self.currentTask = nil
      }
      
      chain.handleRawNetworkResponse(request: request,
                                     rawResponse: result,
                                     completion: completion)
    }
  }
  
  public func cancel() {
    self.currentTask?.cancel()
  }
}
