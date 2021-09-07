public protocol ScalarType: Cacheable {}

extension String: ScalarType {}
extension Int: ScalarType {}
extension Bool: ScalarType {}
extension Float: ScalarType {}
extension Double: ScalarType {}

extension ScalarType {
  public static func value(with cacheData: Any, in transaction: CacheTransaction) throws -> Self {
    return cacheData as! Self
  }
}

public protocol CustomScalarType: Cacheable {
  init(scalarData: Any) throws
  var jsonValue: Any { get }
}

extension CustomScalarType {
  public static func value(with cacheData: Any, in: CacheTransaction) throws -> Self {
    try Self.init(scalarData: cacheData)
  }
}
