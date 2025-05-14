//
//  Agent.swift
//  DMAPF
//
//  Created by Kazuki Minami on 2025/05/14.
//

import Foundation

/// Agent is identified by its start/end *indices* in `MapGrid.cells`
struct Agent: Identifiable {
    let id: Int
    var start: Int
    var goal: Int
}
