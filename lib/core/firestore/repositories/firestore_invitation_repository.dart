import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/models/account_role.dart';
import '../../auth/models/invitation.dart';
import '../../auth/models/invitation_status.dart';
import '../../auth/repositories/invitation_repository.dart';
import '../firestore_paths.dart';
import '../firestore_service.dart';

class FirestoreInvitationRepository implements InvitationRepository {
  FirestoreInvitationRepository._({FirestoreService? service}) : _service = service ?? FirestoreService();

  static final instance = FirestoreInvitationRepository._();

  final FirestoreService _service;

  @override
  Future<List<Invitation>> invitationsFor({required String organizationId, AccountRole? role}) => fetchInvitationsForOrganization(organizationId, role: role);

  @override
  Future<Invitation?> pendingInvitation({required String organizationId, required AccountRole role, required String email}) async {
    final invitations = await fetchInvitationsForOrganization(organizationId, role: role);
    final normalizedEmail = email.trim().toLowerCase();
    for (final invitation in invitations) {
      if (invitation.status == InvitationStatus.pending && invitation.email.trim().toLowerCase() == normalizedEmail) return invitation;
    }
    return null;
  }

  Future<Invitation?> fetchInvitationById(String organizationId, String invitationId) async {
    if (organizationId.trim().isEmpty || invitationId.trim().isEmpty) return null;
    final snapshot = await _service.invitationDocument(organizationId, invitationId).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    final invitation = Invitation.fromMap({...snapshot.data()!, 'id': snapshot.id});
    if (invitation.organizationId.isNotEmpty && invitation.organizationId != organizationId) {
      throw StateError('This invitation belongs to a different organization and cannot be read here.');
    }
    return invitation;
  }

  Future<Invitation?> fetchInvitationByEmail(String organizationId, String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return null;
    final snapshot = await _service.invitationCollection(organizationId)
        .where('email', isEqualTo: normalizedEmail)
        .limit(2)
        .get();
    if (snapshot.docs.isEmpty) return null;
    if (snapshot.docs.length > 1) {
      throw StateError('Multiple pending invitations were found for the same email in this organization.');
    }
    final invitation = Invitation.fromMap({...snapshot.docs.first.data(), 'id': snapshot.docs.first.id});
    if (invitation.organizationId.isNotEmpty && invitation.organizationId != organizationId) {
      throw StateError('This invitation belongs to a different organization and cannot be read here.');
    }
    return invitation;
  }

  Future<Invitation?> fetchPendingInvitationForAuthenticatedEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return null;
    final snapshot = await _service.firestore
        .collectionGroup(FirestorePaths.invitations)
      .where('recipientEmail', isEqualTo: normalizedEmail)
        .where('role', isEqualTo: AccountRole.organization.name)
        .where('status', isEqualTo: InvitationStatus.pending.name)
        .limit(2)
        .get();
    return _pendingInvitationFromSnapshot(snapshot, normalizedEmail, AccountRole.organization);
  }

  Future<Invitation?> fetchPendingInvitationForEmailAndRole({required String email, required AccountRole role}) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return null;
    final snapshot = await _service.firestore
        .collectionGroup(FirestorePaths.invitations)
      .where('recipientEmail', isEqualTo: normalizedEmail)
        .where('role', isEqualTo: role.name)
        .where('status', isEqualTo: InvitationStatus.pending.name)
        .limit(2)
        .get();
    return _pendingInvitationFromSnapshot(snapshot, normalizedEmail, role);
  }

  Invitation? _pendingInvitationFromSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot, String normalizedEmail, AccountRole role) {
    final invitations = snapshot.docs
        .map((document) => Invitation.fromMap({...document.data(), 'id': document.id}))
        .where((invitation) => invitation.role == role && invitation.email.trim().toLowerCase() == normalizedEmail && invitation.isCurrentlyValid)
        .toList();
    if (invitations.length > 1) {
      throw StateError('Multiple pending invitations were found for the same email.');
    }
    return invitations.isEmpty ? null : invitations.first;
  }

  Future<List<Invitation>> fetchInvitationsForOrganization(String organizationId, {AccountRole? role}) async {
    Query<Map<String, dynamic>> query = _service.invitationCollection(organizationId);
    if (role != null) {
      query = query.where('role', isEqualTo: role.name);
    }
    final snapshot = await query.get();
    return snapshot.docs
        .map((document) => Invitation.fromMap({...document.data(), 'id': document.id}))
        .where((invitation) => invitation.organizationId.isEmpty || invitation.organizationId == organizationId)
        .toList();
  }

  Future<void> createInvitation({required String organizationId, required Invitation invitation}) async {
    _validateInvitationOrganization(organizationId, invitation);
    final safeInvitation = Invitation(
      id: invitation.id,
      email: invitation.email.trim().toLowerCase(),
      role: invitation.role,
      invitedBy: invitation.invitedBy.trim(),
      organizationId: organizationId,
      status: invitation.status,
      doctorId: invitation.doctorId,
      patientId: invitation.patientId,
      clinicId: invitation.clinicId,
      expiresAt: invitation.expiresAt,
      userId: invitation.userId,
      acceptedAt: invitation.acceptedAt,
    );
    await _service.invitationDocument(organizationId, safeInvitation.id).set(safeInvitation.toMap(), SetOptions(merge: true));
  }

  Future<void> saveInvitation({required String organizationId, required Invitation invitation}) async {
    await createInvitation(organizationId: organizationId, invitation: invitation);
  }

  Future<void> updateInvitationStatus({required String organizationId, required String invitationId, required InvitationStatus status}) async {
    final invitation = await fetchInvitationById(organizationId, invitationId);
    if (invitation == null) {
      throw StateError('Invitation not found in the trusted organization context.');
    }
    final updated = invitation.copyWith(status: status);
    await _service.invitationDocument(organizationId, invitationId).set(updated.toMap(), SetOptions(merge: true));
  }

  Future<Invitation> acceptInvitation({required String organizationId, required String invitationId}) async {
    final invitation = await fetchInvitationById(organizationId, invitationId);
    if (invitation == null) {
      throw StateError('Invitation not found in the trusted organization context.');
    }
    if (invitation.status != InvitationStatus.pending) {
      throw StateError('This invitation is no longer pending and cannot be accepted.');
    }
    final accepted = invitation.copyWith(status: InvitationStatus.accepted);
    await _service.invitationDocument(organizationId, invitationId).set(accepted.toMap(), SetOptions(merge: true));
    return accepted;
  }

  Future<void> acceptInvitationForUser({required Invitation invitation, required String uid}) async {
    if (!invitation.isCurrentlyValid) {
      throw StateError('هذه الدعوة غير صالحة أو تم استخدامها من قبل.');
    }
    final invitationReference = _service.invitationDocument(invitation.organizationId, invitation.id);
    final userReference = _service.userDocument(uid);
    await _service.firestore.runTransaction((transaction) async {
      final invitationSnapshot = await transaction.get(invitationReference);
      final userSnapshot = await transaction.get(userReference);
      final currentInvitation = invitationSnapshot.exists && invitationSnapshot.data() != null ? Invitation.fromMap({...invitationSnapshot.data()!, 'id': invitationSnapshot.id}) : null;
      if (currentInvitation == null || !currentInvitation.isCurrentlyValid) {
        throw StateError('هذه الدعوة غير صالحة أو تم استخدامها من قبل.');
      }
      if (userSnapshot.exists) {
        throw StateError('يوجد حساب مستخدم مرتبط بهذا المعرف بالفعل.');
      }
      transaction.set(userReference, {
        'uid': uid,
        'email': invitation.email,
        'role': AccountRole.organization.name,
        'organizationId': invitation.organizationId,
        'clinicId': invitation.clinicId,
        'invitationId': invitation.id,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(invitationReference, {
        'status': InvitationStatus.accepted.name,
        'userId': uid,
        'acceptedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<Invitation> rejectInvitation({required String organizationId, required String invitationId}) async {
    final invitation = await fetchInvitationById(organizationId, invitationId);
    if (invitation == null) {
      throw StateError('Invitation not found in the trusted organization context.');
    }
    final rejected = invitation.copyWith(status: InvitationStatus.cancelled);
    await _service.invitationDocument(organizationId, invitationId).set(rejected.toMap(), SetOptions(merge: true));
    return rejected;
  }

  Future<Invitation> expireInvitation({required String organizationId, required String invitationId}) async {
    final invitation = await fetchInvitationById(organizationId, invitationId);
    if (invitation == null) {
      throw StateError('Invitation not found in the trusted organization context.');
    }
    final expired = invitation.copyWith(status: InvitationStatus.expired);
    await _service.invitationDocument(organizationId, invitationId).set(expired.toMap(), SetOptions(merge: true));
    return expired;
  }

  DocumentReference<Map<String, dynamic>> invitationDocument(String organizationId, String invitationId) =>
      _service.invitationDocument(organizationId, invitationId);

  DocumentReference<Map<String, dynamic>> invitationDocumentForPaths(String organizationId, String invitationId) =>
      _service.invitationDocument(organizationId, invitationId);

  void _validateInvitationOrganization(String organizationId, Invitation invitation) {
    if (organizationId.trim().isEmpty) {
      throw StateError('Organization id is required before saving an invitation.');
    }
    if (invitation.id.trim().isEmpty) {
      throw StateError('Invitation id is required before saving to Firestore.');
    }
    if (invitation.email.trim().isEmpty) {
      throw StateError('Invitation email is required before saving to Firestore.');
    }
    if (invitation.organizationId != organizationId) {
      throw StateError('Invitation organization cannot be changed from the client.');
    }
  }
}
