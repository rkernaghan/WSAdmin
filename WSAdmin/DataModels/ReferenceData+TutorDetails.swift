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

		let success = await tutor.loadTutorDetails(tutorNum: idx, tutorDataFileID: tutorDetailsFileID)

		if success {
			tutor.tutorDetailsLoaded = true
		}

		return success
	}
}
