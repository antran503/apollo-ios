import Foundation

public class CodableParsingInterceptor<FlexDecoder: FlexibleDecoder>: ApolloPostNetworkInterceptor {

  let decoder: FlexDecoder
  
  var isCancelled: Bool = false
  
  public init(decoder: FlexDecoder) {
    self.decoder = decoder
  }
  
  public func handleResponse<Operation: GraphQLOperation>(
    chain: RequestChain,
    request: HTTPRequest<Operation>,
    response: HTTPResponse<Operation>,
    completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void) {

    guard !self.isCancelled else {
      return
    }

    do {
      let parsedData = try GraphQLResult<Operation.Data>(from: response.rawData, decoder: self.decoder)
      response.parsedResponse = parsedData
      chain.proceedWithHandlingResponse(request: request,
                                        response: response,
                                        completion: completion)
    } catch {
      chain.handleErrorAsync(error,
                             request: request,
                             response: response,
                             completion: completion)
    }
  }
}
