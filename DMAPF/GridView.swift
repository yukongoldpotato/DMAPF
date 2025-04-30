//
//  GridView.swift
//  DMAPF
//
//  Created by Kazuki Minami on 2025/04/29.
//

import SwiftUI

struct GridView: View {
    @State private var showIndex: Bool = false
    @State var grid = MapGrid(size: 8)
    @State private var selectedState: CellState = .occupied
    @State private var pathIndices: [Int] = []
    private let cellSize: CGFloat = 45
    private let spacing: CGFloat = 2

    var body: some View {
        Button("Reset") {
            for i in grid.cells.indices {
                grid.cells[i].cellState = .empty
            }
            pathIndices.removeAll()
        }

        Button("Randomize Start/End") {
            let total = grid.size * grid.size
            var allIndices = Array(0..<total)
            // Clear existing agent1 start/end
            for i in 0..<total {
                if grid.cells[i].cellState == .agent1Start || grid.cells[i].cellState == .agent1End {
                    grid.cells[i].cellState = .empty
                }
            }
            // Pick a random start index
            let startIndex = allIndices.randomElement()!
            let startRow = startIndex / grid.size
            let startCol = startIndex % grid.size

            // Filter end candidates at least 3 cells away (Chebyshev distance)
            let endCandidates = allIndices.filter { idx in
                let row = idx / grid.size
                let col = idx % grid.size
                let dr = abs(row - startRow)
                let dc = abs(col - startCol)
                return max(dr, dc) >= 3
            }
            guard let endIndex = endCandidates.randomElement() else { return }

            grid.cells[startIndex].cellState = .agent1Start
            grid.cells[endIndex].cellState = .agent1End
        }
        .padding(.vertical)

        Button("Compute Path") {
            // clear any previous highlights
            for idx in pathIndices {
                if grid.cells[idx].cellState == .path {
                    grid.cells[idx].cellState = .empty
                }
            }
            pathIndices.removeAll()
            guard let startIndex = grid.cells.firstIndex(where: { $0.cellState == .agent1Start }),
                  let endIndex = grid.cells.firstIndex(where: { $0.cellState == .agent1End }) else { return }
            let startCell = grid.cells[startIndex]
            let endCell = grid.cells[endIndex]

            guard let cellPath = grid.aStarPath(from: startCell, to: endCell) else { return }

            let newPathIndicies = cellPath.map { cell in
                cell.y * grid.size + cell.x
            }

            for index in newPathIndicies where index != startIndex && index != endIndex {
                grid.cells[index].cellState = .path
            }
            pathIndices = newPathIndicies
        }
        .padding(.vertical)

        Grid(horizontalSpacing: spacing, verticalSpacing: spacing) {
            ForEach(0..<grid.size, id: \.self) { row in
                GridRow {
                    ForEach(0..<grid.size, id: \.self) { column in
                        let index = row * grid.size + column
                        var cell = grid.cells[index]
                        Rectangle()
                            .stroke(Color.gray, lineWidth: 1)
                            .fill(cell.cellState.color)
                            .frame(width: cellSize, height: cellSize)
                            .overlay {
                                if cell.cellState == .agent1End {
                                    Text("End")
                                        .font(.caption)
                                } else if cell.cellState == .agent1Start {
                                    Text("Start")
                                        .font(.caption)
                                }
                                if showIndex {
                                    Text("\(index)")
                                        .font(.caption)
                                }
                            }
                            .onTapGesture {
                                print("Tapped cell at index \(index)")
                                grid.cells[index].cellState = selectedState
                            }
                    }
                }
            }
        }
        .padding(4)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let x = value.location.x
                    let y = value.location.y
                    let col = Int(x / (cellSize + spacing))
                    let row = Int(y / (cellSize + spacing))
                    guard (0..<grid.size).contains(col),
                          (0..<grid.size).contains(row)
                    else { return }
                    let swipeIndex = row * grid.size + col
                    if grid.cells[swipeIndex].cellState != .occupied {
                        grid.cells[swipeIndex].cellState = .occupied
                    }
                }
        )
    }
}

#Preview {
    GridView()
}
