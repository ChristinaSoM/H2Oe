//
//  GraphView.swift
//  H2Oe
//
//  Created by Christina Moser on 27.11.25.
//

import SwiftUI
import Charts

struct GraphView: View {
    var body: some View {
        Chart {
            ForEach(salesData) { data in
                BarMark(
                    x: .value("Month", data.month),
                    y: .value("Sales", data.sales)
                )
            }
        }
        .frame(height: 300)
        .padding()
    }
}

struct SalesData: Identifiable {
    let id = UUID()
    let month: String
    let sales: Int
}

let salesData = [
    SalesData(month: "Jan", sales: 200),
    SalesData(month: "Feb", sales: 150),
    SalesData(month: "Mar", sales: 180),
]



#Preview {
    GraphView()
}
