//
//  AdaptiveStack.swift
//  HeartRateDisplay
//
//  Created by Mikhail Kryuchkov on 10/17/21.
//

import SwiftUI

public enum ConfigurableStackOrientation {
    case horizontal
    case vertical
}

struct ConfigurableStack<Content: View>: View {
    var orientation: ConfigurableStackOrientation
    var content: () -> Content
    
    init(orientation: ConfigurableStackOrientation, @ViewBuilder _ content: @escaping () -> Content) {
        self.content = content
        self.orientation = orientation
    }
    
    var body: some View {
        if orientation == .horizontal {
            HStack(content: content)
        } else {
            VStack(content: content)
        }
    }
}
