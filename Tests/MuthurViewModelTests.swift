import XCTest

@testable import muthur

@MainActor
final class MuthurViewModelTests: XCTestCase {
    // MARK: Boot

    func testBootSequenceSeedsThreeLines() {
        let vm = MuthurViewModel()
        vm.bootSequence()
        XCTAssertEqual(vm.consoleLog.count, 3)
        XCTAssertEqual(vm.consoleLog.last?.text, "STANDBY FOR COMMAND...")
    }

    // MARK: Lore command interception

    func testClearPurgesBuffer() async {
        let vm = MuthurViewModel()
        vm.bootSequence()
        vm.currentInput = "clear"
        await vm.processCommand()
        XCTAssertTrue(vm.consoleLog.isEmpty)
    }

    func testCrewStatusIsCaseAndWhitespaceInsensitive() async {
        let vm = MuthurViewModel()
        vm.currentInput = "  crew    STATUS  "
        await vm.processCommand()
        XCTAssertTrue(
            vm.consoleLog.contains { $0.text.contains("NOSTROMO COMPLEMENT") },
            "Expected the crew manifest despite irregular spacing/case"
        )
        // currentInput is cleared once a command is dispatched.
        XCTAssertEqual(vm.currentInput, "")
    }

    func testSpecialOrder937AliasMatches() async {
        let vm = MuthurViewModel()
        vm.currentInput = "order 937"
        await vm.processCommand()
        XCTAssertTrue(vm.consoleLog.contains { $0.text.contains("INSURE RETURN OF ORGANISM") })
    }

    func testEmptyInputIsIgnored() async {
        let vm = MuthurViewModel()
        vm.currentInput = "   "
        await vm.processCommand()
        XCTAssertTrue(vm.consoleLog.isEmpty)
        XCTAssertFalse(vm.isProcessing)
    }

    // MARK: Interactive-tool detection

    func testInteractiveDetectionLooksPastWrappers() {
        XCTAssertTrue(MuthurViewModel.isInteractive("vim notes.txt"))
        XCTAssertTrue(MuthurViewModel.isInteractive("sudo vim /etc/hosts"))
        XCTAssertTrue(MuthurViewModel.isInteractive("env python3"))
        XCTAssertTrue(MuthurViewModel.isInteractive("env FOO=bar python3 script.py"))
        XCTAssertTrue(MuthurViewModel.isInteractive("command top"))
    }

    func testNonInteractiveCommandsRunInline() {
        XCTAssertFalse(MuthurViewModel.isInteractive("ls -la"))
        XCTAssertFalse(MuthurViewModel.isInteractive("echo hi"))
        XCTAssertFalse(MuthurViewModel.isInteractive("sudo ls"))
    }

    func testBaseCommandSkipsAssignmentsAndWrappers() {
        XCTAssertEqual(MuthurViewModel.baseCommand(of: "env FOO=bar python3 x.py"), "python3")
        XCTAssertEqual(MuthurViewModel.baseCommand(of: "sudo vim"), "vim")
        XCTAssertEqual(MuthurViewModel.baseCommand(of: "ls"), "ls")
    }

    // MARK: Scrollback cap

    func testScrollbackIsCappedAtTwoThousandLines() {
        let vm = MuthurViewModel()
        // bootSequence appends 3 lines; 700 calls => 2100 > the 2000 cap.
        for _ in 0 ..< 700 {
            vm.bootSequence()
        }
        XCTAssertEqual(vm.consoleLog.count, 2000)
        // Trimming drops the oldest, so the newest boot line is still present.
        XCTAssertEqual(vm.consoleLog.last?.text, "STANDBY FOR COMMAND...")
    }
}
