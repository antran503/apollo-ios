import Foundation
import Apollo

public protocol DroidDetails: GraphQLFragment, Codable {
  var __typename: CharacterType { get }
  /// What others call this droid
  var name: String { get }
  /// This droid's primary function
  var primaryFunction: String { get }
}

/// Default implementation
public extension DroidDetails {
  static var fragmentDefinition: String {
#"""
fragment DroidDetails on Droid {
  __typename
  name
  primaryFunction
}
"""#
  }
}
