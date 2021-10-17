//
//  ContentView.swift
//  heart-rate-display WatchKit Extension
//
//  Created by Mikhail Kryuchkov on 6/10/21.
//

import SwiftUI

struct HeartDisplayView: View {
    var heartRate = 0
    var heartRateMeasured = Date(timeIntervalSince1970: 0)
    var sessionEnds = Date(timeIntervalSince1970: 0)
    
    // used to rerender last measured text
    @State private var now = Date()
    let timer = Timer.publish(every: 1, on: .current, in: .common).autoconnect()
    
    @EnvironmentObject var orientationInfo: OrientationInfo
    
    var body: some View {
        VStack {
            ConfigurableStack(orientation: orientationInfo.orientation == .landscape ? .horizontal : .vertical) {
                Spacer()
                
                Text("\(heartRate)")
                    .fontWeight(.regular)
                    .font(.system(size: 200))
                    .foregroundColor(Color.primary)
                    .padding(.vertical, orientationInfo.orientation == .portrait ? 100 : 0)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.3)))
                    .id("HeartRateValue\(heartRate)")
                
                Spacer()
                
                HStack{
                    Image(systemName: "heart.circle")
                        .imageScale(.medium)
                        .foregroundColor(.red)
                        .opacity(Date().timeIntervalSince1970 - self.heartRateMeasured.timeIntervalSince1970 < 6 ? 1 : 0.7)
                        .animation(.easeInOut(duration: 0.3))
                        .pulsating(active: Date().timeIntervalSince1970 - self.heartRateMeasured.timeIntervalSince1970 < 6, speed: Double(heartRate))
                        .font(.system(size: 30))
                    
                    
                    VStack{
                        Text("heartRate")
                            .lineLimit(2)
                            .font(.system(size: 30))
                            .foregroundColor(Color.red)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                Spacer()
            }
            
            
            VStack {
                HStack(spacing: 2) {
                    Text("timeInterval.got")
                    Text(Date().getElapsedInterval(from: heartRateMeasured, to: now))
                    Text("timeInterval.ago")
                }
                if (sessionEnds.timeIntervalSince1970 - now.timeIntervalSince1970 < 20 * 60 && sessionEnds.timeIntervalSince1970 - now.timeIntervalSince1970 > 0) {
                    HStack(spacing: 2) {
                        Text("timeInterval.sessionEndsIn")
                        Text(Date().getElapsedInterval(from: now, to: sessionEnds))
                    }
                }
            }.font(.footnote)
            
        }
        .padding(.vertical, 30)
        .onAppear() {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onReceive(timer) { time in
            self.now = time
        }
    }
}

struct HeartDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HeartDisplayView(
                heartRate: 69,
                heartRateMeasured: Date(timeIntervalSinceNow: -1 * 1),
                sessionEnds: Date(timeIntervalSinceNow: 10 * 60)
            )
        }
    }
}
