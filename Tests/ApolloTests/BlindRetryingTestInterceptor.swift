//
//  BlindRetryingTestInterceptor.swift
//  ApolloTests
//
//  Created by Ellen Shapiro on 8/19/20.
//  Copyright © 2020 Apollo GraphQL. All rights reserved.
//

import Foundation
import Apollo

// An interceptor which blindly retries every time it receives a request. 
class BlindRetryingTestInterceptor: ApolloInterceptor {
  var hitCount = 0
  private(set) var hasBeenCancelled = false

  func interceptAsync<Operation: GraphQLOperation>(
    chain: RequestChain<Operation>,
    request: HTTPRequest<Operation>,
    completion: @escaping (HTTPResponse<Operation>) -> Void) {

    self.hitCount += 1
    chain.retry(request: request)
  }
  
  // Purposely not adhering to `Cancellable` here to make sure non `Cancellable` interceptors don't have this called.
  func cancel() {
    self.hasBeenCancelled = true
  }
}
