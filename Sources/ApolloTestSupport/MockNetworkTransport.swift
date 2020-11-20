@testable import Apollo

public final class MockNetworkTransport: RequestChainNetworkTransport {
  public init(server: MockGraphQLServer, store: ApolloStore) {
    super.init(interceptorProvider: TestInterceptorProvider(store: store, server: server),
               endpointURL: TestURL.mockServer.url)
  }
  
  struct TestInterceptorProvider: InterceptorProvider {
    let store: ApolloStore
    let server: MockGraphQLServer
    
    func interceptors<Operation>(for operation: Operation) -> [ApolloInterceptor] where Operation: GraphQLOperation {
      return [
        MaxRetryInterceptor(),
        LegacyCacheReadInterceptor(store: self.store),
        
        LegacyCacheWriteInterceptor(store: self.store),
        LegacyParsingInterceptor(cacheKeyForObject: self.store.cacheKeyForObject),
        AutomaticPersistedQueryInterceptor(),
        ResponseCodeInterceptor(),

        MockGraphQLServerInterceptor(server: server),
      ]
    }
  }
}

private final class MockTask: Cancellable {
  func cancel() {
    // no-op
  }
}

private class MockGraphQLServerInterceptor: ApolloInterceptor {
  let server: MockGraphQLServer
  
  init(server: MockGraphQLServer) {
    self.server = server
  }
  
  public func interceptAsync<Operation: GraphQLOperation>(
    chain: RequestChain<Operation>,
    request: HTTPRequest<Operation>,
    completion: @escaping (HTTPResponse<Operation>) -> Void) {
    
    server.serve(request: request) { result in
      let httpResponse = HTTPURLResponse(url: TestURL.mockServer.url,
                                         statusCode: 200,
                                         httpVersion: nil,
                                         headerFields: nil)!
      
      switch result {
      case .failure(let error):
        chain.handleErrorAsync(error,
                               request: request,
                               response: nil)
      case .success(let body):
        let data = try! JSONSerializationFormat.serialize(value: body)
        let response = HTTPResponse<Operation>(response: httpResponse,
                                               rawData: data,
                                               parsedResponse: nil)
        completion(response)
      }
    }
  }
}
