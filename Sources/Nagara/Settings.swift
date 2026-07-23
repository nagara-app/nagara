import Foundation

struct Settings {
    private let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    var lastChannelID: String? {
        get { defaults.string(forKey: "lastChannelID") }
        set { defaults.set(newValue, forKey: "lastChannelID") }
    }
    var sliderValue: Double {
        get {
            defaults.object(forKey: "sliderValue") == nil
                ? 0.5 : defaults.double(forKey: "sliderValue")
        }
        set { defaults.set(newValue, forKey: "sliderValue") }
    }
}
