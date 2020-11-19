import Foundation
#if !COCOAPODS
import ApolloCore
#endif

/// An interceptor which actually fetches data from the network.
public class NetworkFetchInterceptor: ApolloNetworkFetchInterceptor {
  let client: URLSessionClient
  private var currentTask: Atomic<URLSessionTask?> = Atomic(nil)
  
  /// Designated initializer.
  ///
  /// - Parameter client: The `URLSessionClient` to use to fetch data
  public init(client: URLSessionClient) {
    self.client = client
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
    
    let task = self.client.sendRequest(urlRequest) { [weak self] result in
      guard let self = self else {
        return
      }
      
      defer {
        self.currentTask.mutate { $0 = nil }
      }
      
      chain.handleRawNetworkResponse(request: request,
                                     rawResponse: result,
                                     completion: completion)
    }
    
    self.currentTask.mutate { $0 = task }
  }
  
  public func cancel() {
    guard let task = self.currentTask.value else {
      return
    }
    
    task.cancel()
  }
}
