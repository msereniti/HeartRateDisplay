//
//  RequireInstall.swift
//  HeartRateDisplay
//
//  Created by Mikhail Kryuchkov on 6/27/21.
//

import SwiftUI

struct RequireInstall: View {
    var body: some View {
        VStack {
            Spacer()
            
            VStack(alignment: .leading) {
                Text("watchAppNotInstalled")
                    .font(.title)
                    .multilineTextAlignment(.leading)
                    .padding(.bottom, 20)
                VStack(alignment: .leading) {
                    Text("watchAppNotInstalledInstruction.intro")
                        .padding(.bottom, 10)
                    HStack(alignment: .top) {
                        Text("1.")
                        Text("watchAppNotInstalledInstruction.openApp")
                    }.padding(.bottom, 1)
                    HStack(alignment: .top) {
                        Text("2.")
                        Text("watchAppNotInstalledInstruction.scrollDown")
                    }.padding(.bottom, 1)
                    HStack(alignment: .top) {
                        Text("3.")
                        Text("watchAppNotInstalledInstruction.tapInstall")
                    }.padding(.bottom, 1)
                }
                    .multilineTextAlignment(.leading)
            }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .onAppear() {
                    UIApplication.shared.isIdleTimerDisabled = false
                }
            
            Spacer()
            
           
        }
    }
}
//
//struct RequireInstall_Previews: PreviewProvider {
//    static var previews: some View {
//        RequireInstall().preferredColorScheme(.light).previewInterfaceOrientation(.portraitUpsideDown)
//    }
//}
