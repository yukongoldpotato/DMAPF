//
//  GridCell.swift
//  DMAPF
//
//  Created by Kazuki Minami on 2025/04/29.
//


import Foundation
import SwiftUI

struct TimedCell: Hashable {
    let cell: Cell   /// spatial location
    let t: Int       /// discrete time
}

struct Agent {
    let id: Int
    let start: Cell
    let goal: Cell
}

enum CellState {
    case empty, occupied, start, end, path

    var color: Color {
        switch self {
        case .empty:
            return .white
        case .occupied:
            return .blue
        case .path:
            return .yellow
        default:
            return .teal
        }
    }
}

struct Cell: Hashable {
    var x: Int
    var y: Int
    var cellState: CellState
}

struct MapGrid {
    let size: Int
    var cells: [Cell]

    init(size: Int = 8) {
        self.size = size
        cells = (0..<(size * size)).map { index in
            let x = index % size
            let y = index / size
            return Cell(x: x, y: y, cellState: .empty)
        }
    }
}

typealias Reservation = [Int : Set<Cell>]

extension MapGrid {
    func getNeighbors(of cell: Cell) -> [Cell] {
        var neighbors: [Cell] = []
        let directions = [
            (row: -1, col: 0), // Up
            (row: 1, col: 0), // Down
            (row: 0, col: -1), // Left
            (row: 0, col: 1), // Right
        ]
        for dir in directions {
            let neighborRow = cell.y + dir.row
            let neighborCol = cell.x + dir.col

            if neighborRow >= 0 && neighborRow < size && neighborCol >= 0 && neighborCol < size {
                let location = neighborRow * size + neighborCol
                let neighborNode = cells[location]
                if neighborNode.cellState != .occupied && neighborNode.cellState != .path {
                    neighbors.append(neighborNode)
                }
            }
        }
        return neighbors
    }

    private func heuristic(_ a: Cell, _ b: Cell) -> Int {
        return abs(a.x - b.x) + abs(a.y - b.y)
    }

    private func reconstructPath(previousCellInPath: [Cell: Cell], startCell: Cell, endCell: Cell) -> [Cell] {
        var path: [Cell] = [endCell]
        var current = endCell
        while current != startCell {
            guard let previous = previousCellInPath[current] else {
                // Should not happen if a path was found
                return []
            }
            path.append(previous)
            current = previous
        }
        return path.reversed() // Reverse to get path from start to end
    }

    func aStarPath(from startCell: Cell, to targetCell: Cell) -> [Cell]? {
        var cellsToConsider: [Cell] = [startCell]
        var cellsAlreadyEvaluated: Set<Cell> = []
        var previousCellInPath: [Cell: Cell] = [:]
        var startToCurrentDistance: [Cell: Int] = [startCell: 0]
        var totalEstimatedCost: [Cell: Int] = [startCell: heuristic(startCell, targetCell)]

        while !cellsToConsider.isEmpty {
            // a. pick lowest score cell
            guard let currentCell = cellsToConsider.min(by: {
                totalEstimatedCost[$0, default: Int.max] < totalEstimatedCost[$1, default: Int.max]
            }) else { return nil }

            guard let currentCellIndex = cellsToConsider.firstIndex(of: currentCell) else { return nil }

            // b. Check if current cell is target cell
            if currentCell == targetCell {
                let path = reconstructPath(previousCellInPath: previousCellInPath, startCell: startCell, endCell: targetCell)
                return path
            }
            // c. Process Current Node
            cellsToConsider.remove(at: currentCellIndex) // Remove from consideration
            cellsAlreadyEvaluated.insert(currentCell) // Mark as evaluated
            // d. Explore Neighbors
            let neighbors = getNeighbors(of: currentCell)

            for neighborCell in neighbors {
                // i. Skip if Already Evaluated
                if cellsAlreadyEvaluated.contains(neighborCell) { continue }

                // ii. Calculate Tentative Distance
                let tentativeStartToNeighborDistance = startToCurrentDistance[currentCell, default: Int.max] + 1

                // iii. Discover or Update Neighbor
                let neighborIsInConsideration = cellsToConsider.contains(neighborCell)

                if !neighborIsInConsideration {
                    // Discover a new node
                    previousCellInPath[neighborCell] = currentCell
                    startToCurrentDistance[neighborCell] = tentativeStartToNeighborDistance
                    totalEstimatedCost[neighborCell] = tentativeStartToNeighborDistance + heuristic(neighborCell, targetCell)
                    cellsToConsider.append(neighborCell) // Add to consider list
                } else if tentativeStartToNeighborDistance < startToCurrentDistance[neighborCell, default: Int.max] {
                    // Found a better path to an existing node in nodesToConsider
                    previousCellInPath[neighborCell] = currentCell
                    startToCurrentDistance[neighborCell] = tentativeStartToNeighborDistance
                    totalEstimatedCost[neighborCell] = tentativeStartToNeighborDistance + heuristic(neighborCell, targetCell)
                    // Note: If using a real priority queue, you'd update the node's priority here.
                }
            }
        }
        // 3. No Path Found
        return nil
    }

    /// Time‑expanded neighbours for multi‑agent planning.
    /// Returns up / down / left / right moves **plus "wait"** that are free
    /// in the reservation table at (t + 1).
    func getTimedNeighbors(of node: TimedCell, reserved: Reservation) -> [TimedCell] {
        var next: [TimedCell] = []
        // spatial moves
        let base = getNeighbors(of: node.cell) + [node.cell] // include 'wait'
        let nextTime = node.t + 1
        for c in base {
            // skip if another agent already occupies the cell at nextTime
            if reserved[nextTime]?.contains(c) == true { continue }
            // prevent head‑on swap: reserve both directions
            if reserved[nextTime]?.contains(where: { reservedCell in
                reservedCell == c
            }) == true { continue }
            next.append(TimedCell(cell: c, t: nextTime))
        }
        return next
    }
    /// Time‑aware A* that respects a global reservation table.
    /// On success it *writes* the path into `reserved`.
    func aStarPathTimed(from start: Cell,
                        to goal: Cell,
                        reserved: inout Reservation) -> [Cell]? {

        let startNode = TimedCell(cell: start, t: 0)

        var open: [TimedCell] = [startNode]
        var closed: Set<TimedCell> = []
        var cameFrom: [TimedCell: TimedCell] = [:]
        var gScore: [TimedCell: Int] = [startNode: 0]
        var fScore: [TimedCell: Int] = [startNode: heuristic(start, goal)]

        while !open.isEmpty {
            guard let current = open.min(by: {
                fScore[$0, default: .max] < fScore[$1, default: .max]
            }) else { return nil }

            // goal reached when spatial cell matches
            if current.cell == goal {
                // reconstruct
                var nodes: [TimedCell] = [current]
                var n = current
                while let prev = cameFrom[n] {
                    nodes.append(prev)
                    n = prev
                }
                let path = nodes.reversed().map { $0.cell }
                // write reservations
                for (step, c) in path.enumerated() {
                    reserved[step, default: []].insert(c)
                }
                return path
            }

            // move current from open to closed
            open.removeAll(where: { $0 == current })
            closed.insert(current)

            for neighbor in getTimedNeighbors(of: current, reserved: reserved) {
                if closed.contains(neighbor) { continue }

                let tentativeG = gScore[current, default: .max] + 1
                let notInOpen = !open.contains(neighbor)

                if notInOpen || tentativeG < gScore[neighbor, default: .max] {
                    cameFrom[neighbor] = current
                    gScore[neighbor] = tentativeG
                    fScore[neighbor] = tentativeG + heuristic(neighbor.cell, goal)
                    if notInOpen {
                        open.append(neighbor)
                    }
                }
            }
        }
        return nil  // no path
    }

}
