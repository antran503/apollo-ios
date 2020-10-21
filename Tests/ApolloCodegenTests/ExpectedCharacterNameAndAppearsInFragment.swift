import Foundation
import Apollo

public protocol CharacterNameAndAppearsIn: GraphQLFragment, Codable {
  var __typename: CharacterType { get }
  var name: String { get }
  var appearsIn: [Episode] { get }
}

// MARK: - Default implementation

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
