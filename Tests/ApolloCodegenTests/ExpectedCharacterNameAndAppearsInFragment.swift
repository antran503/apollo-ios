import Foundation
import Apollo

public protocol CharacterNameAndAppearsIn: GraphQLFragment, Codable {
  var __typename: String { get }
  /// The name of the character
  var name: String { get }
  /// The movies this character appears in
  var appearsIn: [Episode] { get }
}

/// Default implementation
public extension CharacterNameAndAppearsIn {
  static var fragmentDefinition: String {
#"""
fragment CharacterNameAndAppearsIn on Character {
  __typename
  name
  appearsIn
}
"""#
  }
}
