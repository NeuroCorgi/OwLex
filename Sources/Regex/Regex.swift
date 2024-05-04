import Foundation
import Combine

public typealias NRegex = NFA<Int, Character>
public typealias DRegex = DFA<Int, Character>

func emptyMatcher() -> NRegex {
    return NRegex(
      start: 0,
      stop: [0],
      step: [:])
}

func dotMatcher() -> NRegex {
    return NRegex(
      start: 1,
      stop: [1],
      step: [0: ["a": [1]]])
}

func digitMatcher() -> NRegex {
    return NRegex(
      start: 0,
      stop: [1],
      step: [0: Dictionary(uniqueKeysWithValues: "0123456789".map { ($0, [1]) })])
}

func letterMatcher(_ l: Character) -> NRegex {
    return NRegex(
      start: 0,
      stop: [1],
      step: [0: [l: [1]]])
}

func append(_ left: NRegex, _ right: NRegex) -> NRegex {
    let size = left.states().count - 1
    
    let (stops, steps) =
      left.stop
      .map { end in
          let new  = right.incrementState(by: size)
          let new0 = new.replaceState(new.start, with: end)
          return (new0.stop, new0.step)
      }
      .unzip()

    return NFA(
      start: left.start,
      stop: stops.unions().union(left.stop),
      step: steps.reduce(left.step) { (res, step) in
          return res.merging(step) { (act1, act2) in
              return act1.merging(act2, uniquingKeysWith: { $0.union($1) })
          }
      }
    )
}

func concatenate(_ left: NRegex, _ right: NRegex) -> NRegex {
    let size = left.states().count - 1
    
    let (stops, steps) =
      left.stop
      .map { end in
          let incremented  = right.incrementState(by: size)
          let new = incremented.replaceState(incremented.start, with: end)
          return (new.stop, new.step)
      }
      .unzip()

    return NFA(
      start: left.start,
      stop: stops.unions(),
      step: steps.reduce(left.step) { (res, step) in
          return res.merging(step) { (act1, act2) in
              return act1.merging(act2, uniquingKeysWith: { $0.union($1) })
          }
      }
    )
}

func alternative(_ left: NRegex, _ right: NRegex) -> NRegex {
    let size = left.states().count - 1

    let incremented = right.incrementState(by: size)
    let alternative = incremented.replaceState(incremented.start, with: left.start)

    return NFA(
      start: left.start,
      stop: left.stop.union(alternative.stop),
      step: left.step.merging(alternative.step) { (act1, act2) in
          return act1.merging(act2, uniquingKeysWith: { $0.union($1) })
      }
    )
}

func append(_ seq: some Sequence<NRegex>) -> NRegex {
    // return seq.reduce(emptyMatcher(), append)
    if let first = seq.enumerated().first(where: { $0.offset == 0 })?.element {
        seq.dropFirst()
          .reduce(first, append)
    } else {
        emptyMatcher()
    }
}

func concatenate(_ seq: some Sequence<NRegex>) -> NRegex {
    // return seq.reduce(emptyMatcher(), concatenate)
    if let first = seq.enumerated().first(where: { $0.offset == 0 })?.element {
        seq.dropFirst()
          .reduce(first, concatenate)
    } else {
        emptyMatcher()
    }
}

func alternative(_ seq: some Sequence<NRegex>) -> NRegex {
    // return seq.reduce(emptyMatcher(), alternative)
    if let first = seq.enumerated().first(where: { $0.offset == 0 })?.element {
        seq.dropFirst()
          .reduce(first, alternative)
    } else {
        emptyMatcher()
    }
}

private func starPart(_ regex: NRegex) -> NRegex {
    var new = regex.mapStates { state in
        if regex.stop.contains(state) {
            regex.start
        } else {
            state
        }
    }
    new.stop = Set([new.start])
    return new
}

func zeroOrMore(_ regex: NRegex) -> NRegex {
    alternative([emptyMatcher(), append([regex, starPart(regex)])])
}

func oneOrMore(_ regex: NRegex) -> NRegex {
    append([regex, starPart(regex)])
}
