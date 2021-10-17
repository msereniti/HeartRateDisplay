//
//  RequireOpen.swift
//  HeartRateDisplay
//
//  Created by Mikhail Kryuchkov on 6/27/21.
//

import SwiftUI

struct AppIcon: View {
    var color = Color.gray
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 40, height: 40)
    }
}

struct RequireOpen: View {
    @State var watchVisible = false
    @State var tapSimulated = false
    @State var tapSimulationVisible = true
    
    @State var animationRunning = false
    
    @EnvironmentObject var orientationInfo: OrientationInfo
    
    var body: some View {
        ConfigurableStack(orientation: orientationInfo.orientation == .landscape ? .horizontal : .vertical) {
            Spacer()
            VStack(alignment: .leading) {
                Text("openWatchApp")
                    .font(.title)
                    .padding(.bottom, 20)
                Text("openWatchAppInstruction")
            }.padding(25)
            Spacer()
            ZStack {
                Image("apple_watch").resizable()
                    .aspectRatio(contentMode: orientationInfo.orientation == .landscape ? .fill : .fit)
                VStack {
                    HStack {
                        AppIcon()
                        AppIcon()
                    }
                    HStack {
                        AppIcon()
                        AppIcon()
                        AppIcon()
                    }
                    HStack {
                        AppIcon()
                            .opacity(0)
                        AppIcon()
                        AppIcon()
                        ZStack {
                            AppIcon(color: Color.blue)
                                .overlay(
                                    Image("AppIconToOpen")
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                )
                            Circle()
                                .fill(Color.white)
                                .frame(width: 40, height: 40)
                                .opacity(tapSimulated && tapSimulationVisible ? 0.8 : 0)
                                .animation(.spring(), value: tapSimulated && tapSimulationVisible)
                                .scaleEffect(tapSimulated ? 1.5 : 0.1)
                                .animation(.spring(), value: tapSimulated)
                        }
                    }
                }
            }
                .padding(30)
                .frame(maxWidth: 400)
                .opacity(watchVisible ? 1 : 0)
                .animation(.easeOut(duration: 1.0), value: watchVisible)
                .offset(x: 0, y: watchVisible  ? 0 : 50)
                .animation(.easeOut(duration: 1.0), value: watchVisible)
                .onAppear {
                    if (watchVisible) {
                        return
                    }
                        
                    UIApplication.shared.isIdleTimerDisabled = false
                    
                    watchVisible.toggle()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        runAnimation()
                    }
                }.onTapGesture {
                    if (!animationRunning) {
                        runAnimation()
                    }
                }
        }
    }
    
    func runAnimation() {
        animationRunning = true
        tapSimulated.toggle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            tapSimulationVisible.toggle()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            tapSimulated.toggle()
            tapSimulationVisible.toggle()
            animationRunning = false
        }
    }
}

struct RequireOpen_Previews: PreviewProvider {
    static var previews: some View {
        RequireOpen().preferredColorScheme(.light).environmentObject(OrientationInfo())
    }
}
