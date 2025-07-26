import XCTest
@testable import VibeTunnel

final class SessionTests: XCTestCase {
    
    // MARK: - Basic Initialization Tests
    
    func testSessionInitialization() {
        let session = Session(
            id: "test-session-123",
            command: ["ls", "-la"],
            workingDir: "/path/to/working/dir",
            name: "Test Session",
            status: .running,
            exitCode: nil,
            startedAt: "2024-01-01T12:00:00Z",
            lastModified: "2024-01-01T12:01:00Z",
            pid: 12345,
            width: 80,
            height: 24,
            waiting: false,
            source: "local",
            remoteId: nil,
            remoteName: nil,
            remoteUrl: nil
        )
        
        XCTAssertEqual(session.id, "test-session-123")
        XCTAssertEqual(session.command, ["ls", "-la"])
        XCTAssertEqual(session.workingDir, "/path/to/working/dir")
        XCTAssertEqual(session.name, "Test Session")
        XCTAssertEqual(session.status, .running)
        XCTAssertNil(session.exitCode)
        XCTAssertEqual(session.startedAt, "2024-01-01T12:00:00Z")
        XCTAssertEqual(session.lastModified, "2024-01-01T12:01:00Z")
        XCTAssertEqual(session.pid, 12345)
        XCTAssertEqual(session.width, 80)
        XCTAssertEqual(session.height, 24)
        XCTAssertEqual(session.waiting, false)
        XCTAssertEqual(session.source, "local")
        XCTAssertNil(session.remoteId)
        XCTAssertNil(session.remoteName)
        XCTAssertNil(session.remoteUrl)
    }
    
    func testSessionWithMinimalFields() {
        let session = Session(
            id: "minimal-session",
            command: ["echo", "hello"],
            workingDir: "/tmp",
            name: nil,
            status: .exited,
            exitCode: 0,
            startedAt: "2024-01-01T12:00:00Z",
            lastModified: nil,
            pid: nil,
            width: nil,
            height: nil,
            waiting: nil,
            source: nil,
            remoteId: nil,
            remoteName: nil,
            remoteUrl: nil
        )
        
        XCTAssertEqual(session.id, "minimal-session")
        XCTAssertEqual(session.command, ["echo", "hello"])
        XCTAssertEqual(session.workingDir, "/tmp")
        XCTAssertNil(session.name)
        XCTAssertEqual(session.status, .exited)
        XCTAssertEqual(session.exitCode, 0)
        XCTAssertEqual(session.startedAt, "2024-01-01T12:00:00Z")
        XCTAssertNil(session.lastModified)
        XCTAssertNil(session.pid)
        XCTAssertNil(session.width)
        XCTAssertNil(session.height)
        XCTAssertNil(session.waiting)
        XCTAssertNil(session.source)
    }
    
    // MARK: - Codable Tests
    
    func testSessionCodableRoundTrip() throws {
        let originalSession = Session(
            id: "codable-test",
            command: ["npm", "install"],
            workingDir: "/project",
            name: "NPM Install",
            status: .running,
            exitCode: nil,
            startedAt: "2024-01-01T12:00:00Z",
            lastModified: "2024-01-01T12:05:00Z",
            pid: 67890,
            width: 120,
            height: 30,
            waiting: true,
            source: "remote",
            remoteId: "remote-123",
            remoteName: "Remote Server",
            remoteUrl: "https://remote.example.com"
        )
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(originalSession)
        let decodedSession = try decoder.decode(Session.self, from: data)
        
        XCTAssertEqual(originalSession.id, decodedSession.id)
        XCTAssertEqual(originalSession.command, decodedSession.command)
        XCTAssertEqual(originalSession.workingDir, decodedSession.workingDir)
        XCTAssertEqual(originalSession.name, decodedSession.name)
        XCTAssertEqual(originalSession.status, decodedSession.status)
        XCTAssertEqual(originalSession.exitCode, decodedSession.exitCode)
        XCTAssertEqual(originalSession.startedAt, decodedSession.startedAt)
        XCTAssertEqual(originalSession.lastModified, decodedSession.lastModified)
        XCTAssertEqual(originalSession.pid, decodedSession.pid)
        XCTAssertEqual(originalSession.width, decodedSession.width)
        XCTAssertEqual(originalSession.height, decodedSession.height)
        XCTAssertEqual(originalSession.waiting, decodedSession.waiting)
        XCTAssertEqual(originalSession.source, decodedSession.source)
        XCTAssertEqual(originalSession.remoteId, decodedSession.remoteId)
        XCTAssertEqual(originalSession.remoteName, decodedSession.remoteName)
        XCTAssertEqual(originalSession.remoteUrl, decodedSession.remoteUrl)
    }
    
    // MARK: - Identifiable Tests
    
    func testSessionIdentifiable() {
        let session = Session(
            id: "identifiable-test",
            command: ["test"],
            workingDir: "/tmp",
            name: nil,
            status: .running,
            exitCode: nil,
            startedAt: "2024-01-01T12:00:00Z",
            lastModified: nil,
            pid: nil,
            width: nil,
            height: nil,
            waiting: nil,
            source: nil,
            remoteId: nil,
            remoteName: nil,
            remoteUrl: nil
        )
        
        // Test that it conforms to Identifiable
        let id: String = session.id
        XCTAssertEqual(id, "identifiable-test")
    }
    
    // MARK: - Equatable Tests
    
    func testSessionEquality() {
        let session1 = Session(
            id: "equality-test",
            command: ["ls"],
            workingDir: "/tmp",
            name: "Test",
            status: .running,
            exitCode: nil,
            startedAt: "2024-01-01T12:00:00Z",
            lastModified: nil,
            pid: nil,
            width: nil,
            height: nil,
            waiting: nil,
            source: nil,
            remoteId: nil,
            remoteName: nil,
            remoteUrl: nil
        )
        
        let session2 = Session(
            id: "equality-test",
            command: ["ls"],
            workingDir: "/tmp",
            name: "Test",
            status: .running,
            exitCode: nil,
            startedAt: "2024-01-01T12:00:00Z",
            lastModified: nil,
            pid: nil,
            width: nil,
            height: nil,
            waiting: nil,
            source: nil,
            remoteId: nil,
            remoteName: nil,
            remoteUrl: nil
        )
        
        let session3 = Session(
            id: "different-test",
            command: ["ls"],
            workingDir: "/tmp",
            name: "Test",
            status: .running,
            exitCode: nil,
            startedAt: "2024-01-01T12:00:00Z",
            lastModified: nil,
            pid: nil,
            width: nil,
            height: nil,
            waiting: nil,
            source: nil,
            remoteId: nil,
            remoteName: nil,
            remoteUrl: nil
        )
        
        XCTAssertEqual(session1, session2)
        XCTAssertNotEqual(session1, session3)
    }
    
    // MARK: - Hashable Tests
    
    func testSessionHashable() {
        let session1 = Session(
            id: "hashable-test",
            command: ["test"],
            workingDir: "/tmp",
            name: "Test",
            status: .running,
            exitCode: nil,
            startedAt: "2024-01-01T12:00:00Z",
            lastModified: nil,
            pid: nil,
            width: nil,
            height: nil,
            waiting: nil,
            source: nil,
            remoteId: nil,
            remoteName: nil,
            remoteUrl: nil
        )
        
        let session2 = Session(
            id: "hashable-test",
            command: ["test"],
            workingDir: "/tmp",
            name: "Test",
            status: .running,
            exitCode: nil,
            startedAt: "2024-01-01T12:00:00Z",
            lastModified: nil,
            pid: nil,
            width: nil,
            height: nil,
            waiting: nil,
            source: nil,
            remoteId: nil,
            remoteName: nil,
            remoteUrl: nil
        )
        
        XCTAssertEqual(session1.hashValue, session2.hashValue)
        
        var set = Set<Session>()
        set.insert(session1)
        set.insert(session2)
        
        XCTAssertEqual(set.count, 1) // Should only have one unique item
    }
    
    // MARK: - Edge Cases
    
    func testSessionWithEmptyCommand() {
        let session = Session(
            id: "empty-command",
            command: [],
            workingDir: "/tmp",
            name: nil,
            status: .running,
            exitCode: nil,
            startedAt: "2024-01-01T12:00:00Z",
            lastModified: nil,
            pid: nil,
            width: nil,
            height: nil,
            waiting: nil,
            source: nil,
            remoteId: nil,
            remoteName: nil,
            remoteUrl: nil
        )
        
        XCTAssertTrue(session.command.isEmpty)
    }
    
    func testSessionWithSpecialCharacters() {
        let session = Session(
            id: "special-chars",
            command: ["echo", "Hello, World!", "&&", "echo", "\"quoted\""],
            workingDir: "/path/with spaces/and\"quotes\"",
            name: "Session with \"quotes\" and 'apostrophes'",
            status: .running,
            exitCode: nil,
            startedAt: "2024-01-01T12:00:00Z",
            lastModified: nil,
            pid: nil,
            width: nil,
            height: nil,
            waiting: nil,
            source: nil,
            remoteId: nil,
            remoteName: nil,
            remoteUrl: nil
        )
        
        XCTAssertEqual(session.command, ["echo", "Hello, World!", "&&", "echo", "\"quoted\""])
        XCTAssertEqual(session.workingDir, "/path/with spaces/and\"quotes\"")
        XCTAssertEqual(session.name, "Session with \"quotes\" and 'apostrophes'")
    }
    
    func testSessionWithLargeNumbers() {
        let session = Session(
            id: "large-numbers",
            command: ["test"],
            workingDir: "/tmp",
            name: nil,
            status: .running,
            exitCode: Int.max,
            startedAt: "2024-01-01T12:00:00Z",
            lastModified: nil,
            pid: Int.max,
            width: Int.max,
            height: Int.max,
            waiting: nil,
            source: nil,
            remoteId: nil,
            remoteName: nil,
            remoteUrl: nil
        )
        
        XCTAssertEqual(session.exitCode, Int.max)
        XCTAssertEqual(session.pid, Int.max)
        XCTAssertEqual(session.width, Int.max)
        XCTAssertEqual(session.height, Int.max)
    }
    
    // MARK: - Performance Tests
    
    func testSessionEncodingPerformance() throws {
        let session = Session(
            id: "performance-test",
            command: ["long", "command", "with", "many", "arguments"],
            workingDir: "/very/long/working/directory/path",
            name: "Performance Test Session with Long Name",
            status: .running,
            exitCode: nil,
            startedAt: "2024-01-01T12:00:00Z",
            lastModified: "2024-01-01T12:05:00Z",
            pid: 12345,
            width: 120,
            height: 30,
            waiting: true,
            source: "remote",
            remoteId: "remote-123",
            remoteName: "Remote Server Name",
            remoteUrl: "https://very-long-url.example.com/path/to/resource"
        )
        
        measure {
            for _ in 0..<1000 {
                _ = try? JSONEncoder().encode(session)
            }
        }
    }
    
    func testSessionDecodingPerformance() throws {
        let session = Session(
            id: "perf-test",
            command: ["test"],
            workingDir: "/tmp",
            name: "Test",
            status: .running,
            exitCode: nil,
            startedAt: "2024-01-01T12:00:00Z",
            lastModified: nil,
            pid: nil,
            width: nil,
            height: nil,
            waiting: nil,
            source: nil,
            remoteId: nil,
            remoteName: nil,
            remoteUrl: nil
        )
        
        let data = try JSONEncoder().encode(session)
        
        measure {
            for _ in 0..<1000 {
                _ = try? JSONDecoder().decode(Session.self, from: data)
            }
        }
    }
} 