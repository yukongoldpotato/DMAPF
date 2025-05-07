//
//  GridView.swift
//  DMAPF
//
//  Created by Kazuki Minami on 2025/04/29.
//

import SwiftUI

struct GridView: View {
    @State private var showIndex: Bool = false
    @State var grid = MapGrid(size: 12)
    @State private var selectedState: CellState = .occupied
    @State private var pathIndices: [Int] = []
    @State private var agent1CurrentIndex: Int? = nil
    @State private var agent1TargetIndex: Int? = nil
    @State private var agent1PathIndices: [Int] = []
    @State private var reservations: Reservation = [:]   // global reservation table
    private let cellSize: CGFloat = 45
    private let spacing: CGFloat = 2

    var body: some View {
        VStack {
            Button("Reset") {
                reset()
            }

            HStack {
                Button("Agent 1") {
                    randomizeAgent()
                }
                .padding(.vertical)
            }

            HStack {
                Button("Path 1") {
                    calculatePath()
                }
                .padding(.vertical)
            }
            Grid(horizontalSpacing: spacing, verticalSpacing: spacing) {
                ForEach(0..<grid.size, id: \.self) { row in
                    GridRow {
                        ForEach(0..<grid.size, id: \.self) { column in
                            let index = row * grid.size + column
                            let cell = grid.cells[index]
                            Rectangle()
                                .stroke(Color.gray, lineWidth: 1)
                                .fill(cell.cellState.color)
                                .frame(width: cellSize, height: cellSize)
                                .overlay {
                                    if cell.cellState == .end {
                                        Text("End")
                                            .font(.caption)
                                    } else if cell.cellState == .start {
                                        Text("Start")
                                            .font(.caption)
                                    }
                                    if showIndex {
                                        Text("\(index)")
                                            .font(.caption)
                                    }
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

    func reset(){
        for i in grid.cells.indices {
            grid.cells[i].cellState = .empty
        }
        pathIndices.removeAll()
        pathIndices.removeAll()
        agent1PathIndices.removeAll()
        reservations.removeAll()
    }

    func calculatePath() {
        for idx in pathIndices {
            if grid.cells[idx].cellState == .path {
                grid.cells[idx].cellState = .empty
            }
        }
        pathIndices.removeAll()
        guard let startIndex = grid.cells.firstIndex(where: { $0.cellState == .start }),
              let endIndex = grid.cells.firstIndex(where: { $0.cellState == .end }) else { return }
        let startCell = grid.cells[startIndex]
        let endCell = grid.cells[endIndex]

        guard let cellPath = grid.aStarPathTimed(from: startCell, to: endCell, reserved: &reservations) else { return }

        let newPathIndices = cellPath.map { cell in
            cell.y * grid.size + cell.x
        }

        for index in newPathIndices where index != startIndex && index != endIndex {
            grid.cells[index].cellState = .path
        }
        pathIndices = newPathIndices
    }

    func randomizeAgent() {
        let total = grid.size * grid.size
        var allIndices = Array(0..<total)
        // Clear existing agent1 start/end
        for i in 0..<total {
            if grid.cells[i].cellState == .start || grid.cells[i].cellState == .end {
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

        grid.cells[startIndex].cellState = .start
        grid.cells[endIndex].cellState = .end
    }
}

#Preview {
    GridView()
}
