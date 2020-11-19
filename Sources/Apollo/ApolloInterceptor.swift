/// A protocol to set up a chainable unit of networking work.
public protocol ApolloPreNetworkInterceptor: class {
  
  /// Called when this interceptor should do its work.
  ///
  /// - Parameters:
  ///   - chain: The chain the interceptor is a part of.
  ///   - request: The request, as far as it has been constructed
  ///   - response: [optional] The response, if received
  ///   - completion: The completion block to fire when data needs to be returned to the UI.
  func prepareRequest<Operation: GraphQLOperation>(
    chain: RequestChain,
    request: HTTPRequest<Operation>,
    completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void)
}

public protocol ApolloNetworkFetchInterceptor: Cancellable {
  
  func fetchFromNetwork<Operation: GraphQLOperation>(
    chain: RequestChain,
    request: HTTPRequest<Operation>,
    completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void)
}

public protocol ApolloPostNetworkInterceptor: class {
  
  func handleResponse<Operation: GraphQLOperation>(
    chain: RequestChain,
    request: HTTPRequest<Operation>,
    response: HTTPResponse<Operation>,
    completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void)
}
