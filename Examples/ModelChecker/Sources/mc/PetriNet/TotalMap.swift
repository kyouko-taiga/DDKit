/// A total map.
///
/// A total map is analoguous to a dictionary for which all keys are guaranteed to be assigned to
/// a value. In more formal terms, it corresponds to a total function. You may prefer a total map
/// to a function for faster lookup, when values can be memoized.
public struct TotalMap<Key, Value> where Key: CaseIterable & Hashable {

  /// The dictionary that backs this total map.
  fileprivate var storage: [Key: Value]

  /// Initializes a total map with a dictionary.
  ///
  /// - Parameters:
  ///   - mapping: A dictionary containing the keys and values of this total map.
  ///
  /// - Warning:
  ///   The given dictionary must be defined for all keys of the total map's domain, otherwise an
  ///   error will be triggered at runtime.
  public init(_ mapping: [Key: Value]) {
    precondition(Key.allCases.allSatisfy { mapping[$0] != nil }, "incomplete mapping")
    self.storage = mapping
  }

  /// Initializes a total map with a function.
  ///
  /// - Parameters:
  ///   - mapping: The function mapping the keys of this total map to their respective values.
  public init(_ mapping: (Key) throws -> Value) rethrows {
    self.storage = Dictionary(
      uniqueKeysWithValues: try Key.allCases.map { ($0, try mapping($0)) })
  }

  /// Initializes a total map with a dictionary, using default values for unassigned keys.
  ///
  /// - Parameters:
  ///   - mapping: A dictionary containing the keys and values of this total map.
  ///   - defaultValue: The default value to use when for unassigned keys in `mapping`.
  public init(partial mapping: [Key: Value], defaultValue: Value) {
    self.init { key in mapping[key] ?? defaultValue }
  }

  /// Accesses the value associated with the given key for reading and writing.
  ///
  /// - Parameters:
  ///   - key: The key to find in the total map.
  /// - Returns:
  ///   The value associated with `key`.
  public subscript(key: Key) -> Value {
    get { return storage[key]! }
    set { storage[key] = newValue }
  }

  /// Returns a new total map with the values transformed by the given closure.
  ///
  /// - Parameters:
  ///   - transform: A closure that transofmrs a value.
  /// - Returns:
  ///   A total map with the values transformed.
  public func mapValues<T>(_ transform: (Value) throws -> T) rethrows -> TotalMap<Key, T> {
    return try TotalMap<Key, T> { key in try transform(storage[key]!) }
  }

  /// A collection containing just the keys of the total map.
  public var keys: Key.AllCases {
    return Key.allCases
  }

  /// A collection containing just the values of the total map.
  public var values: [Value] {
    return Key.allCases.map { key in storage[key]! }
  }

}

extension TotalMap: ExpressibleByDictionaryLiteral {

  public init(dictionaryLiteral elements: (Key, Value)...) {
    self.storage = Dictionary(uniqueKeysWithValues: elements)
    precondition(Key.allCases.allSatisfy { self.storage[$0] != nil }, "incomplete mapping")
  }

}

extension TotalMap: Equatable where Value: Equatable {

}

extension TotalMap: Hashable where Value: Hashable {

}

extension TotalMap: Collection {

  public typealias Index = Key.AllCases.Index

  public var startIndex: Key.AllCases.Index {
    return Key.allCases.startIndex
  }

  public var endIndex: Key.AllCases.Index {
    return Key.allCases.endIndex
  }

  public func index(after i: Key.AllCases.Index) -> Key.AllCases.Index {
    return Key.allCases.index(after: i)
  }

  public subscript(i: Key.AllCases.Index) -> (key: Key, value: Value) {
    let key = Key.allCases[i]
    return (key: key, value: storage[key]!)
  }

}

extension TotalMap: CustomStringConvertible {

  public var description: String {
    return String(describing: storage)
  }

}
