//
//  HeartDisplayWatchesConnector.swift
//  heart-rate-display
//
//  Created by Mikhail Kryuchkov on 6/11/21.
//

import SwiftUI
import Communicator


let maxIdleToSupposeWatchesOffline = 30.0 // seconds

enum ConnectionState {
    case ok, measuring, notInstalled, notReachable, unknown
}

struct HeartDisplayWatchesConnector: View {
    @State private var heartRate = 0
    @State private var heartRateMeasured = Date(timeIntervalSinceNow: 0)
    @State private var connectionState = ConnectionState.unknown
    
    @Environment(\.scenePhase) var scenePhase
    private let checkScenePhaseTimer = Timer.publish(every: 30, on: .current, in: .common).autoconnect()
    private let checkWatchesOnlineTimer = Timer.publish(every: 10, on: .current, in: .common).autoconnect()
    
    @State private var watchesBackgroundSessionEnds =  Date(timeIntervalSinceNow: 60 * 60)
    
    var body: some View {
        VStack{
            Group {
                if connectionState == .ok {
                    if (heartRate != 0) {
                        HeartDisplayView(
                            heartRate: heartRate,
                            heartRateMeasured: heartRateMeasured,
                            sessionEnds: watchesBackgroundSessionEnds
                        )
                    } else {
                        ActivityIndicator()
                    }
                } else if connectionState == .measuring {
                    ActivityIndicator()
                } else if connectionState == .notInstalled {
                    RequireInstall()
                } else if connectionState == .notReachable {
                    RequireOpen()
                } else if connectionState == .unknown {
                    RequireOpen()
                }
            }
        }.onAppear(perform: {
            if (Communicator.shared.currentState == .activated) {
                guessCurrentState()
            } else {
                Communicator.State.observe { state in
                    if (state == .activated) {
                        guessCurrentState()
                    }
                }
            }
            listenToStateUpdates()
            listenToWatchMessages()
            checkReachability()
        }).onReceive(checkScenePhaseTimer) { _ in
            if (scenePhase == .active) {
                pingWatches()
            }
        }.onReceive(checkWatchesOnlineTimer) { _ in
            checkReachability()
        }
    }
    
    func checkReachability() {
        if (connectionState == .ok && (Date().timeIntervalSince1970 - heartRateMeasured.timeIntervalSince1970 > maxIdleToSupposeWatchesOffline)) {
            connectionState = .notReachable
        }
        if (Date().timeIntervalSince1970 > watchesBackgroundSessionEnds.timeIntervalSince1970) {
            connectionState = .notReachable
        }
    }
    
    func guessCurrentState() {
        handleReachability(watchState: Communicator.shared.currentWatchState, reachability: Communicator.shared.currentReachability)
    }
    
    func listenToStateUpdates() {
        Reachability.observe { reachability in
            handleReachability(watchState: Communicator.shared.currentWatchState, reachability: reachability)
        }
        WatchState.observe { state in
            handleReachability(watchState: state, reachability: Communicator.shared.currentReachability)
        }
        
    }
    
    func handleReachability(watchState: WatchState, reachability: Reachability) {
        switch watchState.appState {
            case .notInstalled:
                connectionState = ConnectionState.notInstalled
            default:
                switch reachability {
                    case .notReachable:
                        connectionState = ConnectionState.notReachable
                    case .immediatelyReachable:
                        if (connectionState != .ok) {
                            connectionState = .measuring
                            startSession()
                        }
                    case .backgroundOnly:
                        if (
                            connectionState != ConnectionState.ok &&
                                connectionState != ConnectionState.measuring &&
                                Date().timeIntervalSince1970 - heartRateMeasured.timeIntervalSince1970 > 30) {
                            connectionState = ConnectionState.notReachable
                        }

                }
        }
    }
    
    func listenToWatchMessages() {
        ImmediateMessage.observe { message in
            if (message.identifier == "heart-rate") {
                if (connectionState == .measuring) {
                    startSession()
                }
                
                heartRate = message.content["heartRate"] as! Int
                heartRateMeasured = message.content["heartRateMeasured"] as! Date
                connectionState = .ok
            }
            if (message.identifier == "session-started") {
                watchesBackgroundSessionEnds = Date(timeIntervalSinceNow: 60 * 60)
            }
        }
    }
    
    func startSession() {
        pingWatches()
        let message = ImmediateMessage(identifier: "start-session", content: [:])
        Communicator.shared.send(message)
    }
    
    func stopSession() {
        let message = ImmediateMessage(identifier: "stop-session", content: [:])
        Communicator.shared.send(message)
    }
    
    func pingWatches() {
        let message = ImmediateMessage(identifier: "confirm-online", content: [:])
        Communicator.shared.send(message)
    }
}

struct HeartDisplayWatchesConnector_Previews: PreviewProvider {
    static var previews: some View {
        HeartDisplayWatchesConnector()
    }
}

