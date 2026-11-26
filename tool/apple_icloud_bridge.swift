import Foundation

private enum RahaCloudError: Error {
  case unavailable, invalidBackup, pendingDownload
}

private enum RahaICloudBridge {
  private static let work = DispatchQueue(label: "raha.icloud.backup")
  private static let limit = 32 * 1024 * 1024
  private static let channelName = "com.raha.life/icloud_backup"

  static func install(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      work.async {
        let response: Any?
        do {
          switch call.method {
          case "check":
            _ = try folder()
            response = true
          case "upload":
            guard let payload = call.arguments as? FlutterStandardTypedData,
                  !payload.data.isEmpty, payload.data.count <= limit
            else { throw RahaCloudError.invalidBackup }
            try upload(payload.data)
            response = nil
          case "downloadLatest":
            response = try downloadLatest()
          default:
            response = FlutterMethodNotImplemented
          }
        } catch RahaCloudError.pendingDownload {
          response = FlutterError(code: "icloud_download_pending",
                                  message: "iCloud is downloading the backup; try again shortly.", details: nil)
        } catch RahaCloudError.unavailable {
          response = FlutterError(code: "icloud_unavailable",
                                  message: "The signed iCloud container or iCloud account is not available.", details: nil)
        } catch {
          response = FlutterError(code: "icloud_backup_failed",
                                  message: "The iCloud backup operation did not complete.", details: nil)
        }
        DispatchQueue.main.async { result(response) }
      }
    }
  }

  private static func folder() throws -> URL {
    let fm = FileManager.default
    guard let id = Bundle.main.object(forInfoDictionaryKey: "RahaICloudContainer") as? String,
          fm.ubiquityIdentityToken != nil,
          let root = fm.url(forUbiquityContainerIdentifier: id)
    else { throw RahaCloudError.unavailable }
    let documents = root.appendingPathComponent("Documents", isDirectory: true)
    try fm.createDirectory(at: documents, withIntermediateDirectories: true)
    return documents
  }

  private static func upload(_ data: Data) throws {
    let name = "raha-\(Int64(Date().timeIntervalSince1970 * 1000))-\(UUID().uuidString.lowercased()).rahabackup"
    let destination = try folder().appendingPathComponent(name)
    let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: tmp) }
    try data.write(to: tmp, options: .atomic)
    try FileManager.default.setUbiquitous(true, itemAt: tmp, destinationURL: destination)
  }

  private static func downloadLatest() throws -> [String: Any]? {
    let fm = FileManager.default
    let home = try folder()
    let items = try fm.contentsOfDirectory(at: home, includingPropertiesForKeys: nil)
    let candidates = items.compactMap { item -> (name: String, stamp: Int64)? in
      var name = item.lastPathComponent
      if name.hasPrefix(".") && name.hasSuffix(".icloud") {
        name = String(name.dropFirst().dropLast(".icloud".count))
      }
      guard name.range(of: #"^raha-[0-9]+-[a-f0-9-]{36}\.rahabackup$"#,
                       options: .regularExpression) != nil,
            let part = name.split(separator: "-").dropFirst().first,
            let stamp = Int64(part)
      else { return nil }
      return (name, stamp)
    }
    guard let latest = candidates.max(by: {
      $0.stamp == $1.stamp ? $0.name < $1.name : $0.stamp < $1.stamp
    }) else { return nil }
    let file = home.appendingPathComponent(latest.name)
    let values = try? file.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey])
    if !fm.fileExists(atPath: file.path) ||
        values?.ubiquitousItemDownloadingStatus == .notDownloaded {
      try fm.startDownloadingUbiquitousItem(at: file)
      throw RahaCloudError.pendingDownload
    }
    var coordinationError: NSError?
    var result: Result<Data, Error> = .failure(RahaCloudError.invalidBackup)
    NSFileCoordinator().coordinate(readingItemAt: file, options: .withoutChanges,
                                   error: &coordinationError) { coordinated in
      result = Result {
        let metadata = try coordinated.resourceValues(
          forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey])
        guard metadata.isRegularFile == true, metadata.isSymbolicLink != true,
              let size = metadata.fileSize, size > 0, size <= limit
        else { throw RahaCloudError.invalidBackup }
        let data = try Data(contentsOf: coordinated)
        guard data.count == size else { throw RahaCloudError.invalidBackup }
        return data
      }
    }
    if let coordinationError = coordinationError { throw coordinationError }
    return ["bytes": FlutterStandardTypedData(bytes: try result.get()),
            "fileName": latest.name, "createdAtMillis": latest.stamp]
  }
}
