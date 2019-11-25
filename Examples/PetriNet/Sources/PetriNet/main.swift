import SFDDKit
import Homomorphisms

guard CommandLine.argc > 2 else {
  fatalError("missing arguments ('--pnml FILE' or '--dummy N')")
}

var homs: [Hom] = []
var initialMarking: DD = factory.zero

// Create the model.
switch CommandLine.arguments[1] {
case "--pnml":
  let model: PetriNet = try .parse(pnmlPath: CommandLine.arguments[2])
  for t in model.transitions {
    let hom = makeTransitionHomomorphism(
      preconditions: Array(model.pre[t]!.keys),
      postconditions: Array(model.post[t]!.keys))
    homs.append(hom)
  }
  initialMarking = factory.make(model.initialMarking.compactMap({ $0.value != 0 ? $0.key : nil }))

case "--dummy":
  homs = makeTransitions(modelSize: Int(CommandLine.arguments[2])!)
  initialMarking = factory.make(["p"])

case let unrecognized:
  fatalError("unrecognized command: '\(unrecognized)'")
}

// Create the transition system.
var transitionSystem: Homomorphism = homFactory.makeUnion(homs + [id]).fixed
transitionSystem = homFactory.optimize(transitionSystem).fixed

// Compute the state space.
let ss = transitionSystem.apply(on: initialMarking)
print(ss.count)
