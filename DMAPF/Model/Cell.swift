//
//  GridCell.swift
//  DMAPF
//
//  Created by Kazuki Minami on 2025/04/29.
//


import Foundation
import SwiftUI

enum CellState {
    case empty, occupied, obstacle, start, end, path

    var color: Color {
        switch self {
        case .empty:
            return .white
        case .occupied:
            return .blue
        case .path:
            return .yellow
        case .obstacle:
            return .gray
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

extension Cell {
    /// Converts (x,y) into the flat index used by MapGrid
    func flatIndex(gridSize: Int) -> Int {
        y * gridSize + x
    }

    var displayColor: Color {
        // If the cell is occupied, show different intensities of blue based on agent count
        if cellState == .occupied {
            let intensity = min(1.0, 0.3 + 0.2 * Double(agentCount))
            return Color.blue.opacity(intensity)
        } else {
            return cellState.color
        }
    }
}
