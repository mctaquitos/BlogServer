do {
    try App.run()
} catch {
    Logger.error("Fatal error: \(error)")
    exit(1)
}
