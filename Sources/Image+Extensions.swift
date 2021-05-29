//
//  Image+Extensions.swift
//  ImageDisplay
//
//  Created by Dave Kondris on 04/03/21.
//

import SwiftUI


extension Image {
    func imageDisplayStyle() -> some View {
        return self
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .aspectRatio(contentMode: .fit)
            .clipShape(Circle())
            .foregroundColor(.gray)
    }
}
