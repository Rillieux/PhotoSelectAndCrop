//
//  File.swift
//  
//
//  Created by Dave Kondris on 28/11/21.
//

import SwiftUI

struct RenderingForegroundStyle: ViewModifier {
    let colors: [Color]
    let isGradient: Bool
    let linearGradient: LinearGradient
    func body(content: Content) -> some View {
        if isGradient {
            content.foregroundStyle(linearGradient)
        } else {
            if colors.count == 1 {
                content.foregroundStyle(colors[0])
            } else if colors.count == 2 {
                content.foregroundStyle(colors[0], colors[1])
            } else if colors.count == 3 {
                content.foregroundStyle(colors[0], colors[1], colors[2])
            } else {
                content
            }
        }
    }
}
