import Foundation
import Observation
import os.log
import UserNotifications

/// Server session information returned by the API.
///
/// Represents the current state of a terminal session running on the VibeTunnel server,
/// including its command, directory, process status, and activity information.
struct ServerSessionInfo: Codable {
    let id: String
    let name: String
    let command: [String]
    let workingDir: String
    let status: String
    let exitCode: Int?
    let startedAt: String
    let pid: Int?
    let initialCols: Int?
    let initialRows: Int?
    let lastClearOffset: Int?
    let version: String?
    let gitRepoPath: String?
    let gitBranch: String?
    let gitAheadCount: Int?
    let gitBehindCount: Int?
    let gitHasChanges: Bool?
    let gitIsWorktree: Bool?
    let gitMainRepoPath: String?

    // Additional fields from Session (not SessionInfo)
    let lastModified: String
    let active: Bool?
    let activityStatus: ActivityStatus?
    let source: String?
    let remoteId: String?
    let remoteName: String?
    let remoteUrl: String?

    var isRunning: Bool {
        status == "running"
    }
}

/// Activity status for a session.
///
/// Tracks whether a session is actively being used and provides
/// application-specific status information when available.
struct ActivityStatus: Codable {
    let isActive: Bool
    let specificStatus: SpecificStatus?
}

/// App-specific status information.
///
/// Provides detailed status information for specific applications running
/// within a terminal session, such as Claude's current working state.
struct SpecificStatus: Codable {
    let app: String
    let status: String
}

/// Lightweight session monitor that fetches terminal sessions on-demand.
///
/// Manages the collection of active terminal sessions by periodically polling
/// the server API and caching results for efficient access. Provides real-time
/// session information to the UI with minimal network overhead.
@MainActor
@Observable
final class SessionMonitor {
    static let shared = SessionMonitor()

    /// Previous session states for exit detection
    private var previousSessions: [String: ServerSessionInfo] = [:]
    private var firstFetchDone = false

    /// Detect sessions that transitioned from running to not running
    static func detectEndedSessions(
        from old: [String: ServerSessionInfo],
        to new: [String: ServerSessionInfo]
    )
        -> [ServerSessionInfo]
    {
        old.compactMap { id, oldSession in
            if oldSession.isRunning,
               let updated = new[id], !updated.isRunning
            {
                return oldSession
            }
            return nil
        }
    }

    private(set) var sessions: [String: ServerSessionInfo] = [:]
    private(set) var lastError: Error?

    private var lastFetch: Date?
    private let cacheInterval: TimeInterval = 2.0
    private let serverManager = ServerManager.shared
    private let logger = Logger(subsystem: BundleIdentifiers.loggerSubsystem, category: "SessionMonitor")

    /// Reference to GitRepositoryMonitor for pre-caching
    weak var gitRepositoryMonitor: GitRepositoryMonitor?

    /// Timer for periodic refresh
    private var refreshTimer: Timer?

    private init() {
        // Start periodic refresh
        startPeriodicRefresh()
    }

    /// Set the local auth token for server requests
    func setLocalAuthToken(_ token: String?) {}

    /// Number of running sessions
    var sessionCount: Int {
        sessions.values.count { $0.isRunning }
    }

    /// Get all sessions, using cache if available
    func getSessions() async -> [String: ServerSessionInfo] {
        // Use cache if available and fresh
        if let lastFetch, Date().timeIntervalSince(lastFetch) < cacheInterval {
            return sessions
        }

        await fetchSessions()
        return sessions
    }

    /// Force refresh session data
    func refresh() async {
        lastFetch = nil
        await fetchSessions()
    }

    // MARK: - Private Methods

    private func fetchSessions() async {
        do {
            // Snapshot previous sessions for exit notifications
            let oldSessions = sessions

            let sessionsArray = try await serverManager.performRequest(
                endpoint: APIEndpoints.sessions,
                method: "GET",
                responseType: [ServerSessionInfo].self
            )

            // Convert to dictionary
            var sessionsDict: [String: ServerSessionInfo] = [:]
            for session in sessionsArray {
                sessionsDict[session.id] = session
            }

            self.sessions = sessionsDict
            self.lastError = nil

            // Notify for sessions that have just ended
            if firstFetchDone && UserDefaults.standard.bool(forKey: "showNotifications") {
                let ended = Self.detectEndedSessions(from: oldSessions, to: sessionsDict)
                for session in ended {
                    let id = session.id
                    let title = "Session Completed"
                    let displayName = session.name ?? session.command.joined(separator: " ")
                    let content = UNMutableNotificationContent()
                    content.title = title
                    content.body = displayName
                    content.sound = .default
                    let request = UNNotificationRequest(identifier: "session_\(id)", content: content, trigger: nil)
                    do {
                        try await UNUserNotificationCenter.current().add(request)
                    } catch {
                        self.logger
                            .error(
                                "Failed to deliver session notification: \(error.localizedDescription, privacy: .public)"
                            )
                    }
                }
            }

            // Set firstFetchDone AFTER detecting ended sessions
            firstFetchDone = true
            self.lastFetch = Date()

            // Update WindowTracker
            WindowTracker.shared.updateFromSessions(sessionsArray)

            // Pre-cache Git data for all sessions
            if let gitMonitor = gitRepositoryMonitor {
                for session in sessionsArray where gitMonitor.getCachedRepository(for: session.workingDir) == nil {
                    Task {
                        // This will cache the data for immediate access later
                        _ = await gitMonitor.findRepository(for: session.workingDir)
                    }
                }
            }
        } catch {
            // Only update error if it's not a simple connection error
            if !(error is URLError) {
                self.lastError = error
            }
            logger.error("Failed to fetch sessions: \(error, privacy: .public)")
            self.sessions = [:]
            self.lastFetch = Date() // Still update timestamp to avoid hammering
        }
    }

    /// Start periodic refresh of sessions
    private func startPeriodicRefresh() {
        // Clean up any existing timer
        refreshTimer?.invalidate()

        // Create a new timer that fires every 3 seconds
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refresh()
            }
        }
    }
}
