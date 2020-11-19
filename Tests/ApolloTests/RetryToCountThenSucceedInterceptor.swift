//
//  RetryToCountThenSucceedInterceptor.swift
//  ApolloTests
//
//  Created by Ellen Shapiro on 8/19/20.
//  Copyright © 2020 Apollo GraphQL. All rights reserved.
//

import Foundation
import Apollo

class RetryToCountThenSucceedInterceptor: ApolloPreNetworkInterceptor {
  let timesToCallRetry: Int
  var timesRetryHasBeenCalled = 0
  
  init(timesToCallRetry: Int) {
    self.timesToCallRetry = timesToCallRetry
  }
  
  func prepareRequest<Operation: GraphQLOperation>(
    chain: RequestChain,
    request: HTTPRequest<Operation>,
    completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void) {
    
    if self.timesRetryHasBeenCalled < self.timesToCallRetry {
      self.timesRetryHasBeenCalled += 1
      chain.retry(request: request,
                  completion: completion)
    } else {
      chain.proceedWithPreparing(request: request,
                                 completion: completion)
    }
  }
}
