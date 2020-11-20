//
//  RetryToCountThenSucceedInterceptor.swift
//  ApolloTests
//
//  Created by Ellen Shapiro on 8/19/20.
//  Copyright © 2020 Apollo GraphQL. All rights reserved.
//

import Foundation
import Apollo

class RetryToCountThenSucceedInterceptor: ApolloInterceptor {
  let timesToCallRetry: Int
  var timesRetryHasBeenCalled = 0
  
  init(timesToCallRetry: Int) {
    self.timesToCallRetry = timesToCallRetry
  }
  
  func interceptAsync<Operation: GraphQLOperation>(
    chain: RequestChain<Operation>,
    request: HTTPRequest<Operation>,
    completion: @escaping (HTTPResponse<Operation>) -> Void) {
    if self.timesRetryHasBeenCalled < self.timesToCallRetry {
      self.timesRetryHasBeenCalled += 1
      chain.retry(request: request)
    } else {
      chain.proceedAsync(request: request,
                         completion: completion)
    }
  }
}
