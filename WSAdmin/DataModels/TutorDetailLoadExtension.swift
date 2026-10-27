//
//  ReferenceData+TutorDetails.swift
//  WSAdmin
//

import Foundation

extension ReferenceData {
	/// Ensures the given tutor's Services and Students data has been loaded
	/// before returning. Safe to call from anywhere — if the tutor's details
	/// are already loaded, it returns immediately; otherwise it awaits the
	/// load before returning, so callers can rely on `tutorServices` and
	/// `tutorStudents` being populated as soon as this function returns `true`.
	///
	/// - Parameter tutorID: the tutor's stable ID, looked up fresh each call
	///   rather than trusting a caller-supplied array index that could be stale.
	/// - Returns: `true` if details are loaded (either already, or just now);
	///   `false` if the load was attempted and failed.
	@discardableResult
	func ensureTutorDetailsLoaded(tutorID: Tutor.ID) async -> Bool {
		guard let idx = tutors.tutorsList.firstIndex(where: { $0.id == tutorID }) else {
			return false
		}

		let tutor = tutors.tutorsList[idx]

		if tutor.tutorDetailsLoaded {
			return true
		}

		let success = await tutor.loadTutorDetails()

		if success {
			tutor.tutorDetailsLoaded = true
		}

		return success
	}

	/// Pre-flight optimistic lock check for operations that write ReferenceData and one Tutor's Tutor Details
	/// (assign, unassign, ...).  Loads the Tutor's details if needed, then verifies - without writing - that the
	/// ReferenceData ranges and the Tutor's Tutor Details tab have not been changed outside WSAdmin since they
	/// were loaded.  Call before modifying anything so a conflict stops the whole operation.
	///
	/// - Returns: `nil` if it is safe to proceed, otherwise a message for the user/log.
	func preflightLockCheck(tutorID: Tutor.ID) async -> String? {
		guard let idx = tutors.tutorsList.firstIndex(where: { $0.id == tutorID }) else { return nil }
		let tutorName = tutors.tutorsList[idx].tutorName
		
		guard await ensureTutorDetailsLoaded(tutorID: tutorID) else {
			return "ERROR: could not load Tutor Details for Tutor \(tutorName)"
		}
		do {
			try await SheetVersionStore.shared.verifyUnchanged(fileID: referenceDataFileID)
			try await SheetVersionStore.shared.verifyUnchanged(fileID: tutorDetailsFileID, sheetName: tutorName)
		} catch {
			return "ERROR: \(error.localizedDescription)"
		}
		return nil
	}

	/// Pre-flight optimistic lock check for operations that write only ReferenceData (suspend, delete, ...).
	/// - Returns: `nil` if it is safe to proceed, otherwise a message for the user/log.
	func preflightReferenceDataLockCheck() async -> String? {
		do {
			try await SheetVersionStore.shared.verifyUnchanged(fileID: referenceDataFileID)
		} catch {
			return "ERROR: \(error.localizedDescription)"
		}
		return nil
	}

	/// Pre-flight optimistic lock check for operations on several Tutors (see preflightLockCheck(tutorID:)).
	func preflightLockCheck(tutorIDs: Set<Tutor.ID>) async -> String? {
		if let message = await preflightReferenceDataLockCheck() { return message }
		for tutorID in tutorIDs {
			if let message = await preflightLockCheck(tutorID: tutorID) { return message }
		}
		return nil
	}
}
