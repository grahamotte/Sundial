import Foundation
import SwiftUI

@main
enum SundialMain {
    static func main() {
        let arguments = CommandLine.arguments
        guard arguments.count == 3, arguments[1] == "run" else {
            SundialApp.main()
            return
        }
        do {
            let runner = JobRunner(paths: .standard, launcher: SystemProcessLauncher())
            exit(try runner.run(jobID: arguments[2]))
        } catch {
            FileHandle.standardError.write(Data("sundial: \(error.localizedDescription)\n".utf8))
            exit(1)
        }
    }
}
