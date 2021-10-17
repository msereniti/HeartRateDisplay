//
//  HeartRateController.swift
//  heart-rate-display WatchKit Extension
//
//  Created by Mikhail Kryuchkov on 6/10/21.
//

import SwiftUI
import WatchKit
import HealthKit
import Communicator

let maxIdleToSupposeDeniedPermissions = 15.0 // seconds
let maxIdleToSupposePhoneOffline = 40.0 // seconds

struct HeartRateController: View {
    private var healthStore = HKHealthStore()
    private let heartRateQuantity = HKUnit(from: "count/min")
    
    @State var session = WKExtendedRuntimeSession()
    @State var sessionEstimatedEnd = Date(timeIntervalSince1970: 0)
    @State var lastPhoneOnlineConfirmation = Date(timeIntervalSince1970: 0)
    
    @Environment(\.scenePhase) var scenePhase
    
    @SceneStorage("app.controller.permission_was_granted") private var permission_was_sometime_granted = false
    @SceneStorage("app.controller.never_show_alert") private var neverShowAlert = false
    
    @State var heartRate = 0
    @State var heartRateMeasured = Date(timeIntervalSince1970: 0)
    @State var measured = false
    
    @State var showingErrorAlert = false
    @State var errorTitle: LocalizedStringKey = ""
    @State var errorMessageKey: LocalizedStringKey = ""
    @State var errorMessage: String = ""
    
    let timer = Timer.publish(every: 10, on: .current, in: .common).autoconnect()
    
    var body: some View {
        HeartDisplayView(heartRate: heartRate, heartRateMeasured: heartRateMeasured, measured: measured)
            .onAppear(perform: {
                autorizeHealthKit()
                listenToSessionToggle()
            })
            .alert(isPresented: $showingErrorAlert) {
                if (errorMessageKey != "") {
                    return Alert(
                        title: Text(errorTitle),
                        message: Text(errorMessageKey),
                        primaryButton: .default(Text("alert.hide")),
                        secondaryButton: .destructive(Text("alert.neverShowAgain"), action: { neverShowAlert = true })
                    )
                } else {
                    return Alert(
                        title: Text(errorTitle),
                        message: Text(errorMessage),
                        primaryButton: .default(Text("alert.hide")),
                        secondaryButton: .destructive(Text("alert.neverShowAgain"), action: { neverShowAlert = true })
                    )
                }
            }.onReceive(timer) { time in
                if (
                    !permission_was_sometime_granted &&
                    !showingErrorAlert &&
                    time.timeIntervalSince1970 - heartRateMeasured.timeIntervalSince1970 > maxIdleToSupposeDeniedPermissions &&
                    (scenePhase == .active || session.state == .running)
                ) {
                    showAlert(
                        title: "alert.permission.title",
                        message: "alert.permission.body \(Int(maxIdleToSupposeDeniedPermissions))" as LocalizedStringKey
                    )
                }
                if (time.timeIntervalSince1970 - lastPhoneOnlineConfirmation.timeIntervalSince1970 > maxIdleToSupposePhoneOffline && session.state == .running) {
                    session.invalidate()
                }
            }.onReceive(NotificationCenter.default.publisher(for: WKExtension.applicationWillEnterForegroundNotification), perform: { _ in
                startSession()
            })
    }
    
    func showAlert(title: LocalizedStringKey, message: LocalizedStringKey) {
        if (neverShowAlert) { return }
        
        showingErrorAlert = true
        errorTitle = title
        errorMessageKey = message
        errorMessage = ""
    }
    
    func showAlert(title: LocalizedStringKey, message: String) {
        if (neverShowAlert) { return }
        
        showingErrorAlert = true
        errorTitle = title
        errorMessageKey = ""
        errorMessage = message
    }
    
    func autorizeHealthKit() {
        let healthKitType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        let readPermissionTypes: Set = [healthKitType]
        
        
        healthStore.requestAuthorization(toShare: [], read: readPermissionTypes) { (success, error) in
            if !success {
                showAlert(
                    title: "alert.error.unknown",
                    message: error?.localizedDescription ?? "alert.error.noDescription"
                )
            } else {
                startHeartRateQuery(quantityTypeIdentifier: .heartRate)
            }
        }
    }
    
    func startHeartRateQuery(quantityTypeIdentifier: HKQuantityTypeIdentifier) {
        let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        let updateHandler: (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = {
            query, samples, deletedObjects, queryAnchor, error in
            
            if (error != nil) {
                showAlert(
                    title: "Unknown error occured while trying to access heart rate",
                    message: error?.localizedDescription ?? "no error description"
                )
            }
            
            guard let samples = samples as? [HKQuantitySample] else {
                return
            }
            
            self.process(samples, type: quantityTypeIdentifier)
            
        }
        
        let query = HKAnchoredObjectQuery(type: HKObjectType.quantityType(forIdentifier: quantityTypeIdentifier)!, predicate: devicePredicate, anchor: nil, limit: HKObjectQueryNoLimit, resultsHandler: updateHandler)
        
        query.updateHandler = updateHandler
        
        healthStore.execute(query)
    }
    
    func process(_ samples: [HKQuantitySample], type: HKQuantityTypeIdentifier) {
        var lastHeartRate = 0.0
        
        for sample in samples {
            if type == .heartRate {
                lastHeartRate = sample.quantity.doubleValue(for: heartRateQuantity)
            }
        }
        
        if (lastHeartRate != 0) {
            handleHeartRateUpdate(heartRate: Int(lastHeartRate))
            
            if (!permission_was_sometime_granted) {
                permission_was_sometime_granted = true
            }
        }
    }
    
    func handleHeartRateUpdate(heartRate: Int) {
        self.heartRate = heartRate
        self.heartRateMeasured = Date()
        self.measured = true
        
        self.sendHeartRateUpdateToIPhone()
    }
    
    
    func sendHeartRateUpdateToIPhone() {
        if (Communicator.shared.currentReachability == .immediatelyReachable) {
            let message = ImmediateMessage(identifier: "heart-rate", content:
                                            [
                                                "heartRate" : self.heartRate,
                                                "heartRateMeasured": self.heartRateMeasured
                                            ]
            )
            Communicator.shared.send(message)
        }
    }
    
    func reportSessionStarted() {
        if (Communicator.shared.currentReachability == .immediatelyReachable) {
            let message = ImmediateMessage(identifier: "session-started", content: [:])
            Communicator.shared.send(message)
        }
    }
    
    
    func listenToSessionToggle() {
        ImmediateMessage.observe { message in
            if (message.identifier == "start-session") {
                startSession()
            }
            if (message.identifier == "stop-session") {
                session.invalidate()
            }
            if (message.identifier == "confirm-online") {
                lastPhoneOnlineConfirmation = Date()
            }
        }
    }
    
    func startSession() {
        if (session.state == .running && sessionEstimatedEnd.timeIntervalSince1970 - Date().timeIntervalSince1970 >= 20 * 60) {
            return
        }
        if (session.state == .running) {
            session.invalidate()
        }
        session = WKExtendedRuntimeSession()
        session.start()
        sessionEstimatedEnd = Date(timeIntervalSinceNow: 60 * 60)
        reportSessionStarted()
        sendHeartRateUpdateToIPhone()
    }
}

struct HeartRateController_Previews: PreviewProvider {
    static var previews: some View {
        HeartRateController()
    }
}
