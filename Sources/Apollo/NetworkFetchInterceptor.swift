import Foundation
#if !COCOAPODS
import ApolloCore
#endif

/// An interceptor which actually fetches data from the network.
public class NetworkFetchInterceptor: ApolloInterceptor, Cancellable {
  let client: URLSessionClient
  private var currentTask: Atomic<URLSessionTask?> = Atomic(nil)
  
  /// Designated initializer.
  ///
  /// - Parameter client: The `URLSessionClient` to use to fetch data
  public init(client: URLSessionClient) {
    self.client = client
  }
  
  public func interceptAsync<Operation: GraphQLOperation>(
    chain: RequestChain<Operation>,
    request: HTTPRequest<Operation>,
    completion: @escaping (HTTPResponse<Operation>) -> Void) {
      
    let urlRequest: URLRequest
    do {
      urlRequest = try request.toURLRequest()
    } catch {
      chain.handleErrorAsync(error,
                             request: request,
                             response: nil)
      return
    }
    
    let task = self.client.sendRequest(urlRequest) { [weak self] result in
      guard let self = self else {
        return
      }
      
      defer {
        self.currentTask.mutate { $0 = nil }
      }
      
      guard chain.isNotCancelled else {
        return
      }
      
      switch result {
      case .failure(let error):
        chain.handleErrorAsync(error,
                               request: request,
                               response: nil)
      case .success(let (data, httpResponse)):
        let response = HTTPResponse<Operation>(response: httpResponse,
                                               rawData: data,
                                               parsedResponse: nil)
        completion(response)
      }
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
