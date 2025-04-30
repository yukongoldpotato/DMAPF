//
//  Trash.swift
//  DMAPF
//
//  Created by Kazuki Minami on 2025/04/29.
//

import Foundation

//extension MapGrid {
//    // Heuristic: Manhattan distance between two indices
//    private func heuristic(_ a: Int, _ b: Int) -> Int {
//        let ax = a % size
//        let ay = a / size
//        let bx = b % size
//        let by = b / size
//        return abs(ax - bx) + abs(ay - by)
//    }
//    // Return neighbor indices (4-directional) that are not blocked
//    private func neighbors(of index: Int) -> [Int] {
//        let row = index / size
//        let col = index % size
//        var result = [Int]()
//        let deltas = [(-1, 0), (1, 0), (0, -1), (0, 1)]
//        for (dr, dc) in deltas {
//            let nr = row + dr, nc = col + dc
//            guard nr >= 0, nr < size, nc >= 0, nc < size else { continue }
//            let ni = nr * size + nc
//            if cells[ni].cellState != .occupied {
//                result.append(ni)
//            }
//        }
//        return result
//    }
//
//    /// Finds the shortest path of indices from start to goal using A*.
//    /// - Returns: an array of indices representing the path, or nil if none.
//    func findPath(from start: Int, to goal: Int) -> [Int]? {
//        var openSet = Set<Int>([start])
//        var cameFrom = [Int: Int]()
//
//        // gScore: cost from start to this index
//        var gScore = [Int: Int]()
//        // fScore: estimated total cost (g + h)
//        var fScore = [Int: Int]()
//
//        for i in 0..<cells.count {
//            gScore[i] = Int.max
//            fScore[i] = Int.max
//        }
//        gScore[start] = 0
//        fScore[start] = heuristic(start, goal)
//
//        while !openSet.isEmpty {
//            // pick node in openSet with lowest fScore
//            let current = openSet.min(by: { fScore[$0]! < fScore[$1]! })!
//
//            if current == goal {
//                // Reconstruct path
//                var path = [goal]
//                var node = goal
//                while let prev = cameFrom[node] {
//                    path.append(prev)
//                    node = prev
//                }
//                return path.reversed()
//            }
//
//            openSet.remove(current)
//            for neighbor in neighbors(of: current) {
//                let tentativeG = gScore[current]! + 1
//                if tentativeG < gScore[neighbor]! {
//                    cameFrom[neighbor] = current
//                    gScore[neighbor] = tentativeG
//                    fScore[neighbor] = tentativeG + heuristic(neighbor, goal)
//                    openSet.insert(neighbor)
//                }
//            }
//        }
//        return nil // no path found
//    }
//}

//extension MapGrid {
//    // Heuristic: Manhattan distance between two indices
//    private func heuristic(_ a: Int, _ b: Int) -> Int {
//        let ax = a % size
//        let ay = a / size
//        let bx = b % size
//        let by = b / size
//        return abs(ax - bx) + abs(ay - by)
//    }
//
//    func aStarPath(from start: Int, to goal: Int) -> [Int]? {
//        var toSearch = Set<Int>([start])
//        var alreadyProcessed = [Int: Int]()
//
//        var startToCurrentDistance = [Int: Int]()
//        var fScore = [Int: Int]()
//
//        for index in 0..<cells.count {
//            startToCurrentDistance[index] = Int.max
//            fScore[index] = Int.max
//        }
//
//        startToCurrentDistance[start] = 0
//        fScore[start] = heuristic(start, goal)
//
//        while !toSearch.isEmpty {
//            // pick node in toSearch with lowest fScrore
//            let current = toSearch.min(by: { fScore[$0]! < fScore[$1]! })!
//
//            if current == goal {
//                // reconsruct path
//                var path = [goal]
//                var node = goal
//                while let prev = alreadyProcessed[node] {
//                    path.append(prev)
//                    node = prev
//                }
//            }
//
//            toSearch.remove(current)
//
//            for neighbor in neighbors(of: current) {
//
//            }
//        }
//    }
//}
