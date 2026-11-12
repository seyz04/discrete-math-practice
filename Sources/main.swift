import SwiftUI
import AppKit

// MARK: - Small helpers

func rint(_ range: ClosedRange<Int>) -> Int { Int.random(in: range) }
func coin() -> Bool { Bool.random() }
func tf(_ b: Bool) -> String { b ? "T" : "F" }

func gcd(_ a: Int, _ b: Int) -> Int {
    var x = abs(a), y = abs(b)
    while y != 0 { (x, y) = (y, x % y) }
    return x
}

// Math mod: always lands in 0...m-1, even for negative a.
func md(_ a: Int, _ m: Int) -> Int { ((a % m) + m) % m }

func ipow(_ b: Int, _ e: Int) -> Int {
    var r = 1
    for _ in 0..<max(e, 0) { r *= b }
    return r
}

func choose(_ n: Int, _ k: Int) -> Int {
    if k < 0 || k > n { return 0 }
    let k = min(k, n - k)
    var r = 1
    for i in 0..<k { r = r * (n - i) / (i + 1) }
    return r
}

func perm(_ n: Int, _ k: Int) -> Int {
    if k < 0 || k > n { return 0 }
    var r = 1
    for i in 0..<k { r *= (n - i) }
    return r
}

func fact(_ n: Int) -> Int { perm(n, n) }

// 1234567 → "1,234,567"
func num(_ x: Int) -> String {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    let s = f.string(from: NSNumber(value: x)) ?? "\(x)"
    return s.hasPrefix("-") ? "−" + String(s.dropFirst()) : s
}

func frac(_ n: Int, _ d: Int) -> String {
    let g = max(gcd(n, d), 1)
    var a = n / g, b = d / g
    if b < 0 { a = -a; b = -b }
    let sign = a < 0 ? "−" : ""
    return b == 1 ? "\(sign)\(abs(a))" : "\(sign)\(abs(a))/\(b)"
}

func dec(_ x: Double) -> String {
    let s = String(format: "%.4g", x)
    return s.hasPrefix("-") ? "−" + String(s.dropFirst()) : s
}

// Signed term for printing "x + 3" vs "x − 3"
func sgn(_ v: Int) -> String { v < 0 ? "− \(abs(v))" : "+ \(v)" }
func neg(_ v: Int) -> String { v < 0 ? "−\(abs(v))" : "\(v)" }

func setStr(_ s: [Int]) -> String { s.isEmpty ? "∅" : "{" + s.sorted().map { "\($0)" }.joined(separator: ", ") + "}" }

// Accepts "0.25", "-1/13", "−17/16", "1,024", " 3 "
func parseAnswer(_ raw: String) -> Double? {
    let s = raw.replacingOccurrences(of: "−", with: "-")
        .replacingOccurrences(of: " ", with: "")
        .replacingOccurrences(of: ",", with: "")
    if s.isEmpty { return nil }
    let parts = s.split(separator: "/")
    if parts.count == 2, let a = Double(String(parts[0])), let b = Double(String(parts[1])), b != 0 { return a / b }
    if parts.count == 1 { return Double(s) }
    return nil
}

// MARK: - Topics (in teaching order)

enum Topic: String, CaseIterable, Identifiable {
    case connectives = "Propositions: ¬ ∧ ∨ ⊕"
    case conditionals = "Conditionals: → and ↔"
    case truthTables = "Truth tables"
    case equivalence = "Logical equivalences"
    case quantifiers = "Quantifiers: ∀ and ∃"
    case proofs = "Proof methods"
    case induction = "Mathematical induction"
    case sets = "Set operations"
    case setSize = "Counting with sets"
    case functions = "Functions"
    case sequences = "Sequences & sums"
    case modArith = "Division & mod"
    case gcdTopic = "GCD, LCM & primes"
    case modInverse = "Modular inverses"
    case bases = "Number bases"
    case countRules = "Product & sum rules"
    case permComb = "Permutations & combinations"
    case starsBars = "Stars and bars"
    case pigeonhole = "Pigeonhole principle"
    case binomial = "Binomial theorem"
    case probability = "Discrete probability"
    case relations = "Relations"
    case graphs = "Graphs & trees"
    case recurrences = "Recurrences"
    var id: String { rawValue }
}

func unit(_ t: Topic) -> String {
    switch t {
    case .connectives, .conditionals, .truthTables, .equivalence, .quantifiers: return "Unit 1 · Logic"
    case .proofs, .induction: return "Unit 2 · Proofs"
    case .sets, .setSize, .functions, .sequences: return "Unit 3 · Sets, functions, sums"
    case .modArith, .gcdTopic, .modInverse, .bases: return "Unit 4 · Number theory"
    case .countRules, .permComb, .starsBars, .pigeonhole, .binomial: return "Unit 5 · Counting"
    case .probability: return "Unit 6 · Probability"
    case .relations, .graphs: return "Unit 7 · Relations & graphs"
    case .recurrences: return "Unit 8 · Recurrences"
    }
}

struct Problem {
    let topic: Topic
    let prompt: String
    let steps: [String]
    let answer: String
    var numeric: Double? = nil    // typed answer, auto-checked
    var ask: String? = nil        // label next to the answer box
    var choices: [String]? = nil  // multiple choice (keys 1–4)
    var correct: Int = 0
}

let tfChoices = ["True", "False"]

// Shuffles the options and remembers where the right one went.
func mc(_ topic: Topic, _ prompt: String, right: String, wrong: [String], steps: [String]) -> Problem {
    var seen: [String] = [right]
    for w in wrong where !seen.contains(w) { seen.append(w) }
    let opts = Array(seen.prefix(4)).shuffled()
    return Problem(topic: topic, prompt: prompt, steps: steps, answer: "Answer: \(right)",
                   choices: opts, correct: opts.firstIndex(of: right) ?? 0)
}

func tfProblem(_ topic: Topic, _ prompt: String, _ value: Bool, steps: [String]) -> Problem {
    Problem(topic: topic, prompt: prompt, steps: steps, answer: "Answer: \(value ? "True" : "False")",
            choices: tfChoices, correct: value ? 0 : 1)
}

func numProblem(_ topic: Topic, _ prompt: String, _ value: Double, shown: String, ask: String = "Answer =", steps: [String]) -> Problem {
    Problem(topic: topic, prompt: prompt, steps: steps, answer: "Answer: \(shown)", numeric: value, ask: ask)
}

// MARK: - Propositional logic engine

indirect enum L {
    case v(String)
    case not(L)
    case and(L, L)
    case or(L, L)
    case xor(L, L)
    case imp(L, L)
    case iff(L, L)

    var isAtom: Bool { if case .v = self { return true }; return false }

    func s(_ top: Bool = true) -> String {
        func bin(_ a: L, _ op: String, _ b: L) -> String {
            let inner = "\(a.s(false)) \(op) \(b.s(false))"
            return top ? inner : "(\(inner))"
        }
        switch self {
        case .v(let n): return n
        case .not(let a): return "¬" + a.s(false)
        case .and(let a, let b): return bin(a, "∧", b)
        case .or(let a, let b): return bin(a, "∨", b)
        case .xor(let a, let b): return bin(a, "⊕", b)
        case .imp(let a, let b): return bin(a, "→", b)
        case .iff(let a, let b): return bin(a, "↔", b)
        }
    }

    func eval(_ e: [String: Bool]) -> Bool {
        switch self {
        case .v(let n): return e[n] ?? false
        case .not(let a): return !a.eval(e)
        case .and(let a, let b): return a.eval(e) && b.eval(e)
        case .or(let a, let b): return a.eval(e) || b.eval(e)
        case .xor(let a, let b): return a.eval(e) != b.eval(e)
        case .imp(let a, let b): return !a.eval(e) || b.eval(e)
        case .iff(let a, let b): return a.eval(e) == b.eval(e)
        }
    }

    var vars: [String] {
        var out: Set<String> = []
        func walk(_ x: L) {
            switch x {
            case .v(let n): out.insert(n)
            case .not(let a): walk(a)
            case .and(let a, let b), .or(let a, let b), .xor(let a, let b), .imp(let a, let b), .iff(let a, let b): walk(a); walk(b)
            }
        }
        walk(self)
        return out.sorted()
    }

    // "T ∧ F = F": the step for this node once its children are known.
    func stepLine(_ e: [String: Bool]) -> String? {
        func show(_ a: L, _ op: String, _ b: L) -> String {
            "\(s()):  \(tf(a.eval(e))) \(op) \(tf(b.eval(e))) = \(tf(eval(e)))"
        }
        switch self {
        case .v: return nil
        case .not(let a): return "\(s()):  ¬\(tf(a.eval(e))) = \(tf(eval(e)))"
        case .and(let a, let b): return show(a, "∧", b)
        case .or(let a, let b): return show(a, "∨", b)
        case .xor(let a, let b): return show(a, "⊕", b)
        case .imp(let a, let b): return show(a, "→", b)
        case .iff(let a, let b): return show(a, "↔", b)
        }
    }

    // Inside-out list of steps, no repeats.
    func evalSteps(_ e: [String: Bool]) -> [String] {
        var out: [String] = []
        func walk(_ x: L) {
            switch x {
            case .v: break
            case .not(let a): walk(a)
            case .and(let a, let b), .or(let a, let b), .xor(let a, let b), .imp(let a, let b), .iff(let a, let b): walk(a); walk(b)
            }
            if let line = x.stepLine(e), !out.contains(line) { out.append(line) }
        }
        walk(self)
        return out
    }
}

func envs(_ vars: [String]) -> [[String: Bool]] {
    var rows: [[String: Bool]] = [[:]]
    for v in vars {
        rows = rows.flatMap { r -> [[String: Bool]] in
            var t = r; t[v] = true
            var f = r; f[v] = false
            return [t, f]
        }
    }
    return rows
}

func equivalent(_ a: L, _ b: L) -> Bool {
    let vs = Array(Set(a.vars + b.vars)).sorted()
    return envs(vs).allSatisfy { a.eval($0) == b.eval($0) }
}

let P = L.v("p"), Q = L.v("q"), R = L.v("r")

func randAtom(_ pool: [L]) -> L {
    let a = pool.randomElement()!
    return Int.random(in: 0..<4) == 0 ? .not(a) : a
}

func randBin(_ a: L, _ b: L, ops: [Int]) -> L {
    switch ops.randomElement()! {
    case 0: return .and(a, b)
    case 1: return .or(a, b)
    case 2: return .xor(a, b)
    case 3: return .imp(a, b)
    default: return .iff(a, b)
    }
}

func randExpr(ops: [Int]) -> L {
    let v = [P, Q, R].shuffled()
    let left = randBin(randAtom([v[0]]), randAtom([v[1]]), ops: ops)
    let shape = rint(0...2)
    if shape == 0 { return randBin(left, randAtom([v[2]]), ops: ops) }
    if shape == 1 { return randBin(randAtom([v[2]]), .not(left), ops: ops) }
    return randBin(left, randBin(randAtom([v[2]]), randAtom([v[0], v[1]]), ops: ops), ops: ops)
}

func envLine(_ vs: [String], _ e: [String: Bool]) -> String {
    vs.map { "\($0) = \(tf(e[$0]!))" }.joined(separator: ",  ")
}

// MARK: - Unit 1: Logic

func generateConnectives() -> Problem {
    let x = randExpr(ops: [0, 1, 0, 1, 2])
    let vs = x.vars
    var e: [String: Bool] = [:]
    for v in vs { e[v] = coin() }
    var steps = ["Plug in the truth values: \(envLine(vs, e))",
                 "Work from the inside out: innermost parentheses first, and ¬ sticks to whatever is right after it."]
    steps += x.evalSteps(e)
    return tfProblem(.connectives, "\(envLine(vs, e))\n\nIs  \(x.s())  true or false?", x.eval(e), steps: steps)
}

struct Cond {
    let h: String, c: String, nh: String, nc: String
}
let condBank: [Cond] = [
    Cond(h: "it rains", c: "the game is canceled", nh: "it does not rain", nc: "the game is not canceled"),
    Cond(h: "you study", c: "you pass the quiz", nh: "you don't study", nc: "you don't pass the quiz"),
    Cond(h: "n is divisible by 4", c: "n is even", nh: "n is not divisible by 4", nc: "n is not even"),
    Cond(h: "the Fed raises rates", c: "bond prices fall", nh: "the Fed doesn't raise rates", nc: "bond prices don't fall"),
    Cond(h: "a shape is a square", c: "it has four sides", nh: "a shape is not a square", nc: "it doesn't have four sides"),
    Cond(h: "Sey lands the internship", c: "Sey spends the summer in NYC", nh: "Sey doesn't land the internship", nc: "Sey doesn't spend the summer in NYC"),
    Cond(h: "x > 5", c: "x² > 25", nh: "x ≤ 5", nc: "x² ≤ 25"),
]

func generateConditionals() -> Problem {
    if coin() {
        var x = randExpr(ops: [3, 3, 4, 0, 1])
        while !x.s().contains("→") && !x.s().contains("↔") { x = randExpr(ops: [3, 3, 4, 0, 1]) }
        let vs = x.vars
        var e: [String: Bool] = [:]
        for v in vs { e[v] = coin() }
        var steps = ["Plug in: \(envLine(vs, e))",
                     "Rule for →: it is false ONLY when the left side is T and the right side is F (T → F = F). Everything else is T.",
                     "Rule for ↔: true when both sides match (T↔T or F↔F)."]
        steps += x.evalSteps(e)
        return tfProblem(.conditionals, "\(envLine(vs, e))\n\nIs  \(x.s())  true or false?", x.eval(e), steps: steps)
    }
    let k = condBank.randomElement()!
    let original = "If \(k.h), then \(k.c)."
    let converse = "If \(k.c), then \(k.h)."
    let inverse = "If \(k.nh), then \(k.nc)."
    let contra = "If \(k.nc), then \(k.nh)."
    let which = rint(0...3)
    let names = ["converse", "inverse", "contrapositive", "equivalent"]
    let right = [converse, inverse, contra, contra][which]
    let q = which == 3 ? "Which statement is logically equivalent to:\n\"\(original)\"" : "What is the \(names[which]) of:\n\"\(original)\""
    let wrong = [converse, inverse, contra, "If \(k.c), then \(k.nh)."].filter { $0 != right }
    return mc(.conditionals, q, right: right, wrong: wrong, steps: [
        "Name the parts: p = \"\(k.h)\",  q = \"\(k.c)\". The original is p → q.",
        "Converse: q → p (swap).  Inverse: ¬p → ¬q (negate both).  Contrapositive: ¬q → ¬p (swap AND negate).",
        "Only the contrapositive is equivalent to the original. The converse and inverse are equivalent to each other, not to p → q.",
        which == 3 ? "So the equivalent one is the contrapositive." : "So the \(names[which]) is the one built by that rule.",
    ])
}

let tautologies: [L] = [
    .or(P, .not(P)), .imp(.and(P, Q), P), .imp(P, .or(P, Q)), .imp(.and(.imp(P, Q), P), Q),
    .iff(.imp(P, Q), .imp(.not(Q), .not(P))), .imp(.and(.imp(P, Q), .not(Q)), .not(P)),
    .imp(.and(.imp(P, Q), .imp(Q, R)), .imp(P, R)),
]
let contradictions: [L] = [
    .and(P, .not(P)), .and(.imp(P, Q), .and(P, .not(Q))), .not(.imp(P, .imp(Q, P))), .and(.iff(P, Q), .xor(P, Q)),
]

func truthTableSteps(_ x: L) -> ([String], Int, Int) {
    let vs = x.vars
    let rows = envs(vs)
    var steps = ["\(vs.count) variables → 2^\(vs.count) = \(rows.count) rows. Go row by row (TT…, then flip the last variable fastest)."]
    var trues = 0
    for e in rows {
        let val = x.eval(e)
        if val { trues += 1 }
        steps.append("\(envLine(vs, e))  →  \(tf(val))")
    }
    return (steps, trues, rows.count)
}

func generateTruthTable() -> Problem {
    let kind = rint(0...2)
    if kind == 0 {
        let x = randExpr(ops: [0, 1, 2, 3, 4])
        var (steps, trues, _) = truthTableSteps(x)
        steps.append("Count the T's: \(trues).")
        return numProblem(.truthTables, "Build the truth table for\n\(x.s())\n\nIn how many rows is it TRUE?", Double(trues), shown: "\(trues) rows",
                          ask: "rows true =", steps: steps)
    }
    let x: L
    if kind == 1 { x = coin() ? tautologies.randomElement()! : contradictions.randomElement()! } else { x = randExpr(ops: [0, 1, 3, 4]) }
    var (steps, trues, total) = truthTableSteps(x)
    let right = trues == total ? "Tautology" : (trues == 0 ? "Contradiction" : "Contingency")
    steps.append("All T → tautology. All F → contradiction. A mix → contingency. Here: \(trues) T out of \(total), so \(right.lowercased()).")
    return mc(.truthTables, "Is this a tautology, a contradiction, or a contingency?\n\(x.s())",
              right: right, wrong: ["Tautology", "Contradiction", "Contingency"], steps: steps)
}

func generateEquivalence() -> Problem {
    let pool = [P, Q, R, .not(R)]
    var a = pool.randomElement()!, b = pool.randomElement()!
    while a.vars == b.vars { a = pool.randomElement()!; b = pool.randomElement()! }
    func notOf(_ x: L) -> L { if case .not(let i) = x { return i }; return .not(x) }
    let kind = rint(0...4)
    let target: L
    var right: L
    var wrong: [L]
    var law: String
    switch kind {
    case 0:
        target = .not(.and(a, b)); right = .or(notOf(a), notOf(b)); wrong = [.and(notOf(a), notOf(b)), .or(a, notOf(b)), .and(a, notOf(b))]
        law = "De Morgan: ¬(A ∧ B) ≡ ¬A ∨ ¬B. The ¬ goes onto each piece and ∧ flips to ∨."
    case 1:
        target = .not(.or(a, b)); right = .and(notOf(a), notOf(b)); wrong = [.or(notOf(a), notOf(b)), .and(a, notOf(b)), .or(a, b)]
        law = "De Morgan: ¬(A ∨ B) ≡ ¬A ∧ ¬B. The ¬ goes onto each piece and ∨ flips to ∧."
    case 2:
        target = .imp(a, b); right = .or(notOf(a), b); wrong = [.or(a, notOf(b)), .and(notOf(a), b), .imp(b, a)]
        law = "Conditional as an or: A → B ≡ ¬A ∨ B (either A fails, or B happens)."
    case 3:
        target = .not(.imp(a, b)); right = .and(a, notOf(b)); wrong = [.imp(notOf(a), notOf(b)), .and(notOf(a), b), .imp(a, notOf(b))]
        law = "Negating a conditional: ¬(A → B) ≡ A ∧ ¬B. The only way A → B fails is A true and B false. It is NOT another →."
    default:
        target = .imp(a, b); right = .imp(notOf(b), notOf(a)); wrong = [.imp(b, a), .imp(notOf(a), notOf(b)), .and(a, notOf(b))]
        law = "Contrapositive: A → B ≡ ¬B → ¬A. The converse and inverse are traps."
    }
    wrong = wrong.filter { !equivalent($0, target) }
    // ¬¬r should print as r
    func clean(_ x: L) -> L {
        switch x {
        case .not(.not(let i)): return clean(i)
        case .not(let i): return .not(clean(i))
        case .and(let l, let r): return .and(clean(l), clean(r))
        case .or(let l, let r): return .or(clean(l), clean(r))
        case .xor(let l, let r): return .xor(clean(l), clean(r))
        case .imp(let l, let r): return .imp(clean(l), clean(r))
        case .iff(let l, let r): return .iff(clean(l), clean(r))
        default: return x
        }
    }
    right = clean(right)
    let bad = wrong.map { clean($0) }
    let witness = bad.first.flatMap { w -> String? in
        let vs = Array(Set(w.vars + target.vars)).sorted()
        guard let e = envs(vs).first(where: { w.eval($0) != target.eval($0) }) else { return nil }
        return "Check a trap: at \(envLine(vs, e)), \(clean(target).s()) is \(tf(target.eval(e))) but \(w.s()) is \(tf(w.eval(e))). Not equivalent."
    }
    var steps = ["Which law matches the shape of \(clean(target).s())?", law, "Apply it: \(clean(target).s())  ≡  \(right.s())"]
    if let w = witness { steps.append(w) }
    return mc(.equivalence, "Which is logically equivalent to\n\(clean(target).s())", right: right.s(), wrong: bad.map { $0.s() }, steps: steps)
}

struct Pred {
    let name: String
    let test: (Int) -> Bool
}

func generateQuantifiers() -> Problem {
    let lo = rint(1...3), hi = lo + rint(3...5)
    let dom = Array(lo...hi)
    let k = rint(lo...hi)
    let preds = [
        Pred(name: "x is even", test: { $0 % 2 == 0 }),
        Pred(name: "x > \(k)", test: { $0 > k }),
        Pred(name: "x² ≥ \(k * 3)", test: { $0 * $0 >= k * 3 }),
        Pred(name: "x is prime", test: { n in n > 1 && (2..<n).allSatisfy { n % $0 != 0 } }),
        Pred(name: "x ≤ \(hi)", test: { $0 <= hi }),
    ]
    let p = preds.randomElement()!
    var q = preds.randomElement()!
    while q.name == p.name { q = preds.randomElement()! }
    let domS = setStr(dom)
    let kind = rint(0...4)
    if kind == 4 {
        let forms: [(String, String, [String])] = [
            ("¬∀x P(x)", "∃x ¬P(x)", ["∀x ¬P(x)", "¬∃x P(x)", "∃x P(x)"]),
            ("¬∃x P(x)", "∀x ¬P(x)", ["∃x ¬P(x)", "¬∀x P(x)", "∀x P(x)"]),
            ("¬∀x (P(x) → Q(x))", "∃x (P(x) ∧ ¬Q(x))", ["∀x (P(x) ∧ ¬Q(x))", "∃x (¬P(x) → ¬Q(x))", "∃x (P(x) → ¬Q(x))"]),
            ("¬∃x (P(x) ∧ Q(x))", "∀x (¬P(x) ∨ ¬Q(x))", ["∀x (¬P(x) ∧ ¬Q(x))", "∃x (¬P(x) ∨ ¬Q(x))", "∀x (P(x) → Q(x))"]),
        ]
        let f = forms.randomElement()!
        return mc(.quantifiers, "Push the negation all the way in:\n\(f.0)", right: f.1, wrong: f.2, steps: [
            "Rule: ¬∀ becomes ∃¬, and ¬∃ becomes ∀¬. The quantifier flips and the ¬ moves inside.",
            "Then negate what's inside with the logic rules: ¬(A → B) ≡ A ∧ ¬B, and De Morgan for ∧ / ∨.",
            "\(f.0)  ≡  \(f.1)",
        ])
    }
    let stmt: String
    let value: Bool
    var steps = ["Domain: \(domS). Check every element. P(x): \(p.name)" + (kind >= 2 ? ",  Q(x): \(q.name)" : "") + "."]
    switch kind {
    case 0:
        stmt = "∀x P(x)"
        value = dom.allSatisfy(p.test)
        steps.append(dom.map { "\($0): \(tf(p.test($0)))" }.joined(separator: "   "))
        steps.append("∀ needs EVERY one true. " + (value ? "They all are, so TRUE." : "x = \(dom.first { !p.test($0) }!) fails, so one counterexample makes it FALSE."))
    case 1:
        stmt = "∃x P(x)"
        value = dom.contains(where: p.test)
        steps.append(dom.map { "\($0): \(tf(p.test($0)))" }.joined(separator: "   "))
        steps.append("∃ needs just ONE true. " + (value ? "x = \(dom.first(where: p.test)!) works, so TRUE." : "None work, so FALSE."))
    case 2:
        stmt = "∀x (P(x) → Q(x))"
        value = dom.allSatisfy { !p.test($0) || q.test($0) }
        steps.append(dom.map { "\($0): \(tf(p.test($0)))→\(tf(q.test($0)))" }.joined(separator: "   "))
        steps.append("Only rows with P true and Q false break it. " + (value ? "None do, so TRUE." : "x = \(dom.first { p.test($0) && !q.test($0) }!) breaks it, so FALSE."))
    default:
        stmt = "∃x (P(x) ∧ Q(x))"
        value = dom.contains { p.test($0) && q.test($0) }
        steps.append(dom.map { "\($0): \(tf(p.test($0)))∧\(tf(q.test($0)))" }.joined(separator: "   "))
        steps.append("Need one x where both hold. " + (value ? "x = \(dom.first { p.test($0) && q.test($0) }!) works, so TRUE." : "None, so FALSE."))
    }
    return tfProblem(.quantifiers, "Domain = \(domS)\nP(x): \(p.name)" + (kind >= 2 ? "\nQ(x): \(q.name)" : "") + "\n\nIs  \(stmt)  true?", value, steps: steps)
}

// MARK: - Unit 2: Proofs

struct ProofItem {
    let claim: String
    let method: String
    let why: String
    let firstLine: String
}
let proofBank: [ProofItem] = [
    ProofItem(claim: "If n is odd, then n² is odd.", method: "Direct proof", why: "The hypothesis gives you a formula to work with (n = 2k + 1). Square it.", firstLine: "Assume n is odd, so n = 2k + 1. Then n² = 4k² + 4k + 1 = 2(2k² + 2k) + 1, which is odd."),
    ProofItem(claim: "If n² is even, then n is even.", method: "Contrapositive", why: "Starting from n² even is awkward. The contrapositive \"if n is odd, n² is odd\" is easy.", firstLine: "Prove instead: if n is odd then n² is odd. n = 2k + 1 ⇒ n² = 2(2k² + 2k) + 1."),
    ProofItem(claim: "√2 is irrational.", method: "Contradiction", why: "\"Irrational\" means NOT a fraction. Assume it IS a fraction and break something.", firstLine: "Suppose √2 = a/b in lowest terms. Then a² = 2b², so a is even, then b is even. Both even contradicts lowest terms."),
    ProofItem(claim: "1 + 2 + ⋯ + n = n(n + 1)/2 for every n ≥ 1.", method: "Induction", why: "A statement for every n ≥ 1 that builds from n to n + 1.", firstLine: "Base case n = 1: 1 = 1·2/2. Inductive step: assume it for k, add (k + 1) to both sides."),
    ProofItem(claim: "There are infinitely many primes.", method: "Contradiction", why: "Assume only finitely many and build a number that breaks the list.", firstLine: "Suppose p₁, …, pₙ are all the primes. N = p₁⋯pₙ + 1 has a prime factor not on the list. Contradiction."),
    ProofItem(claim: "If a | b and b | c, then a | c.", method: "Direct proof", why: "Unpack the definitions and substitute.", firstLine: "b = ak and c = bm, so c = a(km). So a | c."),
    ProofItem(claim: "If 3n + 2 is odd, then n is odd.", method: "Contrapositive", why: "Flip it: if n is even, then 3n + 2 is even. Plug in n = 2k.", firstLine: "Assume n is even, n = 2k. Then 3n + 2 = 6k + 2 = 2(3k + 1), even."),
    ProofItem(claim: "2ⁿ > n for every integer n ≥ 1.", method: "Induction", why: "An inequality for all n that grows step by step.", firstLine: "Base: 2 > 1. Step: if 2ᵏ > k then 2ᵏ⁺¹ = 2·2ᵏ > 2k ≥ k + 1."),
    ProofItem(claim: "There is no largest even integer.", method: "Contradiction", why: "Assume a largest one exists and find a bigger one.", firstLine: "Suppose N is the largest even integer. N + 2 is even and bigger. Contradiction."),
    ProofItem(claim: "There exists an integer n with n² = n.", method: "Existence (example)", why: "An ∃ statement only needs one example.", firstLine: "Take n = 1: 1² = 1. Done."),
    ProofItem(claim: "Every integer n satisfies n² ≥ n.", method: "Proof by cases", why: "Split into n ≤ 0 and n ≥ 1; each case is easy on its own.", firstLine: "Case n ≤ 0: n² ≥ 0 ≥ n. Case n ≥ 1: multiply n ≥ 1 by n to get n² ≥ n."),
    ProofItem(claim: "\"Every odd number is prime\" is false.", method: "Counterexample", why: "A ∀ claim dies with one counterexample.", firstLine: "9 is odd but 9 = 3·3, so it isn't prime."),
]
let proofMethods = ["Direct proof", "Contrapositive", "Contradiction", "Induction", "Proof by cases", "Existence (example)", "Counterexample"]

func generateProofs() -> Problem {
    let item = proofBank.randomElement()!
    if item.method == "Contrapositive" && coin() {
        // What do you assume first?
        func flip(_ x: String) -> String {
            x.contains("odd") ? x.replacingOccurrences(of: "odd", with: "even") : x.replacingOccurrences(of: "even", with: "odd")
        }
        let parts = item.claim.dropFirst(3).components(separatedBy: ", then ")
        let h = parts[0], c = String(parts[1].dropLast())
        let right = "Assume \(flip(c)), and show \(flip(h))."
        return mc(.proofs, "You prove \"\(item.claim)\" by contrapositive.\nWhat is your first line?", right: right,
                  wrong: ["Assume \(h), and show \(c).", "Assume \(c), and show \(h).", "Assume \(h) and \(flip(c)), and find a contradiction."],
                  steps: ["The claim is p → q with p = \"\(h)\", q = \"\(c)\".",
                          "Contrapositive: ¬q → ¬p. Assume the conclusion is false, show the hypothesis is false.",
                          "¬q = \"\(flip(c))\",  ¬p = \"\(flip(h))\".",
                          item.firstLine])
    }
    let wrong = proofMethods.filter { $0 != item.method }.shuffled()
    return mc(.proofs, "Which method fits best?\n\"\(item.claim)\"", right: item.method, wrong: Array(wrong.prefix(3)), steps: [
        "Look at the shape: if-then? for every n? \"not\" / \"no\" / \"infinitely many\"? there exists?",
        item.why,
        "How it starts: \(item.firstLine)",
    ])
}

struct SumFormula {
    let lhs: String
    let rhs: String
    let term: (Int) -> Int
    let closed: (Int) -> Int
    let termS: (String) -> String
}
let sumBank: [SumFormula] = [
    SumFormula(lhs: "1 + 2 + ⋯ + n", rhs: "n(n + 1)/2", term: { $0 }, closed: { $0 * ($0 + 1) / 2 }, termS: { $0 }),
    SumFormula(lhs: "1 + 3 + 5 + ⋯ + (2n − 1)", rhs: "n²", term: { 2 * $0 - 1 }, closed: { $0 * $0 }, termS: { "2(\($0)) − 1" }),
    SumFormula(lhs: "1² + 2² + ⋯ + n²", rhs: "n(n + 1)(2n + 1)/6", term: { $0 * $0 }, closed: { $0 * ($0 + 1) * (2 * $0 + 1) / 6 }, termS: { "(\($0))²" }),
    SumFormula(lhs: "2 + 4 + ⋯ + 2n", rhs: "n(n + 1)", term: { 2 * $0 }, closed: { $0 * ($0 + 1) }, termS: { "2(\($0))" }),
    SumFormula(lhs: "1 + 2 + 4 + ⋯ + 2^(n−1)", rhs: "2^n − 1", term: { ipow(2, $0 - 1) }, closed: { ipow(2, $0) - 1 }, termS: { "2^(\($0) − 1)" }),
]

func generateInduction() -> Problem {
    let f = sumBank.randomElement()!
    let claim = "Claim: \(f.lhs) = \(f.rhs)  for all n ≥ 1"
    let kind = rint(0...2)
    if kind == 0 {
        return mc(.induction, "\(claim)\n\nIn the inductive step you assume it for n = k.\nWhat do you ADD to both sides to reach n = k + 1?",
                  right: f.termS("k + 1"), wrong: [f.termS("k"), f.termS("k + 2"), f.rhs.replacingOccurrences(of: "n", with: "(k + 1)")], steps: [
            "Inductive hypothesis (IH): \(f.lhs.replacingOccurrences(of: "n", with: "k")) = \(f.rhs.replacingOccurrences(of: "n", with: "k")).",
            "The k + 1 version has exactly one more term on the left: the (k + 1)th term.",
            "The nth term is \(f.termS("n")), so the next one is \(f.termS("k + 1")).",
            "Add it to both sides, then use algebra to show the right side becomes \(f.rhs.replacingOccurrences(of: "n", with: "(k + 1)")).",
        ])
    }
    if kind == 1 {
        let n = rint(4...7)
        let terms = (1...n).map { f.term($0) }
        let total = terms.reduce(0, +)
        return numProblem(.induction, "\(claim)\n\nSanity check before proving: compute the left side at n = \(n).", Double(total), shown: "\(total)",
                          ask: "LHS at n = \(n):", steps: [
            "Write out the terms: " + terms.map { "\($0)" }.joined(separator: " + "),
            "Add: \(total).",
            "Right side: \(f.rhs) at n = \(n) gives \(f.closed(n)). They match, so the formula is believable. Induction is what makes it certain for every n.",
        ])
    }
    let steps = ["The four parts of an induction proof:", "1) State P(n).  2) Base case: check P(1).", "3) Inductive step: assume P(k) (the inductive hypothesis) and prove P(k + 1).", "4) Conclude P(n) holds for all n ≥ 1."]
    let questions: [(String, String, [String])] = [
        ("In the inductive step, what are you allowed to assume?", "P(k) is true for some k ≥ 1", ["P(k + 1) is true", "P(n) is true for all n", "P(1) is false"]),
        ("What do you have to prove in the inductive step?", "P(k) → P(k + 1)", ["P(k + 1) → P(k)", "P(1) → P(k)", "P(k) for every k"]),
        ("What is the base case for this claim?", "Check n = 1: both sides equal \(f.closed(1))", ["Check n = 0: both sides equal 0", "Assume it holds for n = k", "Check n = k + 1"]),
    ]
    let qq = questions.randomElement()!
    return mc(.induction, "\(claim)\n\n\(qq.0)", right: qq.1, wrong: qq.2, steps: steps)
}

// MARK: - Unit 3: Sets, functions, sums

func randSubset(_ u: [Int], _ size: Int) -> [Int] { Array(u.shuffled().prefix(size)).sorted() }

func generateSets() -> Problem {
    let u = Array(1...10)
    let a = randSubset(u, rint(3...6)), b = randSubset(u, rint(3...6))
    let A = Set(a), B = Set(b), U = Set(u)
    let ops: [(String, Set<Int>, String)] = [
        ("A ∪ B", A.union(B), "∪ = in A OR B (or both). Combine and drop repeats."),
        ("A ∩ B", A.intersection(B), "∩ = in BOTH A and B."),
        ("A − B", A.subtracting(B), "A − B = in A but NOT in B."),
        ("B − A", B.subtracting(A), "B − A = in B but NOT in A."),
        ("A ⊕ B", A.symmetricDifference(B), "A ⊕ B (symmetric difference) = in exactly one of them: (A ∪ B) − (A ∩ B)."),
        ("Aᶜ", U.subtracting(A), "Aᶜ (complement) = everything in U that is not in A."),
        ("(A ∪ B)ᶜ", U.subtracting(A.union(B)), "First A ∪ B, then take everything in U that's left. Same as Aᶜ ∩ Bᶜ (De Morgan)."),
        ("A ∩ Bᶜ", A.subtracting(B), "Bᶜ is everything not in B; intersect with A. This is the same set as A − B."),
    ]
    let o = ops.randomElement()!
    let r = Array(o.1).sorted()
    return numProblem(.sets, "U = \(setStr(u))\nA = \(setStr(a))\nB = \(setStr(b))\n\nFind  |\(o.0)|", Double(r.count), shown: "\(o.0) = \(setStr(r)), so |\(o.0)| = \(r.count)",
                      ask: "|\(o.0)| =", steps: [o.2, "\(o.0) = \(setStr(r))", "|S| means how many elements: \(r.count)."])
}

func generateSetSize() -> Problem {
    switch rint(0...3) {
    case 0:
        let n = rint(2...6)
        let s = Array(["a", "b", "c", "d", "e", "f"].prefix(n))
        let wantSub = coin()
        if wantSub {
            return numProblem(.setSize, "S = {\(s.joined(separator: ", "))}\n\nHow many elements does the power set P(S) have?", Double(ipow(2, n)), shown: "2^\(n) = \(ipow(2, n))",
                              ask: "|P(S)| =", steps: ["P(S) is the set of ALL subsets of S, including ∅ and S itself.", "Each element is either in a subset or not: 2 choices, \(n) times.", "|P(S)| = 2^|S| = 2^\(n) = \(ipow(2, n))."])
        }
        let m = rint(2...4)
        return numProblem(.setSize, "|A| = \(n), |B| = \(m)\n\nHow many elements are in A × B?  And then in P(A × B)?\n(Type |A × B|.)", Double(n * m), shown: "\(n * m)  (and |P(A × B)| = 2^\(n * m))",
                          ask: "|A × B| =", steps: ["A × B is all ordered pairs (a, b).", "\(n) choices for a times \(m) for b: |A × B| = \(n * m).", "Bonus: its power set has 2^\(n * m) elements."])
    case 1:
        let total = rint(40...80), f = rint(12...30), e = rint(10...28), both = rint(3...min(f, e) - 2)
        let neither = total - (f + e - both)
        return numProblem(.setSize, "In a class of \(total) students, \(f) take French, \(e) take Econ, and \(both) take both.\n\nHow many take neither?", Double(neither), shown: "\(neither)",
                          ask: "neither =", steps: ["Inclusion–exclusion: |F ∪ E| = |F| + |E| − |F ∩ E|.", "= \(f) + \(e) − \(both) = \(f + e - both). (Subtract both, or they're counted twice.)", "Neither = total − |F ∪ E| = \(total) − \(f + e - both) = \(neither)."])
    case 2:
        let a = rint(20...40), b = rint(20...40), c = rint(20...40)
        let ab = rint(5...10), ac = rint(5...10), bc = rint(5...10), abc = rint(1...4)
        let u = a + b + c - ab - ac - bc + abc
        return numProblem(.setSize, "|A| = \(a), |B| = \(b), |C| = \(c)\n|A ∩ B| = \(ab), |A ∩ C| = \(ac), |B ∩ C| = \(bc)\n|A ∩ B ∩ C| = \(abc)\n\nFind |A ∪ B ∪ C|", Double(u), shown: "\(u)",
                          ask: "|A ∪ B ∪ C| =", steps: ["Three-set inclusion–exclusion: add singles, subtract pairs, add back the triple.", "\(a) + \(b) + \(c) = \(a + b + c)", "− (\(ab) + \(ac) + \(bc)) = −\(ab + ac + bc)", "+ \(abc)", "= \(u)"])
    default:
        let n = rint(3...6), k = rint(1...n - 1)
        return numProblem(.setSize, "S has \(n) elements.\nHow many subsets of S have exactly \(k) elements?", Double(choose(n, k)), shown: "C(\(n), \(k)) = \(choose(n, k))",
                          ask: "subsets =", steps: ["Picking which \(k) elements go in, order doesn't matter: C(n, k).", "C(\(n), \(k)) = \(n)! / (\(k)!·\(n - k)!) = \(choose(n, k))."])
    }
}

func generateFunctions() -> Problem {
    switch rint(0...3) {
    case 0:
        let dom = ["a", "b", "c", "d"]
        let kind = rint(0...3)
        var co: [Int]
        var img: [Int]
        switch kind {
        case 0: co = [1, 2, 3, 4]; img = co.shuffled()                         // bijective
        case 1: co = [1, 2, 3, 4, 5]; img = Array(co.shuffled().prefix(4))     // one-to-one, not onto
        case 2: co = [1, 2, 3]; img = (co + [co.randomElement()!]).shuffled()  // onto, not one-to-one
        default:
            co = [1, 2, 3, 4]
            let x = co.randomElement()!
            img = ([x, x] + Array(co.filter { $0 != x }.shuffled().prefix(2))).shuffled()
        }
        let map = zip(dom, img).map { "f(\($0)) = \($1)" }.joined(separator: ",  ")
        let inj = Set(img).count == img.count
        let sur = Set(img) == Set(co)
        let right = inj && sur ? "Bijective (both)" : inj ? "One-to-one only" : sur ? "Onto only" : "Neither"
        let dupe = img.first { v in img.filter { $0 == v }.count > 1 }
        let missing = co.filter { !img.contains($0) }
        return mc(.functions, "f: {a, b, c, d} → \(setStr(co))\n\(map)\n\nIs f one-to-one, onto, both, or neither?", right: right,
                  wrong: ["Bijective (both)", "One-to-one only", "Onto only", "Neither"], steps: [
            "One-to-one (injective): no two inputs share an output.",
            inj ? "All four outputs are different, so one-to-one ✓." : "Output \(dupe!) is hit twice, so NOT one-to-one.",
            "Onto (surjective): every element of the codomain \(setStr(co)) gets hit.",
            sur ? "Every value is hit, so onto ✓." : "\(setStr(missing)) never gets hit, so NOT onto.",
            "Shortcut: with finite sets, |domain| < |codomain| can't be onto, and |domain| > |codomain| can't be one-to-one.",
        ])
    case 1:
        let a = rint(2...5), b = rint(-5...5), c = rint(-4...4), k = rint(-3...3)
        let fg = coin()
        let g = k * k + c, f = a * k + b
        let v = fg ? a * g + b : f * f + c
        let fS = "f(x) = \(a)x \(sgn(b))", gS = "g(x) = x² \(sgn(c))"
        return numProblem(.functions, "\(fS)\n\(gS)\n\nFind (\(fg ? "f ∘ g" : "g ∘ f"))(\(k))", Double(v), shown: "\(v)", ask: "(\(fg ? "f ∘ g" : "g ∘ f"))(\(k)) =", steps: [
            "(f ∘ g)(x) means f(g(x)): do the RIGHT one first.",
            fg ? "Inside: g(\(k)) = (\(k))² \(sgn(c)) = \(g)" : "Inside: f(\(k)) = \(a)(\(k)) \(sgn(b)) = \(f)",
            fg ? "Outside: f(\(g)) = \(a)(\(g)) \(sgn(b)) = \(v)" : "Outside: g(\(f)) = (\(f))² \(sgn(c)) = \(v)",
        ])
    case 2:
        let x = Double(rint(-40...40)) / 10 + 0.05, y = Double(rint(-40...40)) / 10 + 0.3
        let fx = Int(floor(x)), cy = Int(ceil(y))
        return numProblem(.functions, "Compute  ⌊\(dec(x))⌋ + ⌈\(dec(y))⌉", Double(fx + cy), shown: "\(fx) + \(cy) = \(fx + cy)", ask: "=", steps: [
            "⌊x⌋ (floor) = the largest integer ≤ x: round DOWN on the number line.",
            "⌈x⌉ (ceiling) = the smallest integer ≥ x: round UP.",
            "Careful with negatives: ⌊−2.3⌋ = −3 (down means more negative).",
            "⌊\(dec(x))⌋ = \(fx),  ⌈\(dec(y))⌉ = \(cy)",
            "Sum = \(fx + cy)",
        ])
    default:
        let a = [2, 3, 4, 5, -2, -3].randomElement()!, b = rint(-9...9), xv = rint(-4...6)
        let k = a * xv + b
        return numProblem(.functions, "f(x) = \(a)x \(sgn(b)) is a bijection from ℝ to ℝ.\nFind f⁻¹(\(k))", Double(xv), shown: "\(xv)", ask: "f⁻¹(\(k)) =", steps: [
            "f⁻¹(\(k)) is the x that f sends to \(k). Solve f(x) = \(k).",
            "\(a)x \(sgn(b)) = \(k)",
            "\(a)x = \(k - b)",
            "x = \(k - b)/\(neg(a)) = \(xv)",
        ])
    }
}

func generateSequences() -> Problem {
    switch rint(0...3) {
    case 0:
        let a = rint(-5...9), d = [2, 3, 4, 5, -2, -3, 7].randomElement()!, n = rint(8...20)
        let s = n * (2 * a + (n - 1) * d) / 2
        return numProblem(.sequences, "Arithmetic sequence: a₁ = \(a), common difference d = \(d)\n\nFind the sum of the first \(n) terms.", Double(s), shown: "\(s)", ask: "S_\(n) =", steps: [
            "nth term: a_n = a₁ + (n − 1)d, so a_\(n) = \(a) + \(n - 1)(\(d)) = \(a + (n - 1) * d).",
            "Sum = (number of terms) × (first + last)/2.",
            "S_\(n) = \(n)(\(a) + \(a + (n - 1) * d))/2 = \(s)",
        ])
    case 1:
        let a = rint(1...5), r = [2, 3, -2].randomElement()!, n = rint(4...7)
        let s = a * (ipow(r, n + 1) - 1) / (r - 1)
        return numProblem(.sequences, "Compute  Σ_(j=0)^(\(n))  \(a)·(\(r))^j", Double(s), shown: "\(s)", ask: "sum =", steps: [
            "Geometric sum: Σ_(j=0)^n a·r^j = a(r^(n+1) − 1)/(r − 1)   (r ≠ 1).",
            "Here a = \(a), r = \(r), n = \(n): there are \(n + 1) terms (j = 0 counts).",
            "\(a)((\(r))^(\(n + 1)) − 1)/(\(r) − 1) = \(a)(\(ipow(r, n + 1)) − 1)/\(r - 1) = \(s)",
        ])
    case 2:
        let c = rint(2...6), d = rint(-5...5), n = rint(10...30)
        let s = c * n * (n + 1) / 2 + d * n
        return numProblem(.sequences, "Compute  Σ_(i=1)^(\(n))  (\(c)i \(sgn(d)))", Double(s), shown: "\(s)", ask: "sum =", steps: [
            "Split it: Σ(\(c)i \(sgn(d))) = \(c)·Σi + Σ(\(d)).",
            "Σ_(i=1)^n i = n(n + 1)/2 = \(n)(\(n + 1))/2 = \(n * (n + 1) / 2).",
            "Σ of a constant \(d), \(n) times = \(d * n).",
            "\(c)(\(n * (n + 1) / 2)) \(sgn(d * n)) = \(s)",
        ])
    default:
        let c = rint(2...3), d = [-3, -2, -1, 1, 2, 3, 4].randomElement()!, a0 = rint(1...4), n = rint(4...5)
        var vals = [a0]
        for _ in 0..<n { vals.append(c * vals.last! + d) }
        var steps = ["Recurrence: each term is built from the one before. Just iterate."]
        for i in 1...n { steps.append("a_\(i) = \(c)·a_\(i - 1) \(sgn(d)) = \(c)(\(vals[i - 1])) \(sgn(d)) = \(vals[i])") }
        return numProblem(.sequences, "a_n = \(c)·a_(n−1) \(sgn(d)),   a₀ = \(a0)\n\nFind a_\(n)", Double(vals[n]), shown: "\(vals[n])", ask: "a_\(n) =", steps: steps)
    }
}

// MARK: - Unit 4: Number theory

func generateModArith() -> Problem {
    switch rint(0...3) {
    case 0:
        let m = rint(3...13), a = rint(-60...99)
        let q = Int(floor(Double(a) / Double(m))), r = md(a, m)
        return numProblem(.modArith, "Find  \(neg(a)) mod \(m)", Double(r), shown: "\(r)", ask: "\(neg(a)) mod \(m) =", steps: [
            "Division algorithm: a = d·q + r with 0 ≤ r < d. \"a mod d\" is r.",
            a < 0 ? "For a negative a, q is rounded DOWN (more negative) so r stays ≥ 0." : "q = ⌊\(a)/\(m)⌋ = \(q).",
            "\(neg(a)) = \(m)·(\(q)) + \(r)",
            "So \(neg(a)) mod \(m) = \(r).",
        ])
    case 1:
        let m = rint(5...12), a = rint(20...200), b = rint(20...200), c = rint(0...50)
        let ra = a % m, rb = b % m, rc = c % m
        let r = (ra * rb + rc) % m
        return numProblem(.modArith, "Find  (\(a)·\(b) + \(c)) mod \(m)", Double(r), shown: "\(r)", ask: "=", steps: [
            "Reduce first, multiply later. Mod works with + and ×.",
            "\(a) mod \(m) = \(ra),  \(b) mod \(m) = \(rb),  \(c) mod \(m) = \(rc)",
            "(\(ra)·\(rb) + \(rc)) mod \(m) = \(ra * rb + rc) mod \(m) = \(r)",
        ])
    case 2:
        let m = [5, 7, 11, 13, 9].randomElement()!, a = rint(2...m - 1), k = [8, 16, 13, 10, 20].randomElement()!
        var steps = ["Successive squaring: compute a^1, a^2, a^4, a^8, … mod \(m), squaring each time."]
        var p = 1, pw = a % m, e = k
        var bits: [Int] = []
        var powers: [(Int, Int)] = []
        var cur = 1
        while cur <= k { powers.append((cur, pw)); steps.append("\(a)^\(cur) ≡ \(pw)  (mod \(m))"); pw = pw * pw % m; cur *= 2 }
        for (exp, val) in powers.reversed() where e >= exp { e -= exp; bits.append(exp); p = p * val % m }
        steps.append("\(k) = " + bits.sorted().map { "\($0)" }.joined(separator: " + ") + ", so multiply those powers and reduce: \(p).")
        return numProblem(.modArith, "Find  \(a)^\(k) mod \(m)", Double(p), shown: "\(p)", ask: "\(a)^\(k) mod \(m) =", steps: steps)
    default:
        let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        let s = rint(0...6), n = rint(30...500)
        let r = n % 7
        let right = days[(s + r) % 7]
        return mc(.modArith, "Today is \(days[s]). What day is it \(n) days from now?", right: right,
                  wrong: days.filter { $0 != right }.shuffled(), steps: [
            "The week repeats every 7 days, so only \(n) mod 7 matters.",
            "\(n) = 7·\(n / 7) + \(r)",
            "\(r) days after \(days[s]) is \(right).",
        ])
    }
}

func euclidSteps(_ a: Int, _ b: Int) -> ([String], Int) {
    var x = max(a, b), y = min(a, b)
    var steps: [String] = []
    while y != 0 {
        steps.append("\(x) = \(y)·\(x / y) + \(x % y)")
        (x, y) = (y, x % y)
    }
    steps.append("The last nonzero remainder is the gcd: \(x).")
    return (steps, x)
}

func generateGcd() -> Problem {
    switch rint(0...2) {
    case 0:
        let g = rint(2...15)
        var x = rint(2...20), y = rint(2...20)
        while gcd(x, y) != 1 || x == y { x = rint(2...20); y = rint(2...20) }
        let a = g * x, b = g * y
        var (steps, d) = euclidSteps(a, b)
        steps.insert("Euclidean algorithm: divide, keep the remainder, repeat with (divisor, remainder).", at: 0)
        return numProblem(.gcdTopic, "Find gcd(\(a), \(b)) using the Euclidean algorithm.", Double(d), shown: "\(d)", ask: "gcd =", steps: steps)
    case 1:
        let g = rint(2...9)
        var x = rint(2...12), y = rint(2...12)
        while gcd(x, y) != 1 || x == y { x = rint(2...12); y = rint(2...12) }
        let a = g * x, b = g * y
        let l = a * b / g
        return numProblem(.gcdTopic, "Find lcm(\(a), \(b))", Double(l), shown: "\(l)", ask: "lcm =", steps: [
            "Use gcd·lcm = a·b.",
            "gcd(\(a), \(b)) = \(g)",
            "lcm = \(a)·\(b)/\(g) = \(a * b)/\(g) = \(l)",
        ])
    default:
        let e2 = rint(0...4), e3 = rint(0...3), e5 = rint(0...2), e7 = rint(0...1)
        let n = ipow(2, e2) * ipow(3, e3) * ipow(5, e5) * ipow(7, e7)
        if n < 6 { return generateGcd() }
        let pf = [(2, e2), (3, e3), (5, e5), (7, e7)].filter { $0.1 > 0 }
        let fs = pf.map { $0.1 == 1 ? "\($0.0)" : "\($0.0)^\($0.1)" }.joined(separator: " · ")
        let count = pf.map { $0.1 + 1 }.reduce(1, *)
        return numProblem(.gcdTopic, "How many positive divisors does \(n) have?", Double(count), shown: "\(count)", ask: "divisors =", steps: [
            "Prime factorize first (divide by 2, then 3, then 5, …).",
            "\(n) = \(fs)",
            "A divisor picks an exponent for each prime from 0 up to its power: (e + 1) choices each.",
            pf.map { "(\($0.1) + 1)" }.joined(separator: "·") + " = \(count)",
        ])
    }
}

// Inverse of a mod m by the extended Euclidean algorithm, with every line written out.
func inverseSteps(_ a: Int, _ m: Int) -> ([String], Int) {
    var steps = ["Track each remainder as (something)·\(m) + (something)·\(a)."]
    var r0 = m, s0 = 0, r1 = a % m, s1 = 1
    steps.append("\(m) = 1·\(m) + 0·\(a)")
    steps.append("\(r1) = 0·\(m) + 1·\(a)")
    var t0 = 1, t1 = 0
    while r1 > 1 {
        let q = r0 / r1
        let r2 = r0 - q * r1, s2 = s0 - q * s1, t2 = t0 - q * t1
        steps.append("\(r2) = \(r0) − \(q)·\(r1)  →  \(r2) = \(neg(t2))·\(m) + \(neg(s2))·\(a)")
        (r0, s0, t0, r1, s1, t1) = (r1, s1, t1, r2, s2, t2)
    }
    let inv = md(s1, m)
    steps.append("Reading the \(a)-coefficient: \(a)·(\(neg(s1))) ≡ 1 (mod \(m)).")
    if s1 < 0 { steps.append("Make it positive: \(neg(s1)) + \(m) = \(inv).") }
    steps.append("Check: \(a)·\(inv) = \(a * inv) = \(m)·\(a * inv / m) + 1 ✓")
    return (steps, inv)
}

func generateModInverse() -> Problem {
    let m = [7, 11, 13, 17, 19, 23, 26, 15, 21].randomElement()!
    var a = rint(2...m - 1)
    while gcd(a, m) != 1 { a = rint(2...m - 1) }
    let (steps, inv) = inverseSteps(a, m)
    if coin() {
        return numProblem(.modInverse, "Find the inverse of \(a) modulo \(m)\n(the x in 0…\(m - 1) with \(a)x ≡ 1 (mod \(m)))", Double(inv), shown: "\(inv)", ask: "\(a)⁻¹ mod \(m) =",
                          steps: ["An inverse exists because gcd(\(a), \(m)) = 1."] + steps)
    }
    let b = rint(1...m - 1)
    let x = md(inv * b, m)
    return numProblem(.modInverse, "Solve  \(a)x ≡ \(b)  (mod \(m))\nGive x in 0…\(m - 1).", Double(x), shown: "x = \(x)", ask: "x =",
                      steps: ["Multiply both sides by the inverse of \(a). Find it first:"] + steps + [
                        "x ≡ \(inv)·\(b) = \(inv * b) ≡ \(x)  (mod \(m))",
                        "Check: \(a)·\(x) = \(a * x) ≡ \(a * x % m) (mod \(m)) ✓"])
}

func generateBases() -> Problem {
    switch rint(0...2) {
    case 0:
        let n = rint(10...200)
        var steps = ["Divide by 2 over and over. The remainders, read from the bottom up, are the binary digits."]
        var x = n
        var digits: [Int] = []
        while x > 0 { steps.append("\(x) ÷ 2 = \(x / 2) remainder \(x % 2)"); digits.append(x % 2); x /= 2 }
        let bin = digits.reversed().map { "\($0)" }.joined()
        steps.append("Read up: \(bin)")
        return numProblem(.bases, "Write \(n) in binary (base 2).", Double(bin) ?? 0, shown: "(\(bin))₂", ask: "binary =", steps: steps)
    case 1:
        let n = rint(10...255)
        let bin = String(n, radix: 2)
        let ds = Array(bin).map { Int(String($0))! }
        let k = ds.count
        let terms = ds.enumerated().compactMap { i, d in d == 1 ? "2^\(k - 1 - i)" : nil }
        return numProblem(.bases, "Convert (\(bin))₂ to decimal.", Double(n), shown: "\(n)", ask: "decimal =", steps: [
            "Each place is a power of 2, starting at 2^0 on the right.",
            "The 1's are at: " + terms.joined(separator: " + "),
            ds.enumerated().compactMap { i, d in d == 1 ? "\(ipow(2, k - 1 - i))" : nil }.joined(separator: " + ") + " = \(n)",
        ])
    default:
        let base = [3, 8, 5].randomElement()!, n = rint(20...300)
        let s = String(n, radix: base)
        var steps = ["Same method as binary but divide by \(base); read remainders bottom up."]
        var x = n
        while x > 0 { steps.append("\(x) ÷ \(base) = \(x / base) remainder \(x % base)"); x /= base }
        steps.append("Read up: \(s)")
        return numProblem(.bases, "Write \(n) in base \(base).", Double(s) ?? 0, shown: "(\(s))_\(base)", ask: "base \(base) =", steps: steps)
    }
}

// MARK: - Unit 5: Counting

func generateCountRules() -> Problem {
    switch rint(0...3) {
    case 0:
        let l = rint(2...3), d = rint(2...4)
        let v = ipow(26, l) * ipow(10, d)
        return numProblem(.countRules, "A license plate is \(l) letters followed by \(d) digits (repeats allowed).\nHow many plates are possible?", Double(v), shown: num(v), ask: "plates =", steps: [
            "Product rule: a sequence of independent choices → MULTIPLY.",
            "Letters: 26 each, \(l) times = 26^\(l) = \(num(ipow(26, l))).",
            "Digits: 10 each, \(d) times = 10^\(d) = \(num(ipow(10, d))).",
            "Total = \(num(ipow(26, l)))·\(num(ipow(10, d))) = \(num(v))",
        ])
    case 1:
        let a = rint(5...15), b = rint(3...12), c = rint(2...9)
        return numProblem(.countRules, "You'll take ONE elective: \(a) econ options, \(b) philosophy options, or \(c) French options (no overlap).\nHow many choices?", Double(a + b + c), shown: "\(a + b + c)", ask: "choices =", steps: [
            "Sum rule: you do ONE thing from separate (disjoint) groups → ADD.",
            "\(a) + \(b) + \(c) = \(a + b + c)",
            "Tell: \"and then\" = multiply, \"or\" (one of separate groups) = add.",
        ])
    case 2:
        let n = [100, 200, 500, 1000].randomElement()!
        var a = rint(2...7), b = rint(3...11)
        while a == b { a = rint(2...7); b = rint(3...11) }
        let l = a * b / gcd(a, b)
        let v = n / a + n / b - n / l
        return numProblem(.countRules, "How many integers from 1 to \(n) are divisible by \(a) or \(b)?", Double(v), shown: "\(v)", ask: "count =", steps: [
            "Multiples of d up to N: ⌊N/d⌋.",
            "By \(a): ⌊\(n)/\(a)⌋ = \(n / a).  By \(b): ⌊\(n)/\(b)⌋ = \(n / b).",
            "Both = divisible by lcm(\(a), \(b)) = \(l): ⌊\(n)/\(l)⌋ = \(n / l).",
            "Inclusion–exclusion: \(n / a) + \(n / b) − \(n / l) = \(v)",
        ])
    default:
        let n = rint(6...10)
        let v = ipow(2, n - 1) + ipow(2, n - 2) - ipow(2, n - 3)
        return numProblem(.countRules, "How many bit strings of length \(n) start with 1 OR end with 00?", Double(v), shown: num(v), ask: "count =", steps: [
            "Start with 1: the other \(n - 1) bits are free: 2^\(n - 1) = \(ipow(2, n - 1)).",
            "End with 00: the other \(n - 2) bits are free: 2^\(n - 2) = \(ipow(2, n - 2)).",
            "Both (start 1 AND end 00): \(n - 3) free bits: 2^\(n - 3) = \(ipow(2, n - 3)).",
            "Inclusion–exclusion: \(ipow(2, n - 1)) + \(ipow(2, n - 2)) − \(ipow(2, n - 3)) = \(v)",
        ])
    }
}

let words = ["BANANA", "LETTER", "PEPPER", "STATS", "LEVEL", "COFFEE", "ERROR", "MISSISSIPPI", "PARALLEL", "BOOKKEEPER", "SUCCESS", "TOMORROW"]

func generatePermComb() -> Problem {
    switch rint(0...4) {
    case 0:
        let n = rint(8...20), k = rint(2...4)
        let roles = ["president", "VP", "treasurer", "secretary"].prefix(k).joined(separator: ", ")
        return numProblem(.permComb, "A club of \(n) people picks a \(roles) (different people).\nHow many ways?", Double(perm(n, k)), shown: num(perm(n, k)), ask: "ways =", steps: [
            "Different jobs → ORDER MATTERS → permutation P(n, k) = n!/(n − k)!.",
            (0..<k).map { "\(n - $0)" }.joined(separator: "·") + " = \(num(perm(n, k)))",
        ])
    case 1:
        let n = rint(8...20), k = rint(2...5)
        return numProblem(.permComb, "From \(n) people, how many ways to choose a committee of \(k)?", Double(choose(n, k)), shown: num(choose(n, k)), ask: "ways =", steps: [
            "Committee = no roles → order DOESN'T matter → C(n, k) = n!/(k!(n − k)!).",
            "C(\(n), \(k)) = P(\(n), \(k))/\(k)! = \(num(perm(n, k)))/\(fact(k)) = \(num(choose(n, k)))",
            "Dividing by \(k)! removes the \(k)! orders of the same group.",
        ])
    case 2:
        let w = rint(4...8), m = rint(4...8), k = rint(3...5), j = rint(1...min(k - 1, w))
        let v = choose(w, j) * choose(m, k - j)
        return numProblem(.permComb, "A group has \(w) women and \(m) men. Choose a committee of \(k) with EXACTLY \(j) women.", Double(v), shown: num(v), ask: "ways =", steps: [
            "Split into two choices and multiply (product rule).",
            "Women: C(\(w), \(j)) = \(choose(w, j)).  Men: C(\(m), \(k - j)) = \(choose(m, k - j)).",
            "\(choose(w, j))·\(choose(m, k - j)) = \(num(v))",
        ])
    case 3:
        let word = words.randomElement()!
        var counts: [Character: Int] = [:]
        for ch in word { counts[ch, default: 0] += 1 }
        let reps = counts.filter { $0.value > 1 }.sorted { $0.key < $1.key }
        let v = reps.reduce(fact(word.count)) { $0 / fact($1.value) }
        return numProblem(.permComb, "How many different arrangements of the letters of \(word)?", Double(v), shown: num(v), ask: "arrangements =", steps: [
            "\(word.count) letters → \(word.count)! if all were different.",
            "Repeats: " + reps.map { "\($0.key) ×\($0.value)" }.joined(separator: ", ") + ". Swapping identical letters gives the same word, so divide.",
            "\(word.count)!/(" + reps.map { "\($0.value)!" }.joined(separator: "·") + ") = \(num(fact(word.count)))/\(reps.map { fact($0.value) }.reduce(1, *)) = \(num(v))",
        ])
    default:
        let n = rint(9...14), m = rint(2...4), k = rint(3...5)
        let v = choose(n, k) - choose(n - m, k)
        return numProblem(.permComb, "From \(n) students (\(m) of them seniors), choose \(k).\nHow many groups include AT LEAST one senior?", Double(v), shown: num(v), ask: "groups =", steps: [
            "\"At least one\" → count everything, subtract the groups with NONE.",
            "All groups: C(\(n), \(k)) = \(num(choose(n, k))).",
            "No seniors: choose all \(k) from the \(n - m) others: C(\(n - m), \(k)) = \(num(choose(n - m, k))).",
            "\(num(choose(n, k))) − \(num(choose(n - m, k))) = \(num(v))",
        ])
    }
}

func generateStarsBars() -> Problem {
    switch rint(0...2) {
    case 0:
        let n = rint(5...14), k = rint(3...5)
        let v = choose(n + k - 1, k - 1)
        return numProblem(.starsBars, "How many ways to pick \(n) bagels from \(k) kinds (repeats allowed, order doesn't matter)?", Double(v), shown: num(v), ask: "ways =", steps: [
            "Stars and bars: \(n) stars (bagels) split by \(k - 1) bars into \(k) kinds.",
            "Arrange \(n) stars and \(k - 1) bars: choose where the bars go among \(n + k - 1) spots.",
            "C(\(n) + \(k) − 1, \(k) − 1) = C(\(n + k - 1), \(k - 1)) = \(num(v))",
        ])
    case 1:
        let n = rint(7...15), k = rint(3...4)
        let v = choose(n - 1, k - 1)
        let xs = (1...k).map { "x_\($0)" }.joined(separator: " + ")
        return numProblem(.starsBars, "How many solutions to  \(xs) = \(n)  with every x_i ≥ 1 (integers)?", Double(v), shown: num(v), ask: "solutions =", steps: [
            "Give each variable its required 1 first: that uses \(k), leaving \(n - k) to hand out freely.",
            "Now y_i ≥ 0 summing to \(n - k): C(\(n - k) + \(k) − 1, \(k) − 1).",
            "C(\(n - 1), \(k - 1)) = \(num(v))",
        ])
    default:
        let n = rint(8...15), k = rint(3...4), m = rint(2...4)
        let rest = n - m
        let v = choose(rest + k - 1, k - 1)
        let xs = (1...k).map { "x_\($0)" }.joined(separator: " + ")
        return numProblem(.starsBars, "How many nonnegative integer solutions to  \(xs) = \(n)  with x₁ ≥ \(m)?", Double(v), shown: num(v), ask: "solutions =", steps: [
            "Pre-pay the lower bound: put \(m) into x₁. That leaves \(rest).",
            "Now all variables ≥ 0 summing to \(rest): C(\(rest) + \(k) − 1, \(k) − 1).",
            "C(\(rest + k - 1), \(k - 1)) = \(num(v))",
        ])
    }
}

func generatePigeonhole() -> Problem {
    switch rint(0...3) {
    case 0:
        let c = rint(3...6), k = rint(2...5)
        let v = (k - 1) * c + 1
        return numProblem(.pigeonhole, "A drawer has socks in \(c) colors. How many must you pull (in the dark) to GUARANTEE \(k) of the same color?", Double(v), shown: "\(v)", ask: "socks =", steps: [
            "Worst case: you spread out as long as possible: \(k - 1) of each color.",
            "That's \(k - 1)·\(c) = \(c * (k - 1)) socks with no \(k) matching.",
            "One more forces a \(k)th of some color: \(c * (k - 1)) + 1 = \(v).",
        ])
    case 1:
        let n = rint(30...200)
        let v = (n + 11) / 12
        return numProblem(.pigeonhole, "Among \(n) people, at least how many must share a birth month (guaranteed)?", Double(v), shown: "\(v)", ask: "at least", steps: [
            "Generalized pigeonhole: N objects in k boxes → some box has at least ⌈N/k⌉.",
            "⌈\(n)/12⌉ = ⌈\(dec(Double(n) / 12))⌉ = \(v)",
        ])
    case 2:
        let k = rint(3...8)
        let v = 12 * (k - 1) + 1
        return numProblem(.pigeonhole, "What's the minimum number of people needed to guarantee that \(k) share a birth month?", Double(v), shown: "\(v)", ask: "people =", steps: [
            "Worst case: \(k - 1) people in every month: 12·\(k - 1) = \(12 * (k - 1)).",
            "One more person forces a month with \(k): \(v).",
        ])
    default:
        let n = rint(4...12)
        return numProblem(.pigeonhole, "How many numbers must you pick from {1, 2, …, \(2 * n)} to guarantee two of them add up to \(2 * n + 1)?", Double(n + 1), shown: "\(n + 1)", ask: "numbers =", steps: [
            "Make the boxes: pairs that sum to \(2 * n + 1): {1, \(2 * n)}, {2, \(2 * n - 1)}, …, {\(n), \(n + 1)}. That's \(n) pairs.",
            "You can take one from each pair (\(n) numbers) with no match.",
            "The (\(n + 1))th pick must land in a pair you already used: \(n + 1).",
        ])
    }
}

func generateBinomial() -> Problem {
    if rint(0...2) == 0 {
        let n = rint(5...10), k = rint(2...n - 2)
        return numProblem(.binomial, "What is the coefficient of x^(\(k))y^(\(n - k)) in (x + y)^\(n)?", Double(choose(n, k)), shown: "\(choose(n, k))", ask: "coefficient =", steps: [
            "Binomial theorem: (x + y)^n = Σ C(n, k) x^k y^(n−k).",
            "C(\(n), \(k)) = \(choose(n, k))",
        ])
    }
    let n = rint(4...8), k = rint(1...n - 1), a = [1, 2, 3, -1, -2].randomElement()!, b = [1, 2, 3, -1, -2, -3].randomElement()!
    let v = choose(n, k) * ipow(a, k) * ipow(b, n - k)
    let ax = a == 1 ? "x" : a == -1 ? "−x" : "\(neg(a))x"
    return numProblem(.binomial, "Find the coefficient of x^\(k) in (\(ax) \(sgn(b)))^\(n)", Double(v), shown: num(v), ask: "coefficient =", steps: [
        "General term: C(n, k)(\(ax))^k(\(b))^(n−k). The x^\(k) term uses k = \(k).",
        "C(\(n), \(k)) = \(choose(n, k))",
        "(\(neg(a)))^\(k) = \(neg(ipow(a, k))),   (\(neg(b)))^\(n - k) = \(neg(ipow(b, n - k)))",
        "\(choose(n, k))·(\(neg(ipow(a, k))))·(\(neg(ipow(b, n - k)))) = \(num(v))",
        "Watch the signs: a negative number to an odd power stays negative.",
    ])
}

// MARK: - Unit 6: Probability

func generateProbability() -> Problem {
    switch rint(0...4) {
    case 0:
        let s = rint(2...12)
        let ways = (1...6).flatMap { a in (1...6).map { (a, $0) } }.filter { $0.0 + $0.1 == s }
        return numProblem(.probability, "Roll two fair dice. What's P(sum = \(s))?", Double(ways.count) / 36, shown: frac(ways.count, 36), ask: "P =", steps: [
            "Equally likely outcomes: 6·6 = 36 ordered pairs.",
            "Pairs that sum to \(s): " + ways.map { "(\($0.0),\($0.1))" }.joined(separator: " "),
            frac(ways.count, 36) == "\(ways.count)/36" ? "\(ways.count)/36" : "\(ways.count)/36 = \(frac(ways.count, 36))",
        ])
    case 1:
        let n = rint(4...8), k = rint(1...n - 1)
        let num_ = choose(n, k), den = ipow(2, n)
        return numProblem(.probability, "Flip a fair coin \(n) times. P(exactly \(k) heads)?", Double(num_) / Double(den), shown: frac(num_, den), ask: "P =", steps: [
            "Total outcomes: 2^\(n) = \(den).",
            "Choose which \(k) flips are heads: C(\(n), \(k)) = \(num_).",
            "\(num_)/\(den) = \(frac(num_, den))",
        ])
    case 2:
        let n = rint(2...5)
        let p = 1 - pow(5.0 / 6.0, Double(n))
        return numProblem(.probability, "Roll a die \(n) times. P(at least one 6)?", p, shown: "1 − (5/6)^\(n) = \(frac(ipow(6, n) - ipow(5, n), ipow(6, n))) ≈ \(dec(p))", ask: "P =", steps: [
            "\"At least one\" → use the complement: 1 − P(none).",
            "P(no 6 on one roll) = 5/6; independent rolls multiply: (5/6)^\(n).",
            "1 − (5/6)^\(n) = 1 − \(ipow(5, n))/\(ipow(6, n)) = \(frac(ipow(6, n) - ipow(5, n), ipow(6, n))) ≈ \(dec(p))",
        ])
    case 3:
        let k = rint(2...3)
        let n_ = choose(13, k), d = choose(52, k)
        return numProblem(.probability, "Draw \(k) cards from a 52-card deck (no replacement). P(all hearts)?", Double(n_) / Double(d), shown: "\(frac(n_, d)) ≈ \(dec(Double(n_) / Double(d)))", ask: "P =", steps: [
            "Count hands: C(52, \(k)) = \(num(d)) equally likely.",
            "All hearts: choose \(k) of the 13 hearts: C(13, \(k)) = \(n_).",
            "\(n_)/\(num(d)) = \(frac(n_, d))",
        ])
    default:
        let win = rint(5...20), lose = rint(1...4)
        let ev = Double(win - 5 * lose) / 6
        return numProblem(.probability, "Roll a die. Win $\(win) on a 6, lose $\(lose) otherwise.\nExpected value of one game?", ev, shown: "$\(frac(win - 5 * lose, 6)) ≈ $\(dec(ev))", ask: "E[X] =", steps: [
            "E[X] = Σ value × probability.",
            "(\(win))(1/6) + (−\(lose))(5/6) = (\(win) − \(5 * lose))/6",
            "= \(frac(win - 5 * lose, 6)) ≈ \(dec(ev))" + (ev < 0 ? ". Negative: you lose money on average." : ". Positive: worth playing on average."),
        ])
    }
}

// MARK: - Unit 7: Relations & graphs

func pairs(_ r: [(Int, Int)]) -> String { "{" + r.map { "(\($0.0),\($0.1))" }.joined(separator: ", ") + "}" }

func generateRelations() -> Problem {
    if rint(0...3) == 0 {
        let n = rint(2...4)
        let kind = rint(0...2)
        let (what, e, why): (String, Int, String) = [
            ("relations", n * n, "A relation is any subset of A × A, which has n² = \(n * n) pairs."),
            ("reflexive relations", n * n - n, "The \(n) diagonal pairs (a,a) are forced in; the other n² − n = \(n * n - n) are free."),
            ("symmetric relations", n * (n + 1) / 2, "Decide the diagonal (\(n) pairs) and each pair {a,b} together (\(n * (n - 1) / 2) of them): \(n * (n + 1) / 2) free choices."),
        ][kind]
        return numProblem(.relations, "How many \(what) are there on a set with \(n) elements?", Double(ipow(2, e)), shown: "2^\(e) = \(num(ipow(2, e)))", ask: "count =", steps: [
            why, "Each free pair is in or out: 2 choices each → 2^\(e) = \(num(ipow(2, e))).",
        ])
    }
    let A = [1, 2, 3]
    var r: [(Int, Int)] = []
    let refl = coin()
    for a in A { for b in A {
        if a == b { if refl || Int.random(in: 0..<3) == 0 { r.append((a, b)) } }
        else if Int.random(in: 0..<5) < 2 { r.append((a, b)) }
    } }
    if coin(), let p = r.first(where: { $0.0 != $0.1 }), !r.contains(where: { $0 == (p.1, p.0) }) { r.append((p.1, p.0)) }
    func has(_ a: Int, _ b: Int) -> Bool { r.contains { $0 == (a, b) } }
    let props = ["reflexive", "symmetric", "antisymmetric", "transitive"]
    let which = rint(0...3)
    var value = true
    var steps: [String] = []
    switch which {
    case 0:
        steps.append("Reflexive: (a,a) is in R for EVERY a in {1, 2, 3}.")
        let miss = A.filter { !has($0, $0) }
        value = miss.isEmpty
        steps.append(value ? "(1,1), (2,2), (3,3) are all there ✓" : "Missing (\(miss[0]),\(miss[0])), so not reflexive.")
    case 1:
        steps.append("Symmetric: whenever (a,b) is in R, (b,a) is too.")
        let bad = r.first { !has($0.1, $0.0) }
        value = bad == nil
        steps.append(value ? "Every pair has its flip ✓" : "(\(bad!.0),\(bad!.1)) is in R but (\(bad!.1),\(bad!.0)) is not.")
    case 2:
        steps.append("Antisymmetric: (a,b) and (b,a) both in R only if a = b.")
        let bad = r.first { $0.0 != $0.1 && has($0.1, $0.0) }
        value = bad == nil
        steps.append(value ? "No two different elements point both ways ✓" : "(\(bad!.0),\(bad!.1)) and (\(bad!.1),\(bad!.0)) are both in R with \(bad!.0) ≠ \(bad!.1).")
    default:
        steps.append("Transitive: (a,b) and (b,c) in R ⇒ (a,c) in R. Check every chain.")
        var bad: (Int, Int, Int)? = nil
        for x in r { for y in r where x.1 == y.0 { if !has(x.0, y.1) && bad == nil { bad = (x.0, x.1, y.1) } } }
        value = bad == nil
        steps.append(value ? "Every chain closes up ✓" : "(\(bad!.0),\(bad!.1)) and (\(bad!.1),\(bad!.2)) are in R but (\(bad!.0),\(bad!.2)) is not.")
    }
    steps.append("Note: symmetric and antisymmetric are NOT opposites. A relation can be both, or neither.")
    return tfProblem(.relations, "On A = {1, 2, 3}:\nR = \(pairs(r))\n\nIs R \(props[which])?", value, steps: steps)
}

func generateGraphs() -> Problem {
    switch rint(0...4) {
    case 0:
        var degs = (0..<rint(5...7)).map { _ in rint(1...5) }
        if degs.reduce(0, +) % 2 == 1 { degs[0] += 1 }
        let s = degs.reduce(0, +)
        return numProblem(.graphs, "A graph has vertices with degrees \(degs.map { "\($0)" }.joined(separator: ", ")).\nHow many edges?", Double(s / 2), shown: "\(s / 2)", ask: "edges =", steps: [
            "Handshake theorem: sum of degrees = 2·(edges). Each edge has two ends.",
            "Sum = \(s)",
            "Edges = \(s)/2 = \(s / 2)",
            "Corollary: the number of odd-degree vertices is always even.",
        ])
    case 1:
        if coin() {
            let n = rint(4...12)
            return numProblem(.graphs, "How many edges does the complete graph K_\(n) have?", Double(n * (n - 1) / 2), shown: "\(n * (n - 1) / 2)", ask: "edges =", steps: [
                "Every pair of vertices is joined once: C(n, 2) = n(n − 1)/2.", "\(n)·\(n - 1)/2 = \(n * (n - 1) / 2)",
            ])
        }
        let m = rint(2...6), n = rint(2...7)
        return numProblem(.graphs, "How many edges does the complete bipartite graph K_(\(m),\(n)) have?", Double(m * n), shown: "\(m * n)", ask: "edges =", steps: [
            "Every vertex on the left joins every vertex on the right, nothing inside a side.", "\(m)·\(n) = \(m * n)",
        ])
    case 2:
        let n = rint(5...20)
        if coin() {
            return numProblem(.graphs, "A tree has \(n) vertices. How many edges?", Double(n - 1), shown: "\(n - 1)", ask: "edges =", steps: [
                "A tree is connected with no cycles. It always has exactly n − 1 edges.", "\(n) − 1 = \(n - 1)",
            ])
        }
        let m = rint(2...4), i = rint(3...12)
        return numProblem(.graphs, "A full \(m)-ary tree has \(i) internal vertices. How many leaves?", Double((m - 1) * i + 1), shown: "\((m - 1) * i + 1)", ask: "leaves =", steps: [
            "Full m-ary: every internal vertex has exactly \(m) children.",
            "Total vertices n = m·i + 1 = \(m * i + 1) (every vertex is someone's child, except the root).",
            "Leaves = n − i = (m − 1)i + 1 = \((m - 1) * i + 1)",
        ])
    case 3:
        let n = rint(5...10), d = [2, 3, 4].randomElement()!
        let nn = n * d % 2 == 1 ? n + 1 : n
        return numProblem(.graphs, "Every vertex in a \(nn)-vertex graph has degree \(d). How many edges?", Double(nn * d / 2), shown: "\(nn * d / 2)", ask: "edges =", steps: [
            "Handshake: sum of degrees = \(nn)·\(d) = \(nn * d) = 2·edges.", "Edges = \(nn * d / 2)",
        ])
    default:
        let odd = [0, 2, 4].randomElement()!
        let n = rint(5...7)
        var degs = (0..<n).map { _ in [2, 4].randomElement()! }
        for i in 0..<odd { degs[i] = [1, 3, 5].randomElement()! }
        degs.shuffle()
        let right = odd == 0 ? "Euler circuit" : odd == 2 ? "Euler path, but no circuit" : "Neither"
        return mc(.graphs, "A connected graph has degrees \(degs.map { "\($0)" }.joined(separator: ", ")).\nDoes it have an Euler circuit, an Euler path, or neither?", right: right,
                  wrong: ["Euler circuit", "Euler path, but no circuit", "Neither"], steps: [
            "Euler circuit: uses every EDGE once and returns to start. Needs every degree even.",
            "Euler path (not closed): exactly two odd-degree vertices; start at one, end at the other.",
            "Odd degrees here: \(odd).",
            "So: \(right).",
        ])
    }
}

// MARK: - Unit 8: Recurrences

func generateRecurrences() -> Problem {
    if coin() {
        let c1 = rint(1...2), c2 = rint(1...3), a0 = rint(0...2), a1 = rint(1...3), n = rint(5...7)
        var v = [a0, a1]
        var steps = ["Just iterate: each term from the two before it."]
        for i in 2...n { v.append(c1 * v[i - 1] + c2 * v[i - 2]); steps.append("a_\(i) = \(c1)(\(v[i - 1])) + \(c2)(\(v[i - 2])) = \(v[i])") }
        return numProblem(.recurrences, "a_n = \(c1 == 1 ? "" : "\(c1)")a_(n−1) + \(c2 == 1 ? "" : "\(c2)")a_(n−2),   a₀ = \(a0), a₁ = \(a1)\n\nFind a_\(n)", Double(v[n]), shown: "\(v[n])", ask: "a_\(n) =", steps: steps)
    }
    var r = [2, 3, -1, -2, 4, 1].randomElement()!, s = [2, 3, -1, -2, 4, 1].randomElement()!
    while r == s || r + s == 0 { r = [2, 3, -1, -2, 4, 1].randomElement()!; s = [2, 3, -1, -2, 4].randomElement()! }
    if r < s { (r, s) = (s, r) }
    let A = r + s, B = -r * s
    let al = [-2, -1, 1, 2, 3].randomElement()!, be = [1, 2, -1].randomElement()!
    let a0 = al + be, a1 = al * r + be * s
    let n = rint(4...6)
    let an = al * ipow(r, n) + be * ipow(s, n)
    return numProblem(.recurrences, "Solve  a_n = \(neg(A))a_(n−1) \(sgn(B))a_(n−2),   a₀ = \(a0), a₁ = \(a1)\nThen find a_\(n).", Double(an), shown: "a_n = \(neg(al))·(\(r))^n \(sgn(be))·(\(s))^n,  so a_\(n) = \(an)", ask: "a_\(n) =", steps: [
        "Characteristic equation: x² = \(neg(A))x \(sgn(B))  →  x² \(sgn(-A))x \(sgn(-B)) = 0.",
        "Factor: (x − \(r))(x − \(s)) = 0  (check: roots add to \(A), multiply to \(r * s)). Roots: \(r), \(s).",
        "Distinct roots → a_n = α(\(r))^n + β(\(s))^n.",
        "n = 0: α + β = \(a0).   n = 1: \(r)α \(sgn(s))β = \(a1).",
        "Solve: α = \(al), β = \(be).",
        "a_\(n) = \(al)(\(ipow(r, n))) \(sgn(be))(\(ipow(s, n))) = \(an)",
    ])
}

func generate(_ t: Topic) -> Problem {
    let p = rawGenerate(t)
    func fix(_ x: String) -> String {
        x.replacingOccurrences(of: "(?<![0-9A-Za-z)])-(?=[0-9])", with: "−", options: .regularExpression)
    }
    return Problem(topic: p.topic, prompt: fix(p.prompt), steps: p.steps.map(fix), answer: fix(p.answer),
                   numeric: p.numeric, ask: p.ask.map(fix), choices: p.choices?.map(fix), correct: p.correct)
}

func rawGenerate(_ t: Topic) -> Problem {
    switch t {
    case .connectives: return generateConnectives()
    case .conditionals: return generateConditionals()
    case .truthTables: return generateTruthTable()
    case .equivalence: return generateEquivalence()
    case .quantifiers: return generateQuantifiers()
    case .proofs: return generateProofs()
    case .induction: return generateInduction()
    case .sets: return generateSets()
    case .setSize: return generateSetSize()
    case .functions: return generateFunctions()
    case .sequences: return generateSequences()
    case .modArith: return generateModArith()
    case .gcdTopic: return generateGcd()
    case .modInverse: return generateModInverse()
    case .bases: return generateBases()
    case .countRules: return generateCountRules()
    case .permComb: return generatePermComb()
    case .starsBars: return generateStarsBars()
    case .pigeonhole: return generatePigeonhole()
    case .binomial: return generateBinomial()
    case .probability: return generateProbability()
    case .relations: return generateRelations()
    case .graphs: return generateGraphs()
    case .recurrences: return generateRecurrences()
    }
}

// MARK: - Lessons

let lessons: [Topic: [String]] = [
    .connectives: [
        "A proposition is a statement that is either true (T) or false (F). \"7 is prime\" is one. \"x + 1 = 3\" is not, until you know x.",
        "¬p (not p): flips the value.",
        "p ∧ q (and): T only when BOTH are T.",
        "p ∨ q (or): T when AT LEAST one is T. In math, \"or\" includes both.",
        "p ⊕ q (exclusive or): T when EXACTLY one is T.",
        "Order: ¬ first, then ∧, then ∨, but just follow the parentheses and work from the inside out.",
        "Method: write the values above each letter, then shrink the expression one operation at a time.",
    ],
    .conditionals: [
        "p → q (\"if p, then q\") is FALSE in only one case: p is T and q is F. A promise is only broken if the condition happens and the result doesn't.",
        "If p is F, then p → q is automatically T (\"vacuously true\").",
        "p ↔ q (\"p if and only if q\") is T when p and q match.",
        "From p → q you can build: converse q → p, inverse ¬p → ¬q, contrapositive ¬q → ¬p.",
        "The contrapositive is ALWAYS equivalent to the original. The converse and inverse are not.",
        "English versions of p → q: \"q if p\", \"p only if q\", \"p is sufficient for q\", \"q is necessary for p\".",
    ],
    .truthTables: [
        "A truth table lists every possible combination of T/F for the variables.",
        "n variables → 2^n rows. 2 variables: 4 rows. 3 variables: 8 rows.",
        "Standard order: the first variable is TTTTFFFF, the next TTFFTTFF, the last TFTFTFTF.",
        "Add a column for each piece (inside first), then the final column.",
        "Tautology: always T.  Contradiction: always F.  Contingency: sometimes T, sometimes F.",
    ],
    .equivalence: [
        "Two statements are logically equivalent (≡) if they have the same truth table.",
        "De Morgan: ¬(p ∧ q) ≡ ¬p ∨ ¬q   and   ¬(p ∨ q) ≡ ¬p ∧ ¬q.  Push the ¬ in and flip ∧/∨.",
        "Conditional: p → q ≡ ¬p ∨ q.",
        "Negated conditional: ¬(p → q) ≡ p ∧ ¬q.  (Not another arrow!)",
        "Contrapositive: p → q ≡ ¬q → ¬p.",
        "Double negation: ¬¬p ≡ p.  Distributive: p ∧ (q ∨ r) ≡ (p ∧ q) ∨ (p ∧ r).",
        "To show two things are NOT equivalent, find one row where they differ.",
    ],
    .quantifiers: [
        "A predicate P(x) becomes a proposition once you plug in x.",
        "∀x P(x): \"for all x\". True only if P(x) is true for EVERY x in the domain. One counterexample kills it.",
        "∃x P(x): \"there exists x\". True if AT LEAST ONE x works.",
        "∀x (P(x) → Q(x)): every x that has P also has Q. Only x with P true and Q false break it.",
        "Negation: ¬∀x P(x) ≡ ∃x ¬P(x)   and   ¬∃x P(x) ≡ ∀x ¬P(x). Flip the quantifier, push the ¬ in.",
        "The domain matters: ∀x (x² ≥ x) is true for integers but false for real numbers (try x = 1/2).",
    ],
    .proofs: [
        "Direct proof of p → q: assume p, use definitions and algebra, arrive at q.",
        "Definitions you'll use constantly: n is even if n = 2k, odd if n = 2k + 1, a | b if b = ak (k an integer).",
        "Contrapositive: prove ¬q → ¬p instead. Use it when the hypothesis is hard to work with (like \"n² is even\").",
        "Contradiction: assume the statement is FALSE and derive something impossible. Great for \"not\", \"irrational\", \"infinitely many\", \"no largest\".",
        "Cases: split into exhaustive cases (n even / n odd, x ≥ 0 / x < 0) and prove each.",
        "∃ statements: give one example.   ∀ statements are disproved by one counterexample.",
    ],
    .induction: [
        "Induction proves P(n) for every n ≥ 1 (or ≥ some start) like dominoes.",
        "Base case: show P(1) is true (plug in).",
        "Inductive step: ASSUME P(k) is true (the inductive hypothesis, IH). Use it to PROVE P(k + 1).",
        "For sum formulas: start from the IH, add the (k + 1)th term to both sides, and simplify the right side into the formula with n = k + 1.",
        "Conclude: by induction, P(n) holds for all n ≥ 1.",
        "Strong induction: assume P(1), …, P(k) all true to prove P(k + 1).",
    ],
    .sets: [
        "A set is an unordered collection with no repeats: {1, 2, 3} = {3, 1, 2}.",
        "A ∪ B (union): in A or B.   A ∩ B (intersection): in both.",
        "A − B (difference): in A, not in B.   Aᶜ (complement): in the universe U but not in A.",
        "A ⊕ B (symmetric difference): in exactly one of A, B.",
        "|A| is the number of elements (cardinality). ∅ is the empty set, |∅| = 0.",
        "A ⊆ B means every element of A is in B. ∅ ⊆ every set.",
        "De Morgan for sets: (A ∪ B)ᶜ = Aᶜ ∩ Bᶜ  and  (A ∩ B)ᶜ = Aᶜ ∪ Bᶜ.",
    ],
    .setSize: [
        "Power set P(S): the set of all subsets. |P(S)| = 2^|S|.",
        "Cartesian product A × B: all ordered pairs (a, b). |A × B| = |A|·|B|.",
        "Inclusion–exclusion (2 sets): |A ∪ B| = |A| + |B| − |A ∩ B|.",
        "3 sets: |A ∪ B ∪ C| = |A| + |B| + |C| − |A∩B| − |A∩C| − |B∩C| + |A∩B∩C|.",
        "\"Neither\" = total − |A ∪ B|.",
        "Subsets of size k from an n-element set: C(n, k).",
    ],
    .functions: [
        "A function f: A → B gives every element of A exactly one output in B. A is the domain, B the codomain.",
        "One-to-one (injective): different inputs → different outputs.",
        "Onto (surjective): every element of B is hit by something.",
        "Bijection: both. Only bijections have inverses f⁻¹.",
        "Composition (f ∘ g)(x) = f(g(x)): do g first, then f.",
        "Floor ⌊x⌋ rounds down, ceiling ⌈x⌉ rounds up. ⌊−2.5⌋ = −3, ⌈−2.5⌉ = −2.",
    ],
    .sequences: [
        "Arithmetic: add d each time. a_n = a₁ + (n − 1)d. Sum = n(first + last)/2.",
        "Geometric: multiply by r. a_n = a·r^n (starting at n = 0). Σ_(j=0)^n a·r^j = a(r^(n+1) − 1)/(r − 1).",
        "Σ_(i=1)^n i = n(n + 1)/2.   Σ_(i=1)^n i² = n(n + 1)(2n + 1)/6.",
        "Split sums: Σ(c·i + d) = c·Σi + d·n.",
        "Watch where the index starts: Σ_(j=0)^n has n + 1 terms.",
        "A recurrence defines each term from earlier ones; iterate carefully.",
    ],
    .modArith: [
        "Division algorithm: for d > 0, every a = d·q + r with 0 ≤ r < d. q = quotient, r = remainder.",
        "a mod d = r. It's always between 0 and d − 1, even when a is negative: −7 mod 3 = 2 because −7 = 3(−3) + 2.",
        "a ≡ b (mod m) means m divides a − b (same remainder).",
        "You can reduce at any point: (a + b) mod m and (a·b) mod m can use the remainders of a and b.",
        "Big powers: square repeatedly (a, a², a⁴, a⁸, …) reducing each time, then multiply the ones you need.",
    ],
    .gcdTopic: [
        "A prime has exactly two positive divisors: 1 and itself. 1 is NOT prime.",
        "Every integer > 1 factors uniquely into primes (Fundamental Theorem of Arithmetic).",
        "gcd(a, b): the largest number dividing both. lcm(a, b): the smallest positive number both divide.",
        "Euclidean algorithm: gcd(a, b) = gcd(b, a mod b). Repeat until the remainder is 0; the last nonzero remainder is the gcd.",
        "gcd(a, b)·lcm(a, b) = a·b.",
        "Number of divisors of p₁^e₁ ⋯ pₖ^eₖ is (e₁ + 1)⋯(eₖ + 1).",
    ],
    .modInverse: [
        "The inverse of a mod m is x with a·x ≡ 1 (mod m). It exists exactly when gcd(a, m) = 1.",
        "Small m: just test x = 1, 2, 3, … until a·x mod m = 1.",
        "Bigger m: extended Euclid. Run the Euclidean algorithm and write each remainder as (stuff)·m + (stuff)·a. When you hit 1, the coefficient on a is the inverse.",
        "Make it positive by adding m.",
        "Solving a·x ≡ b (mod m): multiply both sides by a⁻¹: x ≡ a⁻¹·b (mod m).",
        "Always check by multiplying back.",
    ],
    .bases: [
        "Base b uses digits 0 … b − 1, and each place is a power of b.",
        "(1011)₂ = 1·8 + 0·4 + 1·2 + 1·1 = 11.",
        "Decimal → base b: divide by b repeatedly; the remainders read from the LAST to the FIRST are the digits.",
        "Powers of 2 to know: 1, 2, 4, 8, 16, 32, 64, 128, 256.",
    ],
    .countRules: [
        "Product rule: a task done in steps (first this AND THEN that) → multiply the number of ways for each step.",
        "Sum rule: a task done ONE way out of separate, non-overlapping groups → add.",
        "Subtraction rule (inclusion–exclusion): |A ∪ B| = |A| + |B| − |A ∩ B| when the groups overlap.",
        "Counting multiples: integers in 1…N divisible by d: ⌊N/d⌋. Divisible by both a and b: by lcm(a, b).",
        "Bit strings of length n: 2^n. Fix some bits, the rest are free.",
    ],
    .permComb: [
        "Key question: does ORDER matter?",
        "Order matters (rankings, roles, arrangements): P(n, k) = n!/(n − k)! = n(n − 1)⋯(n − k + 1).",
        "Order doesn't matter (committees, hands, subsets): C(n, k) = n!/(k!(n − k)!).",
        "C(n, k) = P(n, k)/k!, because each group can be ordered k! ways.",
        "Arranging letters with repeats: n!/(n₁!·n₂!⋯), dividing by the repeats of each letter.",
        "\"At least one\": total minus \"none\" is usually easiest.",
    ],
    .starsBars: [
        "Use stars and bars when choosing with repetition where order doesn't matter, or splitting identical things into groups.",
        "n identical items into k groups (groups can be empty): C(n + k − 1, k − 1).",
        "Picture: n stars and k − 1 bars in a row. The bars split stars into k groups.",
        "Each group needs at least 1: hand out one to each first, then n − k are left: C(n − 1, k − 1).",
        "A lower bound like x₁ ≥ 3: pre-pay 3 to x₁ and subtract it from n.",
    ],
    .pigeonhole: [
        "Pigeonhole: if more than k objects go into k boxes, some box has at least 2.",
        "Generalized: N objects in k boxes → some box has at least ⌈N/k⌉.",
        "\"Guarantee\" questions: imagine the WORST case (spread things out as evenly as you can), then add 1.",
        "To guarantee r in one of k boxes, you need k(r − 1) + 1 objects.",
        "The hard part is choosing the boxes (months, colors, remainders mod n, pairs that sum to something).",
    ],
    .binomial: [
        "(x + y)^n = Σ_(k=0)^n C(n, k) x^k y^(n−k).",
        "The coefficients are row n of Pascal's triangle: C(n, k) = C(n − 1, k − 1) + C(n − 1, k).",
        "For (ax + b)^n, the x^k term is C(n, k)·a^k·b^(n−k)·x^k.",
        "Signs: (−2)^3 = −8, (−2)^4 = 16.",
        "Sum of row n: C(n, 0) + ⋯ + C(n, n) = 2^n.",
    ],
    .probability: [
        "Equally likely outcomes: P(E) = |E| / |S| (favorable over total).",
        "Use counting (product rule, C(n, k)) to get both numbers.",
        "Complement: P(not E) = 1 − P(E). Best for \"at least one\".",
        "Independent events: P(A ∩ B) = P(A)·P(B).",
        "Expected value: E[X] = Σ (value × probability).",
        "Conditional: P(A | B) = P(A ∩ B)/P(B).",
    ],
    .relations: [
        "A relation R on a set A is a set of ordered pairs (a, b) from A × A.",
        "Reflexive: every (a, a) is in R.",
        "Symmetric: (a, b) in R ⇒ (b, a) in R.",
        "Antisymmetric: (a, b) and (b, a) both in R ⇒ a = b.",
        "Transitive: (a, b) and (b, c) in R ⇒ (a, c) in R.",
        "Equivalence relation: reflexive + symmetric + transitive (like ≡ mod m). Partial order: reflexive + antisymmetric + transitive (like ≤).",
    ],
    .graphs: [
        "A graph is vertices joined by edges. The degree of a vertex is how many edges touch it.",
        "Handshake theorem: sum of all degrees = 2 × (number of edges).",
        "K_n (complete): every pair joined, n(n − 1)/2 edges. K_(m,n) (complete bipartite): m·n edges.",
        "A tree is connected with no cycles; n vertices → n − 1 edges.",
        "Euler circuit (every edge once, back to start) exists in a connected graph iff every degree is even. Euler path iff exactly 0 or 2 odd degrees.",
        "Full m-ary tree with i internal vertices: n = mi + 1 vertices, (m − 1)i + 1 leaves.",
    ],
    .recurrences: [
        "A recurrence gives a_n from earlier terms, plus starting values.",
        "Iterating: just compute a₂, a₃, … one at a time.",
        "Linear homogeneous a_n = c₁a_(n−1) + c₂a_(n−2): try a_n = rⁿ. You get the characteristic equation r² − c₁r − c₂ = 0.",
        "Two distinct roots r₁, r₂: a_n = α·r₁^n + β·r₂^n.",
        "Use a₀ and a₁ to solve for α and β (two equations, two unknowns).",
        "Check your closed form against the first couple of terms.",
    ],
]

func reviewLesson() -> [String] {
    [
        "Mixed review pulls from every level you've unlocked, weighted toward the ones you miss.",
        "Before solving, name the topic out loud. Most mistakes start with picking the wrong tool.",
        "Counting tells: order matters → P; groups → C; identical items into bins → stars and bars; \"guarantee\" → pigeonhole; \"at least one\" → complement.",
        "Logic tells: \"if\" → think contrapositive; \"not\" in front of a quantifier → flip it.",
        "Press L any time to reopen the lesson for the current problem's topic.",
    ]
}

// MARK: - Engine

enum Mode: Hashable {
    case path
    case review
    case topic(Topic)
}

final class Engine: ObservableObject {
    static let levels = Topic.allCases
    static let streakGoal = 3

    @Published var current: Problem
    @Published var revealed = false
    @Published var weights: [Topic: Int]
    @Published var attempted: [Topic: Int]
    @Published var missed: [Topic: Int]
    @Published var level: Int
    @Published var maxLevel: Int
    @Published var streak = 0
    @Published var banner: String? = nil
    @Published var stepsShown = 0
    @Published var watching = true
    @Published var teaching = true
    @Published var lessonAtStart = true
    @Published var answerText = ""
    @Published var checked: Bool? = nil
    @Published var picked: Int? = nil
    @Published var parseError = false
    var retryTopic: Topic? = nil
    @Published var mode: Mode = .path {
        didSet {
            streak = 0
            banner = nil
            if mode == .path { level = min(max(UserDefaults.standard.integer(forKey: "dmLevel"), 0), Self.levels.count - 1) }
            teaching = true
            lessonAtStart = true
            watching = mode != .review
            next()
        }
    }

    var onPath: Bool { mode == .path }

    var lessonTopic: Topic? {
        switch mode {
        case .topic(let t): return t
        case .path: return Self.levels[level]
        case .review: return lessonAtStart ? nil : current.topic
        }
    }
    var lessonTitle: String { lessonTopic?.rawValue ?? "Mixed review: how to decide" }
    var lessonLines: [String] { lessonTopic.map { lessons[$0] ?? [] } ?? reviewLesson() }

    init() {
        var w: [Topic: Int] = [:]
        for t in Topic.allCases { w[t] = 3 }
        if let saved = UserDefaults.standard.dictionary(forKey: "dmWeights") as? [String: Int] {
            for (k, v) in saved { if let t = Topic(rawValue: k) { w[t] = v } }
        }
        weights = w
        attempted = Self.loadCounts("dmAttempted")
        missed = Self.loadCounts("dmMissed")
        level = min(max(UserDefaults.standard.integer(forKey: "dmLevel"), 0), Self.levels.count - 1)
        maxLevel = min(max(UserDefaults.standard.integer(forKey: "dmMaxLevel"), 0), Self.levels.count - 1)
        current = generate(.connectives)
        current = generate(chooseTopic())
    }

    static func loadCounts(_ key: String) -> [Topic: Int] {
        var d: [Topic: Int] = [:]
        for t in Topic.allCases { d[t] = 0 }
        if let saved = UserDefaults.standard.dictionary(forKey: key) as? [String: Int] {
            for (k, v) in saved { if let t = Topic(rawValue: k) { d[t] = v } }
        }
        return d
    }

    func save() {
        func dict(_ x: [Topic: Int]) -> [String: Int] { Dictionary(uniqueKeysWithValues: x.map { ($0.key.rawValue, $0.value) }) }
        UserDefaults.standard.set(dict(weights), forKey: "dmWeights")
        UserDefaults.standard.set(dict(attempted), forKey: "dmAttempted")
        UserDefaults.standard.set(dict(missed), forKey: "dmMissed")
        if onPath { UserDefaults.standard.set(level, forKey: "dmLevel") }
        UserDefaults.standard.set(maxLevel, forKey: "dmMaxLevel")
    }

    func chooseTopic() -> Topic {
        if let r = retryTopic { retryTopic = nil; return r }
        switch mode {
        case .topic(let t): return t
        case .path: return Self.levels[level]
        case .review:
            let group = Array(Self.levels.prefix(maxLevel + 1))
            let pool = group.flatMap { t in Array(repeating: t, count: max(weights[t] ?? 1, 1)) }
            return pool.randomElement() ?? .connectives
        }
    }

    var done: Bool { revealed && stepsShown > current.steps.count }
    var isChoice: Bool { current.choices != nil }
    var canAnswer: Bool { !watching && !teaching && checked == nil && !done }

    func next() {
        current = generate(chooseTopic())
        revealed = false
        stepsShown = 0
        answerText = ""
        checked = nil
        picked = nil
        parseError = false
    }

    func advance() {
        if !revealed { revealed = true; stepsShown = 1 }
        else if stepsShown <= current.steps.count { stepsShown += 1 }
    }

    func showAll() {
        revealed = true
        stepsShown = current.steps.count + 1
    }

    // Counting answers must be exact; probabilities and decimals get a little rounding slack.
    func check() {
        guard let target = current.numeric, let g = parseAnswer(answerText) else { parseError = true; return }
        parseError = false
        if target == target.rounded() && abs(target) < 1e15 {
            checked = abs(g - target) < 1e-6
        } else {
            checked = abs(g - target) <= max(0.01 * abs(target), 0.005)
        }
        showAll()
    }

    func pick(_ i: Int) {
        picked = i
        checked = i == current.correct
        showAll()
    }

    func yourTurn() { watching = false; next() }
    func openLesson() { lessonAtStart = false; teaching = true }

    func closeLesson() {
        teaching = false
        if lessonAtStart { watching = mode != .review; next() }
    }

    func setLevel(_ l: Int) {
        level = min(max(l, 0), Self.levels.count - 1)
        maxLevel = max(maxLevel, level)
        streak = 0
        banner = nil
        watching = true
        teaching = true
        lessonAtStart = true
        save()
        next()
    }

    func mark(gotIt: Bool) {
        banner = nil
        attempted[current.topic, default: 0] += 1
        if gotIt {
            weights[current.topic] = max((weights[current.topic] ?? 3) - 1, 2)
            streak += 1
            if onPath, streak >= Self.streakGoal, level < Self.levels.count - 1 {
                level += 1
                maxLevel = max(maxLevel, level)
                streak = 0
                banner = "Level up! Now: \(Self.levels[level].rawValue)"
                watching = true
                teaching = true
                lessonAtStart = true
            }
        } else {
            missed[current.topic, default: 0] += 1
            weights[current.topic] = min((weights[current.topic] ?? 3) + 2, 12)
            streak = 0
            retryTopic = current.topic
        }
        save()
        next()
        if !gotIt { banner = "Same type again with new numbers. Find the step where you split off." }
    }
}

// MARK: - Math rendering

// Renders "2^(n+1)" with a raised exponent and "a_n" with a lowered subscript.
// ^ or _ followed by (...) takes the whole parenthesized group; otherwise it takes the run of letters/digits.
func mathText(_ s: String, size: CGFloat, weight: Font.Weight = .regular, mono: Bool = false) -> Text {
    let design: Font.Design = mono ? .monospaced : .default
    let base = Font.system(size: size, weight: weight, design: design)
    let small = Font.system(size: size * 0.72, weight: weight, design: design)
    let chars = Array(s)
    var out = Text("")
    var buf = ""
    var i = 0
    while i < chars.count {
        let c = chars[i]
        if (c == "^" || c == "_"), i + 1 < chars.count {
            var j = i + 1
            var piece = ""
            if chars[j] == "(" {
                var depth = 0
                while j < chars.count {
                    if chars[j] == "(" { depth += 1 } else if chars[j] == ")" { depth -= 1; if depth == 0 { break } }
                    piece.append(chars[j])
                    j += 1
                }
                piece.removeFirst()
                j += 1
            } else {
                while j < chars.count, chars[j].isLetter || chars[j].isNumber { piece.append(chars[j]); j += 1 }
            }
            if piece.isEmpty {
                buf.append(c)
                i += 1
                continue
            }
            if !buf.isEmpty { out = out + Text(buf).font(base); buf = "" }
            out = out + Text(piece).font(small).baselineOffset(c == "^" ? size * 0.38 : -size * 0.18)
            i = j
            continue
        }
        buf.append(c)
        i += 1
    }
    if !buf.isEmpty { out = out + Text(buf).font(base) }
    return out
}

// MARK: - View

struct ContentView: View {
    @StateObject private var engine = Engine()
    @AppStorage("dmHideStats") private var hideStats = true

    private var pathHeader: some View {
        let t = Engine.levels[engine.level]
        let last = engine.level == Engine.levels.count - 1
        return VStack(spacing: 6) {
            Text(unit(t)).font(.caption.weight(.bold)).foregroundStyle(Color.purple)
            HStack(spacing: 12) {
                Button { engine.setLevel(engine.level - 1) } label: { Image(systemName: "chevron.left") }
                    .disabled(engine.level == 0)
                    .keyboardShortcut("[", modifiers: [])
                Text("Level \(engine.level + 1) of \(Engine.levels.count) · \(t.rawValue)")
                    .font(.subheadline.weight(.semibold))
                Button { engine.setLevel(engine.level + 1) } label: { Image(systemName: "chevron.right") }
                    .disabled(last)
                    .keyboardShortcut("]", modifiers: [])
            }
            HStack(spacing: 6) {
                ForEach(0..<Engine.streakGoal, id: \.self) { i in
                    Circle()
                        .fill(i < engine.streak ? Color.green : Color.secondary.opacity(0.3))
                        .frame(width: 9, height: 9)
                }
                Text(last ? "Final level: keep going" : "\(engine.streak)/\(Engine.streakGoal) in a row to level up")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func lessonCard(_ k: CGFloat) -> some View {
        VStack(spacing: 14 * k) {
            Text("📘 LESSON: \(engine.lessonTitle)")
                .font(.system(size: 18 * k, weight: .bold))
                .foregroundStyle(Color.purple)
            ScrollView {
                VStack(alignment: .leading, spacing: 10 * k) {
                    ForEach(Array(engine.lessonLines.enumerated()), id: \.offset) { _, line in
                        mathText("• \(line)", size: 15 * k)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 30)
            }
            .frame(height: 400 * k)
            Text("Read it once out loud. Then watch one done step by step.")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Button {
                engine.closeLesson()
            } label: {
                Label(engine.lessonAtStart
                      ? (engine.mode == .review ? "Start the review (Return)" : "Show me a worked example (Return)")
                      : "Back to my problem (Return)", systemImage: "play.fill")
            }
            .keyboardShortcut(.return, modifiers: [])
            .controlSize(.large)
            .tint(.purple)
        }
    }

    private func answerBox(_ k: CGFloat) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                mathText(engine.current.ask ?? "Answer =", size: 15 * k, weight: .medium, mono: true)
                TextField("e.g. 12, 3/8 or 0.25", text: $engine.answerText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 180)
                    .onSubmit { engine.check() }
                Button("Check") { engine.check() }
            }
            Text(engine.parseError ? "Type a number or a fraction like 5/36."
                 : "Type your answer and press Return. Or reveal steps with Space.")
                .font(.caption2)
                .foregroundStyle(engine.parseError ? Color.red : Color.secondary)
        }
    }

    private func choiceList(_ k: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array((engine.current.choices ?? []).enumerated()), id: \.offset) { i, opt in
                let shown = engine.checked != nil
                let isRight = i == engine.current.correct
                let isPicked = engine.picked == i
                Button {
                    if engine.canAnswer { engine.pick(i) }
                } label: {
                    HStack(alignment: .top) {
                        Text("\(i + 1)").font(.system(size: 13 * k, weight: .bold, design: .monospaced))
                        mathText(opt, size: 15 * k, mono: true)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        if shown && isRight { Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.green) }
                        if shown && isPicked && !isRight { Image(systemName: "xmark.circle.fill").foregroundStyle(Color.red) }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: 560, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 8).fill(shown && isRight ? Color.green.opacity(0.15) : Color.secondary.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(KeyEquivalent(Character("\(i + 1)")), modifiers: [])
                .disabled(engine.watching && !engine.revealed)
            }
            if engine.canAnswer {
                Text("Press 1–\(engine.current.choices?.count ?? 2) to answer, or Space to reveal steps.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    var body: some View {
        GeometryReader { geo in
        let k = min(max(geo.size.height / 780, 1), 1.8)
        VStack(spacing: 14 * k) {
            HStack {
                Text("Discrete for MFE").font(.headline)
                Spacer()
                Button { engine.openLesson() } label: { Label("Lesson (L)", systemImage: "book") }
                    .keyboardShortcut("l", modifiers: [])
                    .disabled(engine.teaching)
                Button { hideStats.toggle() } label: { Label(hideStats ? "Show stats" : "Hide stats", systemImage: "chart.bar") }
                    .keyboardShortcut("h", modifiers: [])
                Button { NSApp.keyWindow?.toggleFullScreen(nil) } label: { Label("Full screen", systemImage: "arrow.up.left.and.arrow.down.right") }
                    .keyboardShortcut("f", modifiers: [])
            }
            .padding(.horizontal)
            .padding(.top, 16)

            Picker("Mode", selection: $engine.mode) {
                Text("Learn from the beginning (path)").tag(Mode.path)
                Text("Mixed review of unlocked levels").tag(Mode.review)
                Divider()
                ForEach(Topic.allCases) { t in
                    Text("\(unit(t).components(separatedBy: " · ").first ?? ""): \(t.rawValue)").tag(Mode.topic(t))
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: 400)

            if engine.onPath { pathHeader }

            if let b = engine.banner {
                Text(b)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(b.hasPrefix("Same type") ? Color.orange : Color.green)
            }

            if engine.teaching {
                lessonCard(k)
            } else {
                VStack(spacing: 10) {
                    Text(engine.watching ? "WORKED EXAMPLE: watch it step by step, then you try one"
                         : (engine.mode == .review && !engine.revealed ? "Which topic is this? Name it, then solve." : engine.current.topic.rawValue))
                        .font(.caption.weight(engine.watching ? .bold : .regular))
                        .foregroundStyle(engine.watching ? Color.orange : Color.secondary)
                    mathText(engine.current.prompt, size: 19 * k, weight: .medium, mono: true)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 20)
                }
                .frame(minHeight: 90 * k)

                if engine.isChoice {
                    choiceList(k)
                } else if engine.canAnswer {
                    answerBox(k)
                }

                if engine.revealed {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(engine.current.steps.prefix(engine.stepsShown).enumerated()), id: \.offset) { i, step in
                                    mathText("\(i + 1). \(step)", size: 14 * k)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                if engine.done {
                                    Divider()
                                    mathText(engine.current.answer, size: 16 * k, weight: .semibold, mono: true)
                                        .foregroundStyle(Color.accentColor)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Color.clear.frame(height: 1).id("bottom")
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                        }
                        .onChange(of: engine.stepsShown) { _ in
                            withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                        }
                    }
                    .frame(height: (engine.isChoice ? 200 : 250) * k)

                    if !engine.done {
                        HStack(spacing: 14) {
                            Button { engine.advance() } label: {
                                Label("Next step (Space)  \(engine.stepsShown)/\(engine.current.steps.count + 1)", systemImage: "forward.frame")
                            }
                            .keyboardShortcut(.space, modifiers: [])
                            Button { engine.showAll() } label: { Label("Show all (A)", systemImage: "list.bullet") }
                                .keyboardShortcut("a", modifiers: [])
                        }
                        .controlSize(.large)
                    } else if engine.watching {
                        Button { engine.yourTurn() } label: { Label("Your turn (Return)", systemImage: "pencil") }
                            .keyboardShortcut(.return, modifiers: [])
                            .controlSize(.large)
                            .tint(.orange)
                    } else if let ok = engine.checked {
                        VStack(spacing: 8) {
                            Text(ok ? "✓ Correct!" : "✗ Not quite. Read the steps and find where you split off.")
                                .font(.system(size: 16 * k, weight: .bold))
                                .foregroundStyle(ok ? Color.green : Color.red)
                            Button { engine.mark(gotIt: ok) } label: { Label("Next problem (Return)", systemImage: "arrow.right.circle.fill") }
                                .keyboardShortcut(.return, modifiers: [])
                                .tint(ok ? Color.green : Color.red)
                        }
                        .controlSize(.large)
                    } else {
                        HStack(spacing: 14) {
                            Button { engine.mark(gotIt: true) } label: { Label("Got it (G)", systemImage: "checkmark.circle.fill") }
                                .tint(.green)
                                .keyboardShortcut("g", modifiers: [])
                            Button { engine.mark(gotIt: false) } label: { Label("Missed it (M)", systemImage: "xmark.circle.fill") }
                                .tint(.red)
                                .keyboardShortcut("m", modifiers: [])
                        }
                        .controlSize(.large)
                    }
                } else {
                    Button { engine.advance() } label: {
                        Label(engine.watching ? "Start the example (Space)" : "Reveal first step (Space)", systemImage: "eye")
                    }
                    .controlSize(.large)
                    .keyboardShortcut(.space, modifiers: [])
                    Spacer().frame(height: 140 * k)
                }
            }

            Spacer(minLength: 0)

            if !hideStats {
                Divider().padding(.horizontal, 40)
                ScrollView {
                    VStack(spacing: 3) {
                        ForEach(Topic.allCases) { t in
                            HStack {
                                Text(t.rawValue).font(.caption2)
                                Spacer()
                                Text("\(engine.attempted[t] ?? 0) tried · \(engine.missed[t] ?? 0) missed")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 30)
                        }
                    }
                }
                .frame(height: 140)
                .padding(.bottom, 12)
            }
        }
        .frame(maxWidth: 900)
        .frame(width: geo.size.width, height: geo.size.height)
        }
        .frame(minWidth: 700, minHeight: 820)
    }
}

final class IconDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let path = Bundle.main.path(forResource: "AppIcon", ofType: "icns"),
           let img = NSImage(contentsOfFile: path) {
            NSApplication.shared.applicationIconImage = img
        }
    }
}

@main
struct DiscreteMFEApp: App {
    @NSApplicationDelegateAdaptor(IconDelegate.self) var iconDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentMinSize)
    }
}
