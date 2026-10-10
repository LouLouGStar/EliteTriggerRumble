import SwiftUI
import GameController
import CoreHaptics

struct ContentView: View {
    @StateObject private var model = ControllerHapticsModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Xbox Elite Series 2")
                        .font(.title2.bold())
                    Text(model.status)
                        .font(.callout)
                        .foregroundColor(model.connected ? .green : .secondary)

                    Button("Refresh / Detect controller") {
                        model.refresh()
                    }

                    Text("Trigger motors")
                        .font(.headline)
                    motorControl(title: "Left trigger (LT)", key: .leftTrigger,
                                   value: $model.leftTrigger, supported: model.leftTriggerSupported)
                    motorControl(title: "Right trigger (RT)", key: .rightTrigger,
                                   value: $model.rightTrigger, supported: model.rightTriggerSupported)

                    Divider()
                    Text("Grip motors")
                        .font(.headline)
                    motorControl(title: "Left grip", key: .leftHandle,
                                   value: $model.leftGrip, supported: model.leftGripSupported)
                    motorControl(title: "Right grip", key: .rightHandle,
                                   value: $model.rightGrip, supported: model.rightGripSupported)

                    Button("Stop all") {
                        model.stopAll()
                    }

                    Text("Hinweis: Die Regler funktionieren nur, wenn iOS den jeweiligen Motor des Controllers als Haptik-Ziel meldet.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("Trigger Rumble")
        }
        .onAppear { model.refresh() }
        .onDisappear { model.stopAll() }
    }

    @ViewBuilder
    private func motorControl(title: String, key: GCHapticsLocality,
                                value: Binding<Double>, supported: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Text("\(Int(value.wrappedValue * 100))%")
            }
            Slider(value: value, in: 0...1, step: 0.05) { editing in
                if !editing {
                    model.apply(key, intensity: value.wrappedValue)
                }
            }
            HStack {
                Text(supported ? "Von iOS gemeldet" : "Nicht als eigener Motor gemeldet")
                    .font(.caption)
                    .foregroundColor(supported ? .green : .orange)
                Spacer()
                Button("Start") { model.apply(key, intensity: value.wrappedValue) }
                    .disabled(!supported || value.wrappedValue <= 0)
                Button("Stop") { model.stop(key) }
            }
        }
        .padding(12)
    }
}

final class ControllerHapticsModel: ObservableObject {
    @Published var status = "Suche nach Controller …"
    @Published var connected = false
    @Published var leftTriggerSupported = false
    @Published var rightTriggerSupported = false
    @Published var leftGripSupported = false
    @Published var rightGripSupported = false
    @Published var leftTrigger = 0.7
    @Published var rightTrigger = 0.7
    @Published var leftGrip = 0.5
    @Published var rightGrip = 0.5

    private var engines: [String: CHHapticEngine] = [:]
    private var players: [String: CHHapticAdvancedPatternPlayer] = [:]
    private var controller: GCController?

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(controllerChanged),
                                               name: .GCControllerDidConnect, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(controllerChanged),
                                               name: .GCControllerDidDisconnect, object: nil)
        GCController.startWirelessControllerDiscovery(completionHandler: {})
        refresh()
    }

    @objc private func controllerChanged() {
        DispatchQueue.main.async { self.refresh() }
    }

    func refresh() {
        GCController.startWirelessControllerDiscovery(completionHandler: {})
        controller = GCController.controllers.first
        guard let controller = controller else {
            connected = false
            leftTriggerSupported = false
            rightTriggerSupported = false
            leftGripSupported = false
            rightGripSupported = false
            status = "Kein Controller erkannt. Verbinde ihn in Bluetooth."
            stopAll()
            return
        }

        connected = true
        let name = controller.vendorName ?? "Gamecontroller"
        let haptics = controller.haptics
        let supported = haptics?.supportedLocalities ?? []
        leftTriggerSupported = supported.contains(.leftTrigger)
        rightTriggerSupported = supported.contains(.rightTrigger)
        leftGripSupported = supported.contains(.leftHandle)
        rightGripSupported = supported.contains(.rightHandle)

        status = "\(name) verbunden."
    }

    func apply(_ locality: GCHapticsLocality, intensity: Double) {
        let key = keyFor(locality)
        stop(locality)
        guard intensity > 0, let haptics = controller?.haptics,
              haptics.supportedLocalities.contains(locality),
              let engine = haptics.createEngine(withLocality: locality) else {
            return
        }

        do {
            let event = CHHapticEvent(eventType: .hapticContinuous,
                                        parameters: [
                                            CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(intensity)),
                                            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                                        ],
                                        relativeTime: 0, duration: 30)
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makeAdvancedPlayer(with: pattern)
            try engine.start()
            try player.start(atTime: 0)
            engines[key] = engine
            players[key] = player
        } catch {
            print("Fehler: \(error)")
        }
    }

    func stop(_ locality: GCHapticsLocality) {
        let key = keyFor(locality)
        try? players[key]?.stop(atTime: 0)
        players.removeValue(forKey: key)
        engines[key]?.stop(completionHandler: nil)
        engines.removeValue(forKey: key)
    }

    func stopAll() {
        for locality in [GCHapticsLocality.leftTrigger, .rightTrigger, .leftHandle, .rightHandle] {
            stop(locality)
        }
    }

    private func keyFor(_ locality: GCHapticsLocality) -> String {
        if locality == .leftTrigger { return "lt" }
        if locality == .rightTrigger { return "rt" }
        if locality == .leftHandle { return "lh" }
        return "rh"
    }
}
