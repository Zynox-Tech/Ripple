import 'package:cloud_firestore/cloud_firestore.dart';

class RippleUser {
  final String uid;
  final String displayName;
  final String email;
  final String photoURL;
  final String area;
  final String city;
  final bool verified;
  final String subscriptionTier; // free / premium / insightplus
  final DateTime createdAt;
  final DateTime lastActive;
  final String? streetAddress;
  final String? houseNo;
  final String? postcode;
  final double? latitude;
  final double? longitude;
  final String? phoneNumber;
  final int? age;
  final String? gender;

  RippleUser({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.photoURL,
    required this.area,
    required this.city,
    required this.verified,
    required this.subscriptionTier,
    required this.createdAt,
    required this.lastActive,
    this.streetAddress,
    this.houseNo,
    this.postcode,
    this.latitude,
    this.longitude,
    this.phoneNumber,
    this.age,
    this.gender,
  });

  RippleUser copyWith({
    String? displayName,
    String? email,
    String? photoURL,
    String? area,
    String? city,
    bool? verified,
    String? subscriptionTier,
    DateTime? lastActive,
    String? streetAddress,
    String? houseNo,
    String? postcode,
    double? latitude,
    double? longitude,
    String? phoneNumber,
    int? age,
    String? gender,
  }) {
    return RippleUser(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      area: area ?? this.area,
      city: city ?? this.city,
      verified: verified ?? this.verified,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      createdAt: createdAt,
      lastActive: lastActive ?? this.lastActive,
      streetAddress: streetAddress ?? this.streetAddress,
      houseNo: houseNo ?? this.houseNo,
      postcode: postcode ?? this.postcode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      age: age ?? this.age,
      gender: gender ?? this.gender,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'area': area,
      'city': city,
      'verified': verified,
      'subscriptionTier': subscriptionTier,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(lastActive),
      'streetAddress': streetAddress,
      'houseNo': houseNo,
      'postcode': postcode,
      'latitude': latitude,
      'longitude': longitude,
      'phoneNumber': phoneNumber,
      'age': age,
      'gender': gender,
    };
  }

  factory RippleUser.fromMap(Map<String, dynamic> map) {
    return RippleUser(
      uid: map['uid'] ?? '',
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      photoURL: map['photoURL'] ?? '',
      area: map['area'] ?? '',
      city: map['city'] ?? '',
      verified: map['verified'] ?? false,
      subscriptionTier: map['subscriptionTier'] ?? 'free',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActive: (map['lastActive'] as Timestamp?)?.toDate() ?? DateTime.now(),
      streetAddress: map['streetAddress'],
      houseNo: map['houseNo'],
      postcode: map['postcode'],
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      phoneNumber: map['phoneNumber'],
      age: map['age'] != null ? (map['age'] as num).toInt() : null,
      gender: map['gender'],
    );
  }
}

class Child {
  final String childId;
  final String firstName;
  final String gradeYear; // e.g. Class 4, Grade 7
  final String currentSchoolId;
  final List<String> targetSchoolIds;
  final String status; // active / matched / moved
  final int age;

  Child({
    required this.childId,
    required this.firstName,
    required this.gradeYear,
    required this.currentSchoolId,
    required this.targetSchoolIds,
    required this.status,
    required this.age,
  });

  Child copyWith({
    String? firstName,
    String? gradeYear,
    String? currentSchoolId,
    List<String>? targetSchoolIds,
    String? status,
    int? age,
  }) {
    return Child(
      childId: childId,
      firstName: firstName ?? this.firstName,
      gradeYear: gradeYear ?? this.gradeYear,
      currentSchoolId: currentSchoolId ?? this.currentSchoolId,
      targetSchoolIds: targetSchoolIds ?? this.targetSchoolIds,
      status: status ?? this.status,
      age: age ?? this.age,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'childId': childId,
      'firstName': firstName,
      'gradeYear': gradeYear,
      'currentSchoolId': currentSchoolId,
      'targetSchoolIds': targetSchoolIds,
      'status': status,
      'age': age,
    };
  }

  factory Child.fromMap(Map<String, dynamic> map) {
    return Child(
      childId: map['childId'] ?? '',
      firstName: map['firstName'] ?? '',
      gradeYear: map['gradeYear'] ?? '',
      currentSchoolId: map['currentSchoolId'] ?? '',
      targetSchoolIds: List<String>.from(map['targetSchoolIds'] ?? []),
      status: map['status'] ?? 'active',
      age: (map['age'] as num?)?.toInt() ?? 9,
    );
  }
}

class School {
  final String schoolId;
  final String name;
  final String area;
  final String city;
  final double lat;
  final double lng;
  final List<String> gradesOffered;
  final int transferRatePerTerm;
  final int interestedCount;

  School({
    required this.schoolId,
    required this.name,
    required this.area,
    required this.city,
    required this.lat,
    required this.lng,
    required this.gradesOffered,
    required this.transferRatePerTerm,
    required this.interestedCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'name': name,
      'area': area,
      'city': city,
      'lat': lat,
      'lng': lng,
      'gradesOffered': gradesOffered,
      'transferRatePerTerm': transferRatePerTerm,
      'interestedCount': interestedCount,
    };
  }

  factory School.fromMap(Map<String, dynamic> map) {
    return School(
      schoolId: map['schoolId'] ?? '',
      name: map['name'] ?? '',
      area: map['area'] ?? '',
      city: map['city'] ?? '',
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
      gradesOffered: List<String>.from(map['gradesOffered'] ?? []),
      transferRatePerTerm: (map['transferRatePerTerm'] as num?)?.toInt() ?? 0,
      interestedCount: (map['interestedCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class MatchModel {
  final String matchId;
  final String familyA_uid;
  final String familyB_uid;
  final String childA_id;
  final String childB_id;
  final double compatibilityScore;
  final double distanceKm;
  final String status; // pending / connected / complete
  final DateTime createdAt;

  MatchModel({
    required this.matchId,
    required this.familyA_uid,
    required this.familyB_uid,
    required this.childA_id,
    required this.childB_id,
    required this.compatibilityScore,
    required this.distanceKm,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'matchId': matchId,
      'familyA_uid': familyA_uid,
      'familyB_uid': familyB_uid,
      'childA_id': childA_id,
      'childB_id': childB_id,
      'compatibilityScore': compatibilityScore,
      'distanceKm': distanceKm,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory MatchModel.fromMap(Map<String, dynamic> map) {
    return MatchModel(
      matchId: map['matchId'] ?? '',
      familyA_uid: map['familyA_uid'] ?? '',
      familyB_uid: map['familyB_uid'] ?? '',
      childA_id: map['childA_id'] ?? '',
      childB_id: map['childB_id'] ?? '',
      compatibilityScore: (map['compatibilityScore'] as num?)?.toDouble() ?? 0.0,
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class Conversation {
  final String chatId;
  final String matchId;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastAt;
  final Map<String, bool> checklistA; // applied, confirmed, moveDate
  final Map<String, bool> checklistB; // applied, confirmed, moveDate
  final bool moveConfirmed;

  Conversation({
    required this.chatId,
    required this.matchId,
    required this.participants,
    required this.lastMessage,
    required this.lastAt,
    required this.checklistA,
    required this.checklistB,
    required this.moveConfirmed,
  });

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'matchId': matchId,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastAt': Timestamp.fromDate(lastAt),
      'checklistA': checklistA,
      'checklistB': checklistB,
      'moveConfirmed': moveConfirmed,
    };
  }

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      chatId: map['chatId'] ?? '',
      matchId: map['matchId'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastAt: (map['lastAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      checklistA: Map<String, bool>.from(map['checklistA'] ?? {'applied': false, 'confirmed': false, 'moveDate': false}),
      checklistB: Map<String, bool>.from(map['checklistB'] ?? {'applied': false, 'confirmed': false, 'moveDate': false}),
      moveConfirmed: map['moveConfirmed'] ?? false,
    );
  }

  Conversation copyWith({
    String? lastMessage,
    DateTime? lastAt,
    Map<String, bool>? checklistA,
    Map<String, bool>? checklistB,
    bool? moveConfirmed,
  }) {
    return Conversation(
      chatId: chatId,
      matchId: matchId,
      participants: participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastAt: lastAt ?? this.lastAt,
      checklistA: checklistA ?? this.checklistA,
      checklistB: checklistB ?? this.checklistB,
      moveConfirmed: moveConfirmed ?? this.moveConfirmed,
    );
  }
}

class Message {
  final String messageId;
  final String senderUid;
  final String text;
  final String type; // text / system
  final DateTime createdAt;
  final List<String> readBy;

  Message({
    required this.messageId,
    required this.senderUid,
    required this.text,
    required this.type,
    required this.createdAt,
    required this.readBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderUid': senderUid,
      'text': text,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
      'readBy': readBy,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      messageId: map['messageId'] ?? '',
      senderUid: map['senderUid'] ?? '',
      text: map['text'] ?? '',
      type: map['type'] ?? 'text',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readBy: List<String>.from(map['readBy'] ?? []),
    );
  }
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String category; // match / chat / school
  final DateTime createdAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.createdAt,
    required this.isRead,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      category: map['category'] ?? 'school',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }

  AppNotification copyWith({
    bool? isRead,
  }) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      category: category,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

