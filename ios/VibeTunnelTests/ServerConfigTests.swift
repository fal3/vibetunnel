import XCTest
@testable import VibeTunnel

final class ServerConfigTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testServerConfigInitialization() {
        let config = ServerConfig(
            host: "localhost",
            port: 8080,
            name: "Test Server"
        )
        
        XCTAssertEqual(config.host, "localhost")
        XCTAssertEqual(config.port, 8080)
        XCTAssertEqual(config.name, "Test Server")
    }
    
    func testServerConfigWithoutName() {
        let config = ServerConfig(
            host: "192.168.1.100",
            port: 3000
        )
        
        XCTAssertEqual(config.host, "192.168.1.100")
        XCTAssertEqual(config.port, 3000)
        XCTAssertNil(config.name)
    }
    
    // MARK: - Base URL Tests
    
    func testBaseURLWithLocalhost() {
        let config = ServerConfig(host: "localhost", port: 8080)
        let baseURL = config.baseURL
        
        XCTAssertEqual(baseURL.scheme, "http")
        XCTAssertEqual(baseURL.host, "localhost")
        XCTAssertEqual(baseURL.port, 8080)
        XCTAssertEqual(baseURL.absoluteString, "http://localhost:8080")
    }
    
    func testBaseURLWithIPAddress() {
        let config = ServerConfig(host: "192.168.1.100", port: 3000)
        let baseURL = config.baseURL
        
        XCTAssertEqual(baseURL.scheme, "http")
        XCTAssertEqual(baseURL.host, "192.168.1.100")
        XCTAssertEqual(baseURL.port, 3000)
        XCTAssertEqual(baseURL.absoluteString, "http://192.168.1.100:3000")
    }
    
    func testBaseURLWithDomain() {
        let config = ServerConfig(host: "api.example.com", port: 443)
        let baseURL = config.baseURL
        
        XCTAssertEqual(baseURL.scheme, "http")
        XCTAssertEqual(baseURL.host, "api.example.com")
        XCTAssertEqual(baseURL.port, 443)
        XCTAssertEqual(baseURL.absoluteString, "http://api.example.com:443")
    }
    
    func testBaseURLWithSpecialCharacters() {
        let config = ServerConfig(host: "test-server.local", port: 8080)
        let baseURL = config.baseURL
        
        XCTAssertEqual(baseURL.scheme, "http")
        XCTAssertEqual(baseURL.host, "test-server.local")
        XCTAssertEqual(baseURL.port, 8080)
        XCTAssertEqual(baseURL.absoluteString, "http://test-server.local:8080")
    }
    
    // MARK: - Codable Tests
    
    func testServerConfigCodableRoundTrip() throws {
        let originalConfig = ServerConfig(
            host: "test.example.com",
            port: 9000,
            name: "Test Configuration"
        )
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(originalConfig)
        let decodedConfig = try decoder.decode(ServerConfig.self, from: data)
        
        XCTAssertEqual(originalConfig.host, decodedConfig.host)
        XCTAssertEqual(originalConfig.port, decodedConfig.port)
        XCTAssertEqual(originalConfig.name, decodedConfig.name)
    }
    
    func testServerConfigCodableWithoutName() throws {
        let config = ServerConfig(host: "localhost", port: 8080)
        
        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(ServerConfig.self, from: data)
        
        XCTAssertEqual(decoded.host, "localhost")
        XCTAssertEqual(decoded.port, 8080)
        XCTAssertNil(decoded.name)
    }
    
    func testServerConfigCodableWithEmptyName() throws {
        let config = ServerConfig(host: "localhost", port: 8080, name: "")
        
        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(ServerConfig.self, from: data)
        
        XCTAssertEqual(decoded.host, "localhost")
        XCTAssertEqual(decoded.port, 8080)
        XCTAssertEqual(decoded.name, "")
    }
    
    // MARK: - Equatable Tests
    
    func testServerConfigEquality() {
        let config1 = ServerConfig(host: "localhost", port: 8080, name: "Test")
        let config2 = ServerConfig(host: "localhost", port: 8080, name: "Test")
        let config3 = ServerConfig(host: "localhost", port: 8080, name: "Different")
        let config4 = ServerConfig(host: "different", port: 8080, name: "Test")
        let config5 = ServerConfig(host: "localhost", port: 9000, name: "Test")
        
        XCTAssertEqual(config1, config2)
        XCTAssertNotEqual(config1, config3)
        XCTAssertNotEqual(config1, config4)
        XCTAssertNotEqual(config1, config5)
    }
    
    func testServerConfigEqualityWithNilName() {
        let config1 = ServerConfig(host: "localhost", port: 8080)
        let config2 = ServerConfig(host: "localhost", port: 8080)
        let config3 = ServerConfig(host: "localhost", port: 8080, name: "Test")
        
        XCTAssertEqual(config1, config2)
        XCTAssertNotEqual(config1, config3)
    }
    
    // MARK: - Edge Cases
    
    func testServerConfigWithLargePort() {
        let config = ServerConfig(host: "localhost", port: 65535)
        let baseURL = config.baseURL
        
        XCTAssertEqual(baseURL.port, 65535)
        XCTAssertEqual(baseURL.absoluteString, "http://localhost:65535")
    }
    
    func testServerConfigWithPortZero() {
        let config = ServerConfig(host: "localhost", port: 0)
        let baseURL = config.baseURL
        
        XCTAssertEqual(baseURL.port, 0)
        XCTAssertEqual(baseURL.absoluteString, "http://localhost:0")
    }
    
    func testServerConfigWithSpecialHostCharacters() {
        let config = ServerConfig(host: "test-host_with.underscores", port: 8080)
        let baseURL = config.baseURL
        
        XCTAssertEqual(baseURL.host, "test-host_with.underscores")
        XCTAssertEqual(baseURL.absoluteString, "http://test-host_with.underscores:8080")
    }
    
    func testServerConfigWithLongHostname() {
        let longHostname = "very-long-hostname-that-exceeds-normal-length-limits-for-testing-purposes.example.com"
        let config = ServerConfig(host: longHostname, port: 8080)
        let baseURL = config.baseURL
        
        XCTAssertEqual(baseURL.host, longHostname)
        XCTAssertTrue(baseURL.absoluteString.contains(longHostname))
    }
    
    // MARK: - Performance Tests
    
    func testServerConfigEncodingPerformance() throws {
        let config = ServerConfig(
            host: "performance-test.example.com",
            port: 8080,
            name: "Performance Test Configuration"
        )
        
        measure {
            for _ in 0..<1000 {
                _ = try? JSONEncoder().encode(config)
            }
        }
    }
    
    func testServerConfigDecodingPerformance() throws {
        let config = ServerConfig(host: "localhost", port: 8080, name: "Test")
        let data = try JSONEncoder().encode(config)
        
        measure {
            for _ in 0..<1000 {
                _ = try? JSONDecoder().decode(ServerConfig.self, from: data)
            }
        }
    }
    
    func testBaseURLPerformance() {
        let config = ServerConfig(host: "localhost", port: 8080)
        
        measure {
            for _ in 0..<10000 {
                _ = config.baseURL
            }
        }
    }
} 