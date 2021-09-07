/// A structure that wraps the underlying data dictionary used by `SelectionSet`s.
public struct ResponseDict {

  let data: [String: Any]

  public subscript<T: ScalarType>(_ key: String) -> T {
    data[key] as! T
  }

  public subscript<T: ScalarType>(_ key: String) -> T? {
    data[key] as? T
  }

  public subscript<T: SelectionSet>(_ key: String) -> T {
    let objectData = data[key] as! [String: Any]
    return T.init(data: ResponseDict(data: objectData))
  }

  public subscript<T: SelectionSet>(_ key: String) -> T? {
    guard let objectData = data[key] as? [String: Any] else { return nil }
    return T.init(data: ResponseDict(data: objectData))
  }

  public subscript<T: SelectionSet>(_ key: String) -> [T] {
    let objectData = data[key] as! [[String: Any]]
    return objectData.map { T.init(data: ResponseDict(data: $0)) }
  }

  public subscript<T>(_ key: String) -> GraphQLEnum<T> {
    let objectData = data[key] as! String
    return GraphQLEnum(rawValue: objectData)
  }

  public subscript<T>(_ key: String) -> GraphQLEnum<T>? {
    guard let objectData = data[key] as? String else { return nil }
    return GraphQLEnum(rawValue: objectData)
  }
}
