import Foundation
import Testing
import FocusModel
@testable import FocusMedication

@Suite("Dose log — guard, audit, undo (spec §7.2, §8.2 rules 7–9)")
struct DoseLogTests {
    let vyvanse = Product(displayName: "Vyvanse 50 mg", formulation: .lisdexamfetamine, minimumRelogInterval: 6 * 3600)
    let ritalin = Product(displayName: "Ritalin 10", formulation: .methylphenidateIR, minimumRelogInterval: 2 * 3600)
    let morning = Date(timeIntervalSince1970: 1_792_000_000) // fixed clock for determinism

    @Test func firstLogIsWrittenAndAudited() async throws {
        let log = DoseLog(products: [vyvanse])
        let outcome = try await log.record(DoseLogRequest(product: vyvanse.id, takenAt: morning),
                                           by: UserGesture(origin: .watchButton, at: morning))
        guard case .logged(let event) = outcome else { Issue.record("expected .logged"); return }
        #expect(event.takenAt == morning)
        #expect(await log.audit.map(\.action) == [.logged])
    }

    @Test func secondLogInsideIntervalNeedsDeliberateConfirmAndWritesNothing() async throws {
        let log = DoseLog(products: [vyvanse])
        let gesture = UserGesture(origin: .button, at: morning.addingTimeInterval(3 * 3600))
        _ = try await log.record(DoseLogRequest(product: vyvanse.id, takenAt: morning), by: UserGesture(origin: .button, at: morning))
        let outcome = try await log.record(DoseLogRequest(product: vyvanse.id, takenAt: morning.addingTimeInterval(3 * 3600)), by: gesture)
        guard case .needsDeliberateConfirm(let previous) = outcome else { Issue.record("guard did not fire"); return }
        #expect(previous.takenAt == morning)
        let day = DateInterval(start: morning.addingTimeInterval(-3600), duration: 86_400)
        #expect(await log.doses(in: day).count == 1)
    }

    @Test func confirmedDuplicateIsWrittenWithDistinctAuditAction() async throws {
        let log = DoseLog(products: [vyvanse])
        let first = try await log.record(DoseLogRequest(product: vyvanse.id, takenAt: morning), by: UserGesture(origin: .button, at: morning))
        guard case .logged(let firstEvent) = first else { return }
        let later = morning.addingTimeInterval(3 * 3600)
        _ = try await log.recordConfirmingDuplicate(DoseLogRequest(product: vyvanse.id, takenAt: later),
                                                    previous: firstEvent.id, by: UserGesture(origin: .button, at: later))
        #expect(await log.audit.map(\.action) == [.logged, .loggedAfterConfirm])
    }

    @Test func differentProductIsNotGuarded() async throws {
        let log = DoseLog(products: [vyvanse, ritalin])
        _ = try await log.record(DoseLogRequest(product: vyvanse.id, takenAt: morning), by: UserGesture(origin: .button, at: morning))
        let booster = morning.addingTimeInterval(5 * 3600)
        let outcome = try await log.record(DoseLogRequest(product: ritalin.id, takenAt: booster, isBooster: true),
                                           by: UserGesture(origin: .button, at: booster))
        guard case .logged = outcome else { Issue.record("booster of another product should log"); return }
    }

    @Test func aMedicationAddedLaterCanBeLoggedAndIsGuarded() async throws {
        let log = DoseLog(products: [vyvanse])
        let unknown = try? await log.record(DoseLogRequest(product: ritalin.id, takenAt: morning), by: UserGesture(origin: .button, at: morning))
        #expect(unknown == nil, "an unregistered product can't be logged")
        await log.register(ritalin)
        let first = try await log.record(DoseLogRequest(product: ritalin.id, takenAt: morning), by: UserGesture(origin: .button, at: morning))
        guard case .logged = first else { Issue.record("a registered product should log"); return }
        let again = morning.addingTimeInterval(60)
        let second = try await log.record(DoseLogRequest(product: ritalin.id, takenAt: again), by: UserGesture(origin: .button, at: again))
        guard case .needsDeliberateConfirm = second else { Issue.record("the guard applies to products added later"); return }
    }

    @Test func undoRemovesTheEventAndKeepsAnAuditTrail() async throws {
        let log = DoseLog(products: [vyvanse])
        let outcome = try await log.record(DoseLogRequest(product: vyvanse.id, takenAt: morning), by: UserGesture(origin: .button, at: morning))
        guard case .logged(let event) = outcome else { return }
        try await log.undo(event.id, by: UserGesture(origin: .button, at: morning.addingTimeInterval(5)))
        #expect(await log.lastDose(of: vyvanse.id) == nil)
        #expect(await log.audit.map(\.action) == [.logged, .undone])
    }

    @Test func futureDosesAreRejected() async {
        let log = DoseLog(products: [vyvanse])
        await #expect(throws: DomainError.self) {
            _ = try await log.record(DoseLogRequest(product: vyvanse.id, takenAt: morning.addingTimeInterval(3600)),
                                     by: UserGesture(origin: .button, at: morning))
        }
    }
}
