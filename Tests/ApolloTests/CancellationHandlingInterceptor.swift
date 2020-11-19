//
//  CancellationHandlingInterceptor.swift
//  ApolloTests
//
//  Created by Ellen Shapiro on 9/17/20.
//  Copyright © 2020 Apollo GraphQL. All rights reserved.
//

import Foundation
import Apollo

class CancellationHandlingInterceptor: ApolloPreNetworkInterceptor, Cancellable {
  private(set) var hasBeenCancelled = false
  
  
  func prepareRequest<Operation: GraphQLOperation>(
    chain: RequestChain,
    request: HTTPRequest<Operation>,
    completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void) {
    
    guard !self.hasBeenCancelled else {
      return
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      chain.proceedWithPreparing(request: request,
                                 completion: completion)
    }
  }
  
  func cancel() {
    self.hasBeenCancelled = true
  }
}
