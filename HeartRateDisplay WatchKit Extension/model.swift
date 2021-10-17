//
//  model.swift
//  HeartRateDisplay WatchKit Extension
//
//  Created by Mikhail Kryuchkov on 6/28/21.
//

import Foundation
import WatchKit

class Model: ObservableObject {
    @Published var session = WKExtendedRuntimeSession()
}
