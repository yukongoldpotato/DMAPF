//
//  GridCell.swift
//  DMAPF
//
//  Created by Kazuki Minami on 2025/04/29.
//


import Foundation
import SwiftUI

enum CellState {
    case empty, occupied, blocked, agent1Start, agent1End, path, agent2Start, agent2End

    var color: Color {
        switch self {
        case .empty:
            return .white
        case .occupied:
            return .blue
        case .blocked:
            return .gray
        case .path:
            return .yellow
        default:
            return .red
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
                if neighborNode.cellState != .occupied && neighborNode.cellState != .blocked {
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
                print("Error: Path reconstruction failed.")
                return []
            }
            path.append(previous)
            current = previous
        }
        return path.reversed() // Reverse to get path from start to end
    }

    func aStarPath(from startCell: Cell, to targetCell: Cell) -> [Cell]? {
        print("A* start: from", startCell, "to", targetCell)
        var cellsToConsider: [Cell] = [startCell]
        var cellsAlreadyEvaluated: Set<Cell> = []
        var previousCellInPath: [Cell: Cell] = [:]
        var startToCurrentDistance: [Cell: Int] = [startCell: 0]

        // totalEstimatedCost (fScore): gScore + heuristic. Used for priority. Initialize to infinity.
        var totalEstimatedCost: [Cell: Int] = [startCell: heuristic(startCell, targetCell)]

        print("Initial open set:", cellsToConsider)
        print("Initial gScores:", startToCurrentDistance)
        print("Initial fScores:", totalEstimatedCost)

        while !cellsToConsider.isEmpty {
            // a. Select Best Node: Find node in nodesToConsider with the lowest totalEstimatedCost (fScore).
            var currentCell = cellsToConsider.min(by: {totalEstimatedCost[$0]! < totalEstimatedCost[$1]! })

            guard let currentCell = cellsToConsider.min(by: {
                totalEstimatedCost[$0, default: Int.max] < totalEstimatedCost[$1, default: Int.max]
            }) else {
                print("Error: Could not find minimum cost node in non-empty list.")
                return nil
            }
            print("Current cell:", currentCell, "fScore:", totalEstimatedCost[currentCell] ?? -1, "gScore:", startToCurrentDistance[currentCell] ?? -1)
            // Find the index to remove it later (still needed if using Array)
            guard let currentCellIndex = cellsToConsider.firstIndex(of: currentCell) else {
                print("Error: Could not find index of current node.")
                return nil
            }
            // b. Check if current cell is target cell
            if currentCell == targetCell {
                let path = reconstructPath(previousCellInPath: previousCellInPath, startCell: startCell, endCell: targetCell)
                print("Path found:", path)
                return path
            }
            // c. Process Current Node
            cellsToConsider.remove(at: currentCellIndex) // Remove from consideration
            print("Removed current cell from open set. Open set size:", cellsToConsider.count)
            cellsAlreadyEvaluated.insert(currentCell) // Mark as evaluated
            // d. Explore Neighbors
            let neighbors = getNeighbors(of: currentCell)
            print("Neighbors of", currentCell, ":", neighbors)

            for neighborCell in neighbors {
                print("Neighbor state for", neighborCell, "is", neighborCell.cellState)
                // i. Skip if Already Evaluated
                if cellsAlreadyEvaluated.contains(neighborCell) { continue }

                // ii. Calculate Tentative Distance
                let tentativeStartToNeighborDistance = startToCurrentDistance[currentCell, default: Int.max] + 1
                print("Tentative distance to", neighborCell, "via", currentCell, ":", tentativeStartToNeighborDistance)

                // iii. Discover or Update Neighbor
                let neighborIsInConsideration = cellsToConsider.contains(neighborCell)

                if !neighborIsInConsideration {
                    // Discover a new node
                    previousCellInPath[neighborCell] = currentCell
                    startToCurrentDistance[neighborCell] = tentativeStartToNeighborDistance
                    totalEstimatedCost[neighborCell] = tentativeStartToNeighborDistance + heuristic(neighborCell, targetCell)
                    print("Discovered new neighbor:", neighborCell, "gScore:", startToCurrentDistance[neighborCell]!, "fScore:", totalEstimatedCost[neighborCell]!)
                    cellsToConsider.append(neighborCell) // Add to consider list
                    print("Open set now:", cellsToConsider)
                    print("gScores now for", neighborCell, ":", startToCurrentDistance[neighborCell] ?? -1)
                    print("fScores now for", neighborCell, ":", totalEstimatedCost[neighborCell] ?? -1)
                } else if tentativeStartToNeighborDistance < startToCurrentDistance[neighborCell, default: Int.max] {
                    // Found a better path to an existing node in nodesToConsider
                    previousCellInPath[neighborCell] = currentCell
                    startToCurrentDistance[neighborCell] = tentativeStartToNeighborDistance
                    totalEstimatedCost[neighborCell] = tentativeStartToNeighborDistance + heuristic(neighborCell, targetCell)
                    print("Updated neighbor with better path:", neighborCell, "gScore:", startToCurrentDistance[neighborCell]!, "fScore:", totalEstimatedCost[neighborCell]!)
                    print("Open set now:", cellsToConsider)
                    print("gScores now for", neighborCell, ":", startToCurrentDistance[neighborCell] ?? -1)
                    print("fScores now for", neighborCell, ":", totalEstimatedCost[neighborCell] ?? -1)
                    // Note: If using a real priority queue, you'd update the node's priority here.
                }
            }
            print("Loop iteration complete. Open set size:", cellsToConsider.count, "Closed set size:", cellsAlreadyEvaluated.count)
        }
        // 3. No Path Found
        print("No path found.")
        return nil
    }
}
