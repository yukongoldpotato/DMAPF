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
    @State private var agents: [Agent] = []
    @State private var agentPaths: [Int : [Cell]] = [:]
    @State private var agentProgress: [Int : Int] = [:]   // tracks the step each agent is on
    @State private var pendingStart: Int? = nil           // tap‑to‑place helper

    private let cellSize: CGFloat = 45
    private let spacing: CGFloat = 2

    @State private var simulationRunning: Bool = false
    @State private var currentTick: Int = 0

    /// Fires every 0.5 s; drives the turn‑based animation
    private let tickTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            Button("Reset") {
                reset()
            }

            HStack {
                Button("Add Agent") { addRandomAgent() }
                Button("Plan All")  { planAll() }
                Button(simulationRunning ? "Stop" : "Run") {
                    if simulationRunning {
                        // Stop
                        simulationRunning = false
                    } else {
                        // Start
                        if agentPaths.isEmpty {
                            planAll()            // auto‑plan if nothing planned yet
                        }
                        currentTick = 0
                        simulationRunning = true
                    }
                }
            }
            .padding(.vertical)

            Grid(horizontalSpacing: spacing, verticalSpacing: spacing) {
                ForEach(0..<grid.size, id: \.self) { row in
                    GridRow {
                        ForEach(0..<grid.size, id: \.self) { column in
                            let index = row * grid.size + column
                            let cell = grid.cells[index]
                            Rectangle()
                                .stroke(Color.gray, lineWidth: 1)
                                .fill(cell.cellState.color)
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
                                .onTapGesture {
                                    placeAgent(at: index)
                                }
                                .frame(width: cellSize, height: cellSize)
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
                        if grid.cells[swipeIndex].cellState == .empty {
                            grid.cells[swipeIndex].cellState = .obstacle
                        }
                    }
            )
            .onReceive(tickTimer) { _ in
                guard simulationRunning else { return }
                advanceOneTick()
            }

        }
    }

    func reset() {
        for i in grid.cells.indices { grid.cells[i].cellState = .empty }
        agents.removeAll()
        agentPaths.removeAll()
        agentProgress.removeAll()
        pendingStart = nil
    }

    /// Adds one agent with random start / goal
    func addRandomAgent() {
        let total = grid.size * grid.size
        let free = grid.cells.indices.filter { grid.cells[$0].cellState == .empty }

        guard free.count > 10 else { return } // not enough space

        let start = free.randomElement()!
        // choose a goal at least 3 chebyshev cells away
        let goalCandidates = free.filter { idx in
            let dr = abs(idx / grid.size - start / grid.size)
            let dc = abs(idx % grid.size - start % grid.size)
            return max(dr, dc) >= 3 && idx != start
        }
        guard let goal = goalCandidates.randomElement() else { return }

        let id = (agents.last?.id ?? 0) + 1
        agents.append(Agent(id: id, start: start, goal: goal))

        grid.cells[start].cellState = .start
        grid.cells[goal].cellState = .end
        
        // Initialize agent count at start position
        grid.cells[start].agentCount += 1
    }

    /// Manually create an agent by tapping: first tap = start, second tap = goal
    private func placeAgent(at index: Int) {
        // require empty cell for either selection
        guard grid.cells[index].cellState == .empty else { return }

        if let start = pendingStart {
            // second tap → goal
            let id = (agents.last?.id ?? 0) + 1
            agents.append(Agent(id: id, start: start, goal: index))
            grid.cells[start].cellState = .start
            grid.cells[index].cellState = .end
            
            // Initialize agent count at start position
            grid.cells[start].agentCount += 1
            pendingStart = nil
        } else {
            // first tap → start
            pendingStart = index
            grid.cells[index].cellState = .start
        }
    }

    /// Plans paths for every agent in order of insertion
    func planAll() {
        // clear previous path cells
        for nodes in agentPaths.values {
            for n in nodes {
                let idx = n.flatIndex(gridSize: grid.size)
                if grid.cells[idx].cellState == .path {
                    grid.cells[idx].cellState = .empty
                }
            }
        }
        agentPaths.removeAll()

        for agent in agents {
            let startCell = grid.cells[agent.start]
            let goalCell  = grid.cells[agent.goal]

            if let nodes = grid.aStarPath(from: startCell,
                                               to: goalCell) {
                agentPaths[agent.id] = nodes
                agentProgress[agent.id] = 0
                for n in nodes where n != startCell && n != goalCell {
                    let idx = n.flatIndex(gridSize: grid.size)
                    grid.cells[idx].cellState = .path
                }
            }
        }
    }
    /// Recalculate a fresh path for every agent on every tick, then move each agent one step.
    private func advanceOneTick() {
        var anyMoved = false

        // 1. Remove previous path‑only markings so we can draw new ones
        for idx in grid.cells.indices where grid.cells[idx].cellState == .path {
            grid.cells[idx].cellState = .empty
        }

        for agent in agents {

            // --- locate this agent’s current position
            let currentCell: Cell
            if let nodes = agentPaths[agent.id],
               let progress = agentProgress[agent.id],
               !nodes.isEmpty
            {
                currentCell = nodes[min(progress, nodes.count - 1)]
            } else {
                currentCell = grid.cells[agent.start]
            }

            // Already at goal?
            if currentCell.flatIndex(gridSize: grid.size) == agent.goal { continue }

            // --- temporarily mark every other agent’s position as occupied for planning
            var reverted: [(idx: Int, old: CellState)] = []
            for other in agents where other.id != agent.id {
                if let otherNodes = agentPaths[other.id],
                   let otherProg  = agentProgress[other.id] {
                    let otherPos   = otherNodes[min(otherProg, otherNodes.count - 1)]
                    let oIdx       = otherPos.flatIndex(gridSize: grid.size)
                    if grid.cells[oIdx].cellState != .occupied {
                        reverted.append((oIdx, grid.cells[oIdx].cellState))
                        grid.cells[oIdx].cellState = .occupied
                    }
                }
            }

            // --- plan a brand‑new path
            let goalCell = grid.cells[agent.goal]
            guard let newPath = grid.aStarPath(from: currentCell, to: goalCell),
                  newPath.count >= 2 else {
                // restore temp changes and continue
                for (idx, old) in reverted { grid.cells[idx].cellState = old }
                continue
            }

            // --- draw the new path
            for n in newPath where n != currentCell && n != goalCell {
                let idx = n.flatIndex(gridSize: grid.size)
                if grid.cells[idx].cellState == .empty {
                    grid.cells[idx].cellState = .path
                }
            }

            // --- store the path and reset progress
            agentPaths[agent.id]    = newPath
            agentProgress[agent.id] = 0

            // --- attempt to move one step
            let nextCell = newPath[1]
            let nextIdx  = nextCell.flatIndex(gridSize: grid.size)

            if grid.cells[nextIdx].cellState != .occupied &&
               grid.cells[nextIdx].cellState != .obstacle {

                // free the current cell (unless it’s a start/end marker)
                let currentIdx = currentCell.flatIndex(gridSize: grid.size)
                if grid.cells[currentIdx].cellState == .occupied {
                    grid.cells[currentIdx].cellState = .path
                }

                // occupy the next cell (unless it’s explicitly an end marker)
                if grid.cells[nextIdx].cellState != .end {
                    grid.cells[nextIdx].cellState = .occupied
                }

                agentProgress[agent.id] = 1   // moved to step 1 of new path
                anyMoved = true
            }

            // --- restore temporarily‑changed cells
            for (idx, old) in reverted { grid.cells[idx].cellState = old }
        }

        currentTick += 1
        if !anyMoved { simulationRunning = false }
    }

}

#Preview {
    GridView()
}
