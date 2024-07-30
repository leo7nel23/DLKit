//
//  VFlow.swift
//
//
//  Created by 賴柏宏 on 2024/7/30.
//

import SwiftUI

public struct VFlow: Layout {
  let alignment: VerticalAlignment
  let verticalSpacing: CGFloat
  let horizontalSpacing: CGFloat

  public init(
    alignment: VerticalAlignment = .center,
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
    let maxHeight = proposal.height ?? 0
    var width: CGFloat = 0
    let columns = generateColumns(maxHeight, proposal, subviews)

    for (index, column) in columns.enumerated() {
      if index == (columns.count - 1) {
        width += column.maxWidth(proposal)
      } else {
        width += column.maxWidth(proposal) + horizontalSpacing
      }
    }

    return CGSize(width: width, height: maxHeight)
  }

  public func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) {
    var origin = bounds.origin
    let maxHeight = bounds.height

    let columns = generateColumns(maxHeight, proposal, subviews)

    for column in columns {
      let top: CGFloat = bounds.maxY - maxHeight
      let bottom = bounds.maxY - (column.reduce(CGFloat.zero) { partialResult, view in
        let height = view.sizeThatFits(proposal).height

        if view == column.last {
          return partialResult + height
        }

        return partialResult + height + verticalSpacing
      })

      let center = (top + bottom) / 2

      origin.y = (alignment == .top ? top : alignment == .bottom ? bottom : center)

      for view in column {
        let viewSize = view.sizeThatFits(proposal)
        view.place(at: origin, proposal: proposal)

        origin.y += (viewSize.width + verticalSpacing)
      }

      origin.x += (column.maxWidth(proposal) + horizontalSpacing)
    }
  }


  func generateColumns(
    _ maxHeight: CGFloat,
    _ proposal: ProposedViewSize,
    _ subviews: Subviews
  ) -> [[LayoutSubviews.Element]] {
    var column: [LayoutSubviews.Element] = []
    var columns: [[LayoutSubviews.Element]] = []

    var origin = CGRect.zero.origin

    for subview in subviews {
      let viewSize = subview.sizeThatFits(proposal)

      if (origin.y + viewSize.height + verticalSpacing) > maxHeight {
        columns.append(column)
        column.removeAll()

        origin.y = 0
        column.append(subview)
        origin.y += (viewSize.height + verticalSpacing)
      } else {
        column.append(subview)
        origin.y += (viewSize.height + verticalSpacing)
      }
    }

    if !column.isEmpty {
      columns.append(column)
      column.removeAll()
    }

    return columns
  }

}

extension [LayoutSubviews.Element] {
  func maxWidth(_ proposal: ProposedViewSize) -> CGFloat {
    compactMap({ $0.sizeThatFits(proposal).width })
      .max() ?? 0
  }
}

#Preview {
  ScrollView(.horizontal) {
    VFlow(alignment: .center, verticalSpacing: 10, horizontalSpacing: 10) {
      ForEach(1...20, id: \.self) { tag in
        Text("AAPL \(tag)")
          .padding(10)
          .background(.blue)
          .clipShape(.capsule)
      }
    }
    .frame(height: 300)
    .padding(50)
    .background(.yellow)
  }
}
