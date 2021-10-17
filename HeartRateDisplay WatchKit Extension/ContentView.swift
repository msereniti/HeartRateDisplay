//
//  ContentView.swift
//  heart-rate-display WatchKit Extension
//
//  Created by Mikhail Kryuchkov on 6/11/21.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        HeartRateController()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDevice("Apple Watch SE - 40mm")
    }
}
