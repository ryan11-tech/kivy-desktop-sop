import '../models/member.dart';

abstract class MemberRepository {
  Future<Member?> currentMember();
}

class MockMemberRepository implements MemberRepository {
  const MockMemberRepository({this.member = DemoAccounts.admin});

  final Member member;

  @override
  Future<Member?> currentMember() async {
    return member;
  }
}
