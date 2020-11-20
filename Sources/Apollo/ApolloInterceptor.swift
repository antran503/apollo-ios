/// A protocol to set up a chainable unit of networking work.
public protocol ApolloInterceptor: class {
  
  /// Called when this interceptor should do its work.
  ///
  /// - Parameters:
  ///   - chain: The chain the interceptor is a part of.
  ///   - request: The request, as far as it has been constructed
  ///   - response: [optional] The response, if received
  ///   - completion: The completion block to fire when data needs to be returned to the UI.
  func interceptAsync<Operation: GraphQLOperation>(
    chain: RequestChain<Operation>,
    request: HTTPRequest<Operation>,
    completion: @escaping (HTTPResponse<Operation>) -> Void)
}

/// Response in completion instead of passing everything through - then you can handle working with the response
