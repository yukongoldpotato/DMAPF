////
////  MultiAgent.swift
////  DMAPF
////
////  Created by Kazuki Minami on 2025/05/07.
////
//
//import Foundation
///// Reservation table: timestep → (set of occupied cells)
//
///// A grid cell stamped with a discrete timestep.
///// Keeps `Cell` semantics untouched while adding a time dimension.
//
//
//struct TimedMapGrid {
//    let size: Int
//    var cells: [TimedCell]
//
//    init(size: Int = 8) {
//        self.size = size
//        cells = (0..<(size * size)).map { index in
//            let x = index % size
//            let y = index / size
//            return TimedCell(x: x, y: y, cellState: .empty)
//        }
//    }
//}
///// Time‑expanded neighbours for multi‑agent planning.
///// Returns up / down / left / right moves **plus "wait"** that are free
///// in the reservation table at (t + 1).
//func getNeighbors(of node: TimedCell, reserved: Reservation) -> [TimedCell] {
//    var next: [TimedCell] = []
//    // spatial moves
//    let base = getNeighbors(of: node.cell) + [node.cell] // include 'wait'
//    let nextTime = node.t + 1
//    for c in base {
//        // skip if another agent already occupies the cell at nextTime
//        if reserved[nextTime]?.contains(c) == true { continue }
//        // prevent head‑on swap: reserve both directions
//        if reserved[nextTime]?.contains(where: { reservedCell in
//            reservedCell == c
//        }) == true { continue }
//        next.append(TimedCell(cell: c, t: nextTime))
//    }
//    return next
//}
///// Time‑aware A* that respects a global reservation table.
///// On success it *writes* the path into `reserved`.
//func aStarPathTimed(from start: Cell,
//                    to goal: Cell,
//                    reserved: inout Reservation) -> [Cell]? {
//
//    let startNode = TimedCell(cell: start, t: 0)
//
//    var open: [TimedCell] = [startNode]
//    var closed: Set<TimedCell> = []
//    var cameFrom: [TimedCell: TimedCell] = [:]
//    var gScore: [TimedCell: Int] = [startNode: 0]
//    var fScore: [TimedCell: Int] = [startNode: heuristic(start, goal)]
//
//    while !open.isEmpty {
//        guard let current = open.min(by: {
//            fScore[$0, default: .max] < fScore[$1, default: .max]
//        }) else { return nil }
//
//        // goal reached when spatial cell matches
//        if current.cell == goal {
//            // reconstruct
//            var nodes: [TimedCell] = [current]
//            var n = current
//            while let prev = cameFrom[n] {
//                nodes.append(prev)
//                n = prev
//            }
//            let path = nodes.reversed().map { $0.cell }
//            // write reservations
//            for (step, c) in path.enumerated() {
//                reserved[step, default: []].insert(c)
//            }
//            return path
//        }
//
//        // move current from open to closed
//        open.removeAll(where: { $0 == current })
//        closed.insert(current)
//
//        for neighbor in getNeighbors(of: current, reserved: reserved) {
//            if closed.contains(neighbor) { continue }
//
//            let tentativeG = gScore[current, default: .max] + 1
//            let notInOpen = !open.contains(neighbor)
//
//            if notInOpen || tentativeG < gScore[neighbor, default: .max] {
//                cameFrom[neighbor] = current
//                gScore[neighbor] = tentativeG
//                fScore[neighbor] = tentativeG + heuristic(neighbor.cell, goal)
//                if notInOpen {
//                    open.append(neighbor)
//                }
//            }
//        }
//    }
//    return nil  // no path
//}
