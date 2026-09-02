import Foundation

public final class ToggleDesktopWidgetUseCase: Sendable {
    private let updateConfigUseCase: UpdateConfigUseCase

    public init(updateConfigUseCase: UpdateConfigUseCase) {
        self.updateConfigUseCase = updateConfigUseCase
    }

    public func execute(enabled: Bool? = nil) throws -> Bool {
        var newStatus = false
        _ = try updateConfigUseCase.execute { config in
            if let explicit = enabled {
                config.isDesktopWidgetEnabled = explicit
            } else {
                config.isDesktopWidgetEnabled.toggle()
            }
            newStatus = config.isDesktopWidgetEnabled
        }
        return newStatus
    }
}
