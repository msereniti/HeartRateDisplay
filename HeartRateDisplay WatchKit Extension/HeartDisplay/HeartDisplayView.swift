//
//  ContentView.swift
//  heart-rate-display WatchKit Extension
//
//  Created by Mikhail Kryuchkov on 6/10/21.
//

import SwiftUI

extension Animation {
    func `repeat`(while expression: Bool, autoreverses: Bool = true) -> Animation {
        if expression {
            return self.repeatForever(autoreverses: autoreverses)
        } else {
            return self
        }
    }
}

struct HeartDisplayView: View {
    var heartRate = 0
    var heartRateMeasured = Date(timeIntervalSince1970: 0)
    var measured = false
    
    // used to rerender last measured text
    @State private var now = Date()
    let timer = Timer.publish(every: 1, on: .current, in: .common).autoconnect()
    
    var body: some View {
        VStack{
            HStack{
                Image(systemName: "heart.circle")
                    .imageScale(.large)
                    .foregroundColor(.red)
                    .opacity(Date().timeIntervalSince1970 - self.heartRateMeasured.timeIntervalSince1970 < 6 ? 1 : 0.7)
                    .animation(.easeInOut(duration: 0.3))
                    .pulsating(active: Date().timeIntervalSince1970 - self.heartRateMeasured.timeIntervalSince1970 < 6, speed: Double(heartRate))
                    
                
                VStack{
                    Text("heartRate")
                        .lineLimit(/*@START_MENU_TOKEN@*/2/*@END_MENU_TOKEN@*/)
                        .font(.headline)
                        .foregroundColor(Color.red)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            ZStack {
                Text("\(heartRate)")
                    .fontWeight(.regular)
                    .font(.system(size: 95))
                    .padding(.vertical, -12)
                    .padding(.horizontal, -20)
                    .animation(nil)
                    .opacity(measured ? 1 : 0)
                    .transition(AnyTransition.opacity.animation(.easeInOut(duration: 0.3)))
                    .id("HeartRateValue\(heartRate)")
                        
                
                if (!measured) {
                    ActivityIndicator()
                }
            }
            
            HStack(spacing: 2) {
                if (measured) {
                    Text("timeInterval.got")
                        .fontWeight(.thin)
                        .foregroundColor(Color.gray)
                        .font(.footnote)
                    Text(Date().getElapsedInterval(from: heartRateMeasured, to: now))
                        .fontWeight(.thin)
                        .foregroundColor(Color.gray)
                        .font(.footnote)
                    Text("timeInterval.ago")
                        .fontWeight(.thin)
                        .foregroundColor(Color.gray)
                        .font(.footnote)
                } else {
                    Text("measuring")
                        .fontWeight(.thin)
                        .foregroundColor(Color.gray)
                        .font(.footnote)
                }
            }
            .onReceive(timer) { time in
                self.now = time
            }
        }
        .padding(.vertical, 20)
    }
}

struct HeartDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HeartDisplayView(
                heartRate: 69,
                heartRateMeasured: Date(timeIntervalSinceNow: -1 * 0),
                measured: true
            )
        }
    }
}
