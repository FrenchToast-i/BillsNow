import Foundation

// Decodes the live ESPN scoreboard / schedule / summary with the exact code
// the app ships, then prints a one-line summary. Exit 0 = the decoder works
// against the current data shape; exit 1 = something broke (and the error
// message names the exact field).

let semaphore = DispatchSemaphore(value: 0)
Task {
    do {
        let result = try await ESPNClient.selfTest()
        print("DECODE CHECK PASSED: \(result)")
    } catch {
        print("DECODE CHECK FAILED: \(error.localizedDescription)")
        exit(1)
    }
    semaphore.signal()
}
semaphore.wait()