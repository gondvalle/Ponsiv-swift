import Foundation
import Logging

public enum Log {
    public static var core: Logger {
        var logger = Logger(label: "com.ponsiv.core")
        #if DEBUG
        logger.logLevel = .debug
        #else
        logger.logLevel = .info
        #endif
        return logger
    }
}
