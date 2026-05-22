import '../models/member.dart';

class AccessController {
  const AccessController();

  bool canManageContent(Member member) => member.isAdmin;

  bool canReadPublishedContent(Member member) {
    return member.isAdmin || member.isStaff;
  }

  bool canReadDraftContent(Member member) => member.isAdmin;

  bool canManageFavorites(Member member, String uid) {
    return member.isActive && member.uid == uid;
  }
}
