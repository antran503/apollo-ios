import Foundation
#if !COCOAPODS
import ApolloCore
#endif

/// A chain that allows a single network request to be created and executed.
public class RequestChain: Cancellable {
  
  public enum ChainError: Error, LocalizedError {
    case invalidIndex(chain: RequestChain, index: Int)
    case noPostNetworkInterceptors
    
    public var errorDescription: String? {
      switch self {
      case .noPostNetworkInterceptors:
        return "No pre-network interceptors were provided to this chain. This is a developer error."
      case .invalidIndex(_, let index):
        return "`proceedAsync` was called for index \(index), which is out of bounds of the receiver for this chain. Double-check the order of your interceptors."
      }
    }
  }
  
  private let preNetworkInterceptors: [ApolloPreNetworkInterceptor]
  private let networkInterceptor: ApolloNetworkFetchInterceptor
  private let postNetworkInterceptors: [ApolloPostNetworkInterceptor]
  private var currentPreNetworkIndex: Int
  private var currentPostNetworkIndex: Int
  private var callbackQueue: DispatchQueue
  private var isCancelled = Atomic<Bool>(false)
  
  /// Checks the underlying value of `isCancelled`. Set up like this for better readability in `guard` statements
  public var isNotCancelled: Bool {
    !self.isCancelled.value
  }
  
  /// Something which allows additional error handling to occur when some kind of error has happened.
  public var additionalErrorHandler: ApolloErrorInterceptor?
  
  /// Creates a chain with the given interceptor array.
  ///
  /// - Parameters:
  ///   - interceptors: The array of interceptors to use.
  ///   - callbackQueue: The `DispatchQueue` to call back on when an error or result occurs. Defaults to `.main`.
  public init(preNetworkInterceptors: [ApolloPreNetworkInterceptor],
              networkInterceptor: ApolloNetworkFetchInterceptor,
              postNetworkInterceptors: [ApolloPostNetworkInterceptor],
              callbackQueue: DispatchQueue = .main) {
    
    self.currentPreNetworkIndex = 0
    self.preNetworkInterceptors = preNetworkInterceptors
    
    self.networkInterceptor = networkInterceptor
    
    self.currentPostNetworkIndex = 0
    self.postNetworkInterceptors = postNetworkInterceptors
    
    self.callbackQueue = callbackQueue
  }
  
  /// Kicks off the request from the beginning of the interceptor array.
  ///
  /// - Parameters:
  ///   - request: The request to send.
  ///   - completion: The completion closure to call when the request has completed.
  public func kickoff<Operation: GraphQLOperation>(
    request: HTTPRequest<Operation>,
    completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void) {
    assert(self.currentPreNetworkIndex == 0, "The pre-network interceptor index should be zero when calling this method")
    
    guard self.postNetworkInterceptors.apollo.isNotEmpty else {
      // There definitely need to be post-network interceptors to do some kind of parsing.
      handleErrorAsync(ChainError.noPostNetworkInterceptors,
                       request: request,
                       response: nil,
                       completion: completion)
      return
    }

    guard let firstInterceptor = self.preNetworkInterceptors.first else {
      // There aren't any pre-network interceptors, go directly to fetching from the network.
      self.networkInterceptor.fetchFromNetwork(chain: self,
                                               request: request,
                                               completion: completion)
      return
    }
    
    firstInterceptor.prepareRequest(chain: self,
                                    request: request,
                                    completion: completion)
  }
  
  /// Proceeds to the next pre-network interceptor in the array.
  ///
  /// - Parameters:
  ///   - request: The in-progress request object
  ///   - completion: The completion closure to call when data has been processed and should be returned to the UI.
  public func proceedWithPreparing<Operation: GraphQLOperation>(
    request: HTTPRequest<Operation>,
    completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void) {
  
    guard self.isNotCancelled else {
      // Do not proceed, this chain has been cancelled.
      return
    }
    
    let nextIndex = self.currentPreNetworkIndex + 1
    if self.preNetworkInterceptors.indices.contains(nextIndex) {
      self.currentPreNetworkIndex = nextIndex
      let interceptor = self.preNetworkInterceptors[self.currentPreNetworkIndex]
      
      interceptor.prepareRequest(chain: self,
                                 request: request,
                                 completion: completion)
    } else {
      // We've gotten to the end of the pre-network interceptors, call the network interceptor
      self.networkInterceptor.fetchFromNetwork(chain: self,
                                               request: request,
                                               completion: completion)
    }
  }
  
  public func handleRawNetworkResponse<Operation: GraphQLOperation>(request: HTTPRequest<Operation>,
                                                                    rawResponse: Result<(Data, HTTPURLResponse), Error>,
                                                                    completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void) {
    guard self.isNotCancelled else {
      // Do not proceed, this chain has been cancelled.
      return
    }
    
    switch rawResponse {
    case .failure(let error):
      self.handleErrorAsync(error,
                            request: request,
                            response: nil,
                            completion: completion)
    case .success(let (data, httpResponse)):
      let response = HTTPResponse<Operation>(response: httpResponse,
                                             rawData: data,
                                             parsedResponse: nil)
      
      /// This force unwrap shouldn't die because we're validating that there's at least one interceptor in `kickoff`.
      let firstPostInterceptor = self.postNetworkInterceptors.first!
      
      firstPostInterceptor.handleResponse(chain: self,
                                          request: request,
                                          response: response,
                                          completion: completion)
    }
  }
  
  public func proceedWithHandlingResponse<Operation: GraphQLOperation>(
    request: HTTPRequest<Operation>,
    response: HTTPResponse<Operation>,
    completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void) {
  
    guard self.isNotCancelled else {
      // Do not proceed, this chain has been cancelled.
      return
    }
    
    let nextIndex = self.currentPostNetworkIndex + 1
    if self.postNetworkInterceptors.indices.contains(nextIndex) {
      self.currentPostNetworkIndex = nextIndex
      let interceptor = self.postNetworkInterceptors[self.currentPostNetworkIndex]
      
      interceptor.handleResponse(chain: self,
                                 request: request,
                                 response: response,
                                 completion: completion)
    } else {
      if let result = response.parsedResponse {
        // We got to the end of the chain with a parsed response. Yay! Return it.
        self.returnValueAsync(for: request,
                              value: result,
                              completion: completion)
      } else {
        // We got to the end of the chain and no parsed response is there, there needs to be more processing.
        self.handleErrorAsync(ChainError.invalidIndex(chain: self, index: nextIndex),
                              request: request,
                              response: response,
                              completion: completion)
      }
    }
  }
  
  /// Cancels the entire chain of interceptors, along with any interceptors that conform to `Cancellable`
  public func cancel() {
    self.isCancelled.mutate { $0 = true }
    
    var cancellables = self.preNetworkInterceptors.compactMap { $0 as? Cancellable }
    cancellables.append(contentsOf: self.postNetworkInterceptors.compactMap { $0 as? Cancellable })
    cancellables.append(self.networkInterceptor)
    
    for cancellable in cancellables {
      cancellable.cancel()
    }
  }
  
  /// Restarts the request starting from the first interceptor.
  ///
  /// - Parameters:
  ///   - request: The request to retry
  ///   - completion: The completion closure to call when the request has completed.
  public func retry<Operation: GraphQLOperation>(
    request: HTTPRequest<Operation>,
    completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void) {
    
    guard self.isNotCancelled else {
      // Don't retry something that's been cancelled.
      return
    }
    
    self.currentPreNetworkIndex = 0
    self.currentPostNetworkIndex = 0
    self.kickoff(request: request, completion: completion)
  }
  
  /// Handles the error by returning it on the appropriate queue, or by applying an additional error interceptor if one has been provided.
  ///
  /// - Parameters:
  ///   - error: The error to handle
  ///   - request: The request, as far as it has been constructed.
  ///   - response: The response, as far as it has been constructed.
  ///   - completion: The completion closure to call when work is complete.
  public func handleErrorAsync<Operation: GraphQLOperation>(
    _ error: Error,
    request: HTTPRequest<Operation>,
    response: HTTPResponse<Operation>?,
    completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void) {
    guard self.isNotCancelled else {
      return
    }

    guard let additionalHandler = self.additionalErrorHandler else {
      self.callbackQueue.async {
        completion(.failure(error))
      }
      return
    }

    additionalHandler.handleErrorAsync(error: error, chain: self, request: request, response: response) { [weak self] result in
      self?.callbackQueue.async {
        completion(result)
      }
    }
  }
  
  /// Handles a resulting value by returning it on the appropriate queue.
  ///
  /// - Parameters:
  ///   - request: The request, as far as it has been constructed.
  ///   - value: The value to be returned
  ///   - completion: The completion closure to call when work is complete.
  public func returnValueAsync<Operation: GraphQLOperation>(
    for request: HTTPRequest<Operation>,
    value: GraphQLResult<Operation.Data>,
    completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void) {
   
    guard self.isNotCancelled else {
      return
    }
    
    self.callbackQueue.async {
      completion(.success(value))
    }
  }
}
