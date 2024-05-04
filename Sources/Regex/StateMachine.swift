enum StateMachineError: Error {
    case errorState
}

public protocol StateMachine<State, Action> {
    associatedtype State: Hashable
    associatedtype Action: Hashable

    func run(on seq: any Sequence<Action>) -> Bool

    func states() -> Set<State>
    func replaceState(_ orig: State, with dest: State) -> Self
    // func mapStates<NewState: Hashable>(_ mapping: @escaping (State) -> NewState) -> Self<NewState, Action>
}

// It seems not possible to force associated type like this
// Built-in Sequence map returns a List and not another Sequence
// extension StateMachine {
//     func normalize() -> Self<Int, Action> {
//         let mapping = Dictionary(
//           uniqueKeysWithValues:
//             self.states().enumerated().map { ($0.element, $0.offset) })
        
//         return self.mapStates { state in
//             mapping[state]!
//         }
//     }
// }

extension StateMachine where State == Int {
    func incrementState(by value: Int) -> Self {
        fatalError("Not implemented")
    }
}


public struct DFA<State: Hashable, Action: Hashable>: StateMachine {
    var start: State
    var stop: Set<State>
    let step: [State: [Action: State]]

    init(start: State, stop: Set<State>, step: [State: [Action: State]]) {
        self.start = start
        self.stop = stop
        self.step = step
    }

    init<NFAState>(from nfa: NFA<NFAState, Action>) where State == Set<NFAState> {
        let start = Set([nfa.start])
        var stop: Set<State> = []
        var step: [State: [Action: State]] = [:]

        print(nfa)

        var queue: [State] = [start]
        var visited: Set<State> = Set()
        while !queue.isEmpty {
            let state = queue.popLast()!
            guard !visited.contains(state) else { continue }
            visited.insert(state)

            let action_table = state.compactMap { nfa.step[$0] }
            print(state, action_table)

            var state_table: [Action: State] = [:]
            for table in action_table {
                for (action, value) in table {
                    queue.append(value)
                    let value = value.union(step[state]?[action] ?? Set())
                    state_table[action] = value
                }
            }
            if !state_table.isEmpty {
                step[state] = state_table
            }

            if nfa.stop.intersection(state).count != 0 {
                stop.insert(state)
            }
        }       

        self.start = Set([nfa.start])
        self.stop = stop
        self.step = step
    }

    public func run(on seq: any Sequence<Action>) -> Bool {
        do {
            return self.stop.contains(
              try seq.reduce(self.start) { (state, action) in
                  guard let nextState = self.step[state]?[action] else {
                      throw StateMachineError.errorState
                  }
                  return nextState
              })
        } catch {
            return false
        }
    }

    public func states() -> Set<State> {
        let step =
          self.step.map { (key, step) in
              return Set(step.values).union([key])
          }
          .unions()
        return [Set([self.start]), self.stop, step].unions()
    }

    public func replaceState(_ orig: State, with dest: State) -> DFA<State, Action> {
        let change = { if $0 == orig { dest } else { $0 } }

        let start = change(self.start)
        let stop  = Set(self.stop.map(change))
        let step  = Dictionary(
          uniqueKeysWithValues:
            self.step.map { (key, step) in
                (change(key), step.mapValues(change)) })
        return DFA(start: start, stop: stop, step: step)
    }

    public func mapStates<NewState: Hashable>(_ mapping: @escaping (State) -> NewState) -> DFA<NewState, Action> {
        let start = mapping(self.start)
        let stop  = Set(self.stop.map(mapping))
        let step  = Dictionary(
          uniqueKeysWithValues: self.step.map { (key, step) in
              (mapping(key), step.mapValues(mapping))
          })
        return DFA<NewState, Action>(start: start, stop: stop, step: step)
    }

    public func normalize() -> DFA<Int, Action> {
        let mapping = Dictionary(
          uniqueKeysWithValues:
            self.states().enumerated().map { ($0.element, $0.offset) })
        
        return self.mapStates { state in
            mapping[state]!
        }
    }
}

public struct NFA<State: Hashable, Action: Hashable>: StateMachine {
    var start: State
    var stop: Set<State>
    let step: [State: [Action: Set<State>]]

    init(start: State, stop: Set<State>, step: [State: [Action: Set<State>]]) {
        self.start = start
        self.stop = stop
        self.step = step
    }

    init(from dfa: DFA<State, Action>) {
        self.start = dfa.start
        self.stop = dfa.stop
        self.step = dfa.step.mapValues { actionMap in
            actionMap.mapValues { Set([$0]) }
        }
    }

    public func run(on seq: any Sequence<Action>) -> Bool {
        return !self.stop.intersection(
          seq.reduce(Set([self.start])) { (states, action) in
              let newStates = states
                .map { self.step[$0]?[action] ?? [] }
                .unions()
              return newStates
          })
          .isEmpty
    }

    public func states() -> Set<State> {
        let step =
          self.step
          .map { (key, step) in
              step.values.reduce(Set()) { (res, set) in res.union(set)}
                .union(Set([key]))
          }
          .unions()
        return [Set([self.start]), self.stop, step].unions()
    }

    public func replaceState(_ orig: State, with dest: State) -> NFA<State, Action> {
        let change = { if $0 == orig { dest } else { $0 } }

        let start = change(self.start)
        let stop  = Set(self.stop.map(change))
        let step  = Dictionary(
          uniqueKeysWithValues:
            self.step.map { (key, step) in
                (change(key), step.mapValues { Set($0.map(change)) })
            })
        return NFA(start: start, stop: stop, step: step)
    }

    public func mapStates<NewState: Hashable>(_ mapping: @escaping (State) -> NewState) -> NFA<NewState, Action> {
        let start = mapping(self.start)
        let stop  = Set(self.stop.map(mapping))
        let step  = Dictionary(
          uniqueKeysWithValues:
            self.step.map { (key, step) in
                (mapping(key), step.mapValues { Set($0.map(mapping)) })
            })
        return NFA<NewState, Action>(start: start, stop: stop, step: step)
    }
}

extension NFA where State == Int {
    func incrementState(by value: Int) -> NFA {
        let incr = { $0 + value }
        let step = self.step.map { (key, step) in
            return (incr(key), step.mapValues { Set($0.map(incr)) } )
        }
        
        return NFA(
          start: incr(self.start),
          stop: Set(self.stop.map(incr)),
          step: Dictionary(uniqueKeysWithValues: step))
    }
}
