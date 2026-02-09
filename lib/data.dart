class Group extends GroupElement {
  bool open;
  List<GroupElement> searchTerms;

  Group(super.title, super.editDate, super.deleted, super.enabled, this.open, this.searchTerms);

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      "searchTerms": searchTerms.map((e) => e.toMap()).toList(),
    };
  }

  static Group fromMap(Map<String, dynamic> map) {
    return Group(
      map["title"] ?? "",
      map["editDate"] == null? DateTime.now() : DateTime.parse(map["editDate"]),
      map["deleted"] ?? false,
      map["enabled"] ?? true,
      true,
      List<GroupElement>.from(map["searchTerms"].map((e) => GroupElement.fromMap(e)).toList())
    );
  }
}

class GroupElement {
  String title;
  DateTime editDate;
  bool deleted;
  bool enabled;
  bool isHovering = false;
  bool isEditing = false;

  GroupElement(this.title, this.editDate, this.deleted, this.enabled);

  Map<String, dynamic> toMap() {
    return {
      "title": title,
      "editDate": editDate.toString(),
      "deleted": deleted,
      "enabled": enabled,
    };
  }

  static GroupElement fromMap(Map<String, dynamic> map) {
    return GroupElement(
      map["title"] ?? "",
      map["editDate"] == null? DateTime.now() : DateTime.parse(map["editDate"]),
      map["deleted"]?? false,
      map["enabled"] ?? true
    );
  }

  @override
  String toString() {
    return toMap().toString();
  }
}
