//
//  CancellationHandlingInterceptor.swift
//  ApolloTests
//
//  Created by Ellen Shapiro on 9/17/20.
//  Copyright © 2020 Apollo GraphQL. All rights reserved.
//

import Foundation
import Apollo

class CancellationHandlingInterceptor: ApolloInterceptor, Cancellable {
  private(set) var hasBeenCancelled = false
  
  func interceptAsync<Operation: GraphQLOperation>(
    chain: RequestChain<Operation>,
    request: HTTPRequest<Operation>,
    completion: @escaping (HTTPResponse<Operation>) -> Void) {
    
    guard !self.hasBeenCancelled else {
      return
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      chain.proceedAsync(request: request,
                         completion: completion)
    }
  }
  
  func cancel() {
    self.hasBeenCancelled = true
  }
}
