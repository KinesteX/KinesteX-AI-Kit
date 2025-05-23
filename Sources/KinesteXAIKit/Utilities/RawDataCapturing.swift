// MARK: - RawDataCapturing Protocol

/// Protocol for models that can capture and expose their raw JSON data
public protocol RawDataCapturing {
    /// The raw JSON data
    var rawJSON: [String: Any]? { get }
    
    /// Sets raw JSON data
    mutating func captureRawJSON(_ json: [String: Any]?)
}
