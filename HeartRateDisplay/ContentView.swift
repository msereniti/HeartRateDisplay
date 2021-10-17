//
//  ContentView.swift
//  HeartRateDisplay
//
//  Created by Mikhail Kryuchkov on 6/26/21.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        HeartDisplayWatchesConnector()
            .environmentObject(OrientationInfo())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
