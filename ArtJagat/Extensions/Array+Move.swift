// Array+Move.swift
// ArtJagat — Reordering helper for Array

import Foundation

extension Array {
    mutating func move(fromOffsets: IndexSet, toOffset: Int) {
        var s = self
        var destination = toOffset
        let sourceOff = fromOffsets.sorted(by: >)
        for i in sourceOff {
            let item = s.remove(at: i)
            if i < destination { destination -= 1 }
            s.insert(item, at: destination)
        }
        self = s
    }
}
