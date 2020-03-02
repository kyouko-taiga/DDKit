import DDKit

// MARK: Petri net definition

enum P: Int, Place, Comparable, Hashable, CustomStringConvertible {

  case p0 = 0, p1, p2, p3, p4, p5, p6

  var description: String { "p\(rawValue)" }

  static func < (lhs: P, rhs: P) -> Bool {
    lhs.rawValue < rhs.rawValue
  }

}

enum T: Int, Transition, Comparable, Hashable, CustomStringConvertible {

  case t0 = 0, t1, t2, t3, t4, t5, t6, t7, t8, t9

  var description: String { "t\(rawValue)" }

  static func < (lhs: T, rhs: T) -> Bool {
    lhs.rawValue < rhs.rawValue
  }

}

let model = PetriNet<P, T>(
  // t0
  .pre(from: .p0, to: .t0),
  .post(from: .t0, to: .p1, labeled: 2),

  // t1
  .pre(from: .p1, to: .t1),
  .post(from: .t1, to: .p3),

  // t2
  .pre(from: .p0, to: .t2),
  .post(from: .t2, to: .p2, labeled: 2),

  // t3
  .pre(from: .p2, to: .t3),
  .post(from: .t3, to: .p3),

  // t4
  .pre(from: .p3, to: .t4, labeled: 4),
  .post(from: .t4, to: .p0, labeled: 2),

  // t5
  .pre(from: .p3, to: .t5),
  .post(from: .t5, to: .p4, labeled: 2),

  // t6
  .pre(from: .p4, to: .t6),
  .post(from: .t6, to: .p6),

  // t7
  .pre(from: .p3, to: .t7),
  .post(from: .t7, to: .p4, labeled: 2),

  // t8
  .pre(from: .p5, to: .t8),
  .post(from: .t8, to: .p6),

  // t9
  .pre(from: .p6, to: .t9, labeled: 8),
  .post(from: .t9, to: .p3, labeled: 4))

// MARK: MFDD Translation

final class TransitionMorphism<PlaceType>: Morphism, MFDDSaturable
  where PlaceType: Comparable & Hashable
{

  typealias DD = MFDD<PlaceType, Int>

  /// One of the transition's precondition.
  let precondition: (place: PlaceType, tokens: Int)

  /// One of the transition's postcondition.
  let postcondition: (place: PlaceType, tokens: Int)

  /// The next morphism to apply once the first precondition has been checked.
  let next: TransitionMorphism<PlaceType>?

  /// The factory that creates the nodes handled by this morphism.
  unowned let factory: MFDDFactory<PlaceType, Int>

  /// The morphism's cache.
  private var cache: [MFDD<PlaceType, Int>.Pointer: MFDD<PlaceType, Int>.Pointer] = [:]

  var lowestRelevantKey: PlaceType { precondition.place }

  init<S>(_ pre: S, _ post: S, factory: MFDDFactory<PlaceType, Int>)
    where S: Sequence, S.Element == (key: PlaceType, value: Int)
  {
    let preconditions = pre.sorted(by: { a, b in a.0 < b.0 })
    let postconditions = post.sorted(by: { a, b in a.0 < b.0 })
    assert(preconditions[0].key == postconditions[0].key)

    self.precondition = (place: preconditions[0].key, tokens: preconditions[0].value)
    self.postcondition = (place: postconditions[0].key, tokens: postconditions[0].value)
    self.factory = factory

    if preconditions.count > 1 {
      self.next = factory.morphisms.uniquify(
        TransitionMorphism(preconditions[1...], postconditions[1...], factory: factory))
    } else {
      self.next = nil
    }
  }

  func apply(on pointer: MFDD<PlaceType, Int>.Pointer) -> MFDD<PlaceType, Int>.Pointer {
    // Check for trivial cases.
    guard !factory.isTerminal(pointer)
      else { return factory.zero.pointer }

    // Query the cache.
    if let result = cache[pointer] {
      return result
    }

    let result: MFDD<PlaceType, Int>.Pointer
    if pointer.pointee.key < precondition.place {
      result = factory.node(
        key: pointer.pointee.key,
        take: pointer.pointee.take.mapValues(apply(on:)),
        skip: apply(on: pointer.pointee.skip))
    } else if pointer.pointee.key == precondition.place {
      var take: [Int: MFDD<PlaceType, Int>.Pointer] = [:]
      for (tokens, child) in pointer.pointee.take where tokens >= precondition.tokens {
        take[tokens - precondition.tokens + postcondition.tokens] = next?.apply(on: child) ?? child
      }

      result = factory.node(
        key: pointer.pointee.key,
        take: take,
        skip: factory.zero.pointer)
    } else {
      result = factory.zero.pointer
    }

    cache[pointer] = result
    return result
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(precondition.place)
    hasher.combine(precondition.tokens)
    hasher.combine(next)
  }

  static func == (lhs: TransitionMorphism, rhs: TransitionMorphism) -> Bool {
    lhs === rhs
  }

}

extension PetriNet where PlaceType: Comparable & Hashable {

  func encode(transition: TransitionType, factory: MFDDFactory<PlaceType, Int>)
    -> TransitionMorphism<PlaceType>?
  {
    var pre = input[transition] ?? [:]
    var post = output[transition] ?? [:]

    for place in PlaceType.allCases {
      if (pre[place] == nil) && (post[place] != nil) {
        pre[place] = 0
      }
      if (post[place] == nil) && (pre[place] != nil) {
        post[place] = 0
      }
    }
    assert(Set(pre.keys) == Set(post.keys))

    guard pre.count > 0
      else { return nil }
    return factory.morphisms.uniquify(TransitionMorphism<PlaceType>(pre, post, factory: factory))
  }

  func encodeAllTransitions(factory: MFDDFactory<PlaceType, Int>)
    -> AnyMorphism<MFDD<PlaceType, Int>>
  {
    let morphisms = TransitionType.allCases
      .compactMap({ transition in encode(transition: transition, factory: factory) })
      .sorted(by: { a, b in a.lowestRelevantKey > b.lowestRelevantKey })

    let M = factory.morphisms
    switch morphisms.count {
    case 0:
      return AnyMorphism(M.identity)
    case 1:
      return AnyMorphism(M.fixedPoint(of: M.union(morphisms[0], M.identity)))
    default:
      var result = AnyMorphism(M.saturate(morphisms[0]))
      for morphism in morphisms[1...] {
        result = AnyMorphism(M.saturate(M.union(morphism, result), to: morphism.lowestRelevantKey))
      }
      return AnyMorphism(M.fixedPoint(of: M.union(result, M.identity)))
    }
  }

}

// MARK: State space construction

let N = 24
let C = 1 << 16

//do {
//  let stopwatch = Stopwatch()
//  guard let graph = model.markingGraph(from: Marking(partial: [.p0: N]))
//    else { fatalError("unbounded model") }
//  print("marking graph computed in \(stopwatch.elapsed.humanFormat)")
//  print("- \(graph.count) states")
//}
//
//print()

do {
  let factory = MFDDFactory<P, Int>(bucketCapacity: C)

  let ts = model.encodeAllTransitions(factory: factory)
  let m0 = factory.encode(family: [Marking<P, Int>(partial: [.p0: N])])

  let stopwatch = Stopwatch()
  let ss = ts.apply(on: m0)
  print("State space computed in \(stopwatch.elapsed.humanFormat)")
  print("- \(ss.count) states")

  let cc = factory.createdCount
  let percentage = (Double(cc) / Double(C) * 10000.0).rounded() / 100.0
  print("- \(cc) nodes created (\(percentage)% of a single bucket capacity)")
}
