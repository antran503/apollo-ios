public protocol SchemaTypeFactory {
  static func objectType(forTypename __typename: String) -> Object.Type?
}
