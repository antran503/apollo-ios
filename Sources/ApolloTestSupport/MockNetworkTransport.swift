@testable import Apollo

public final class MockNetworkTransport: RequestChainNetworkTransport {
  public init(server: MockGraphQLServer, store: ApolloStore) {
    super.init(interceptorProvider: TestInterceptorProvider(store: store, server: server),
               endpointURL: TestURL.mockServer.url)
  }
  
  class TestInterceptorProvider: LegacyInterceptorProvider {
    let server: MockGraphQLServer
    
    init(store: ApolloStore,
         server: MockGraphQLServer) {
      self.server = server
      super.init(store: store)
    }
    
    override func networkInterceptor<Operation: GraphQLOperation>(for operation: Operation) -> ApolloNetworkFetchInterceptor {
      MockGraphQLServerInterceptor(server: server)
    }
  }
}

private final class MockTask: Cancellable {
  func cancel() {
    // no-op
  }
}

private class MockGraphQLServerInterceptor: ApolloNetworkFetchInterceptor {
  
  let server: MockGraphQLServer
  
  init(server: MockGraphQLServer) {
    self.server = server
  }
  
  func fetchFromNetwork<Operation: GraphQLOperation>(
    chain: RequestChain,
    request: HTTPRequest<Operation>,
    completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void) {
    
    self.server.serve(request: request) { result in
      let httpResponse = HTTPURLResponse(url: TestURL.mockServer.url,
                                         statusCode: 200,
                                         httpVersion: nil,
                                         headerFields: nil)!
      
      switch result {
      case .failure(let error):
        chain.handleErrorAsync(error,
                               request: request,
                               response: nil,
                               completion: completion)
      case .success(let body):
        let data = try! JSONSerializationFormat.serialize(value: body)
        chain.handleRawNetworkResponse(request: request,
                                       rawResponse: .success((data, httpResponse)),
                                       completion: completion)
      }
    }
  }
  
  func cancel() {
    // no-op, required protocol conformance
  }
}
