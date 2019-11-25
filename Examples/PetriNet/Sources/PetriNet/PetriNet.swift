import SFDDKit
import Homomorphisms
import Kanna

typealias Place = String
typealias Transition = String
typealias Hom = Homomorphism<SFDD<Place>>
typealias DD = SFDD<Place>

let factory = Factory<Place>()
let homFactory = SFDDKit.HomomorphismFactory<Place>()

let id : Hom = homFactory.makeIdentity()

private let ns = ["pnml": "http://www.pnml.org/version-2009/grammar/pnml"]

struct PetriNet {

  init(
    places: Set<String>,
    transitions: Set<String>,
    pre: [Transition: [Place: Int]],
    post: [Transition: [Place: Int]],
    initialMarking: [Place: Int])
  {
    self.places = places
    self.transitions = transitions
    self.pre = pre
    self.post = post
    self.initialMarking = initialMarking
  }

  /// The set of places.
  let places: Set<String>
  /// The set of transitions.
  let transitions: Set<String>
  /// The preconditions matrix.
  let pre: [String: [String: Int]]
  /// The postconditions matrix.
  let post: [String: [String: Int]]
  /// The initial marking of the net.
  let initialMarking: [Place: Int]

  enum ParseError: Error {

    case invalidPNML(message: String)
    case invalidArc

  }

  /// Parses a Petri net from a PNML file.
  static func parse(pnmlPath: String) throws -> PetriNet {
    let xml = try String(contentsOfFile: pnmlPath, encoding: .utf8)
    let doc = try XML(xml: xml, encoding: .utf8)

    // We expect the PNML file to contain a single net, on a single page.
    let pages = doc.xpath("//pnml:net/pnml:page", namespaces: ns)
    guard pages.count == 1 else {
      throw ParseError.invalidPNML(message: "expected 1 <page> element, found \(pages.count)")
    }
    let page = pages[0]

    // Collect the places.
    let placeIdsWithInitialMarking = page.xpath("pnml:place", namespaces: ns)
      .map { el -> (id: String, initialMarking: Int) in
        let id = el.xpath("@id").first!.text!
        let m0 = el.xpath("pnml:initialMarking/pnml:text", namespaces: ns).first?.text ?? "0"
        return (id, Int(m0)!)
    }
    let initialMarking: [Place: Int] = Dictionary(uniqueKeysWithValues: placeIdsWithInitialMarking)

    // Collect the transitions.
    let transitionIds = page.xpath("pnml:transition", namespaces: ns)
      .map { el -> String in
        return el.xpath("@id").first!.text!
    }
    let transitions = Set(transitionIds)

    // Collect the pre/post-conditions.
    var pre: [Transition: [Place: Int]] = Dictionary(
      uniqueKeysWithValues: transitions.map({ ($0, [:]) }))
    var post = pre

    for arc in page.xpath("pnml:arc", namespaces: ns) {
      // Parse the source and target of the arc.
      let source = arc.xpath("@source").first!.text!
      let target = arc.xpath("@target").first!.text!

      // Parse the weight of the arc, if any.
      let weight = arc.xpath("pnml:inscription/pnml:text", namespaces: ns).first?.text ?? "1"

      if initialMarking[source] != nil {
        guard transitions.contains(target)
          else { throw ParseError.invalidArc }
        pre[target]![source] = Int(weight)!
      } else {
        guard initialMarking[target] != nil
          else { throw ParseError.invalidArc }
        post[source]![target] = Int(weight)
      }
    }

    return PetriNet(
      places: Set(initialMarking.keys),
      transitions: transitions,
      pre: pre,
      post: post,
      initialMarking: initialMarking)
  }

}

func makeTransitionHomomorphism(preconditions: [Place], postconditions: [Place]) -> Hom {
  let insert = homFactory.makeInsert(postconditions.sorted())
  let remove = homFactory.makeRemove(preconditions.sorted())
  let filter = homFactory.makeFilter(containing: preconditions.sorted())
  return homFactory.makeComposition([filter, remove, insert])
}
