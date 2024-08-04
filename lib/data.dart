class Group extends GroupElement {
  bool open;
  List<GroupElement> searchTerms;

  Group(super.title, super.creationDate, super.deletionDate, super.enabled, this.open, this.searchTerms);

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      "searchTerms": searchTerms.map((e) => e.toMap()).toList(),
    };
  }

  static Group fromMap(Map<String, dynamic> map) {
    return Group(
      map["title"],
      map["creationDate"] == null? DateTime.now() : DateTime.parse(map["creationDate"]),
      map["deletionDate"] == null || map["deletionDate"] == "null"? null : DateTime.parse(map["deletionDate"]),
      map["enabled"],
      true,
      List<GroupElement>.from(map["searchTerms"].map((e) => GroupElement.fromMap(e)).toList())
    );
  }
}

class GroupElement {
  String title;
  DateTime creationDate;
  DateTime? deletionDate;
  bool enabled;
  bool isHovering = false;
  bool isEditing = false;

  GroupElement(this.title, this.creationDate, this.deletionDate, this.enabled);

  Map<String, dynamic> toMap() {
    return {
      "title": title,
      "creationDate": creationDate.toString(),
      "deletionDate": deletionDate.toString(),
      "enabled": enabled,
    };
  }

  static GroupElement fromMap(Map<String, dynamic> map) {
    return GroupElement(
      map["title"],
      map["creationDate"] == null? DateTime.now() : DateTime.parse(map["creationDate"]),
      map["deletionDate"] == null || map["deletionDate"] == "null"? null : DateTime.parse(map["deletionDate"]),
      map["enabled"]);
  }
}
