# Discrete for MFE

A macOS app that teaches discrete math from zero, one level at a time. Every problem is randomly generated and comes with every step of the solution written out.

## The path (24 levels)
1. **Logic:** propositions, conditionals, truth tables, logical equivalences, quantifiers
2. **Proofs:** proof methods, mathematical induction
3. **Sets, functions and sums:** set operations, counting with sets, functions, sequences and sums
4. **Number theory:** division and mod, GCD/LCM and primes, modular inverses, number bases
5. **Counting:** product and sum rules, permutations and combinations, stars and bars, pigeonhole, binomial theorem
6. **Probability, relations, graphs and recurrences**

Three right in a row unlocks the next level. There's also a mixed review of everything unlocked so far, and a single-topic mode.

## How it's built
- One SwiftUI file (`Sources/main.swift`). Each topic has a generator that returns a problem, its worked steps and the answer (typed numeric or multiple choice).
- Logic problems use a small expression tree that evaluates formulas, builds truth tables and checks whether two formulas are equivalent.

## Build
Requires macOS 13+ and the Xcode Command Line Tools.
```sh
./build.sh
```
