//  Server event model for notification handling
//

import Foundation

/// Types of server events that can be received
enum ServerEventType: String, Codable {
    case sessionStart = "session-start"
    case sessionExit = "session-exit"
    case commandFinished = "command-finished"
    case commandError = "command-error"
    case bell = "bell"
    case claudeTurn = "claude-turn"
    case connected = "connected"
}

/// Represents a server event received via Server-Sent Events (SSE)
struct ServerEvent: Codable {
    let type: ServerEventType
    let sessionId: String?
    let sessionName: String?
    let command: String?
    let exitCode: Int?
    let duration: Int?
    let processInfo: String?
    let message: String?
    
    // Regular initializer for creating events manually
    init(
        type: ServerEventType,
        sessionId: String? = nil,
        sessionName: String? = nil,
        command: String? = nil,
        exitCode: Int? = nil,
        duration: Int? = nil,
        processInfo: String? = nil,
        message: String? = nil
    ) {
        self.type = type
        self.sessionId = sessionId
        self.sessionName = sessionName
        self.command = command
        self.exitCode = exitCode
        self.duration = duration
        self.processInfo = processInfo
        self.message = message
    }
} 
