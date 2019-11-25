func makeTransitions(modelSize n: Int, suffix: String = "") -> [Hom] {
  let a = makeTransitionHomomorphism(
    preconditions : ["p\(suffix)"],
    postconditions: ["p\(suffix)l", "p\(suffix)r"])
  let b = makeTransitionHomomorphism(
    preconditions : ["p\(suffix)l", "p\(suffix)r"],
    postconditions: ["p\(suffix)"])

  if n > 1 {
    let l = makeTransitions(modelSize: n - 1, suffix: "\(suffix)l")
    let r = makeTransitions(modelSize: n - 1, suffix: "\(suffix)r")
    return [a, b] + l + r
  } else {
    return [a, b]
  }
}
