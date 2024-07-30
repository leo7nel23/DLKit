//
//  HFlow.swift
//
//
//  Created by 賴柏宏 on 2024/7/30.
//

import SwiftUI

public struct HFlow: Layout {
  let alignment: HorizontalAlignment
  let verticalSpacing: CGFloat
  let horizontalSpacing: CGFloat

  public init(
    alignment: HorizontalAlignment = .leading,
    verticalSpacing: CGFloat = 8,
    horizontalSpacing: CGFloat = 8
  ) {
    self.alignment = alignment
    self.verticalSpacing = verticalSpacing
    self.horizontalSpacing = horizontalSpacing
  }

  public func sizeThatFits(
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) -> CGSize {
    let maxWidth = proposal.width ?? 0
    var height: CGFloat = 0
    let rows = generateRows(maxWidth, proposal, subviews)

    for (index, row) in rows.enumerated() {
      if index == (rows.count - 1) {
        height += row.maxHeight(proposal)
      } else {
        height += row.maxHeight(proposal) + verticalSpacing
      }
    }

    return CGSize(width: maxWidth, height: height)
  }
  
  public func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) {
    var origin = bounds.origin
    let maxWidth = bounds.width

    let rows = generateRows(maxWidth, proposal, subviews)

    for row in rows {
      let leading: CGFloat = bounds.maxX - maxWidth
      let trailing = bounds.maxX - (row.reduce(CGFloat.zero) { partialResult, view in
        let width = view.sizeThatFits(proposal).width

        if view == row.last {
          return partialResult + width
        }

        return partialResult + width + horizontalSpacing
      })

      let center = (trailing + leading) / 2

      origin.x = (alignment == .leading ? leading : alignment == .trailing ? trailing : center)

      for view in row {
        let viewSize = view.sizeThatFits(proposal)
        view.place(at: origin, proposal: proposal)

        origin.x += (viewSize.width + horizontalSpacing)
      }

      origin.y += (row.maxHeight(proposal) + verticalSpacing)
    }
  }
  

  func generateRows(
    _ maxWidth: CGFloat,
    _ proposal: ProposedViewSize,
    _ subviews: Subviews
  ) -> [[LayoutSubviews.Element]] {
    var row: [LayoutSubviews.Element] = []
    var rows: [[LayoutSubviews.Element]] = []

    var origin = CGRect.zero.origin

    for subview in subviews {
      let viewSize = subview.sizeThatFits(proposal)

      if (origin.x + viewSize.width + horizontalSpacing) > maxWidth {
        rows.append(row)
        row.removeAll()

        origin.x = 0
        row.append(subview)
        origin.x += (viewSize.width + horizontalSpacing)
      } else {
        row.append(subview)
        origin.x += (viewSize.width + horizontalSpacing)
      }
    }

    if !row.isEmpty {
      rows.append(row)
      row.removeAll()
    }

    return rows
  }

}

extension [LayoutSubviews.Element] {
  func maxHeight(_ proposal: ProposedViewSize) -> CGFloat {
    compactMap({ $0.sizeThatFits(proposal).height })
      .max() ?? 0
  }
}

//#Preview {
//  ScrollView(.vertical) {
//    HFlow(alignment: .trailing, verticalSpacing: 10, horizontalSpacing: 10) {
//      ForEach(1...100, id: \.self) { tag in
//        Text("AAPL")
//          .padding(10)
//          .background(.blue)
//          .clipShape(.capsule)
//      }
//    }
//    .padding(50)
//  }
//}
