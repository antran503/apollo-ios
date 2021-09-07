public protocol AnySelectionSet: ResponseObject {
  static var selections: [Selection] { get }
}

public enum ParentType {
  case Object(Object.Type)
  case Interface(Interface.Type)
  case Union(UnionType.Type)
}

public protocol SelectionSet: ResponseObject {

  associatedtype Schema: SchemaTypeFactory

  /// The GraphQL type for the `SelectionSet`.
  ///
  /// This may be a concrete type (`Object`) or an abstract type (`Interface`, or `Union`).
  static var __parentType: ParentType { get }
}

extension SelectionSet {

  var __objectType: Object.Type? { Schema.objectType(forTypename: __typename) }

  var __typename: String { data["__typename"] }

  /// Verifies if a `SelectionSet` may be converted to a different `SelectionSet` and performs
  /// the conversion.
  ///
  /// - Warning: This function is not supported for use outside of generated call sites.
  /// Generated call sites are guaranteed by the GraphQL compiler to be safe.
  /// Unsupported usage may result in unintended consequences including crashes.
  func _asType<T: SelectionSet>() -> T? where T.Schema == Schema {
    guard let __objectType = __objectType else { return nil }

    switch T.__parentType {
    case .Object(let type):
      guard __objectType == type else { return nil }

    case .Interface(let interface):
      guard __objectType.__metadata.implements(interface) else { return nil }

    case .Union(let union):
      guard union.possibleTypes.contains(where: { $0 == __objectType }) else { return nil }
    }

    return T.init(data: data)
  }
}

public protocol ResponseObject {
  var data: ResponseDict { get }

  init(data: ResponseDict)
}

extension ResponseObject {

  /// Converts a `SelectionSet` to a `Fragment` given a generic fragment type.
  ///
  /// - Warning: This function is not supported for use outside of generated call sites.
  /// Generated call sites are guaranteed by the GraphQL compiler to be safe.
  /// Unsupported usage may result in unintended consequences including crashes.
  func _toFragment<T: Fragment>() -> T {
    return T.init(data: data)
  }
}
