class Group extends GroupElement {
  bool open;
  List<GroupElement> searchTerms;

  Group(super.title, super.enabled, this.open, this.searchTerms);

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'searchTerms': searchTerms.map((e) => e.toMap()).toList(),
    };
  }

  static Group fromMap(Map<String, dynamic> map) {
    return Group(map['title'], map['enabled'], true, List<GroupElement>.from(map['searchTerms'].map((e) => GroupElement.fromMap(e)).toList()));
  }
}

class GroupElement {
  String title;
  bool enabled;
  bool isHovering = false;
  bool isEditing = false;

  GroupElement(this.title, this.enabled);

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'enabled': enabled,
    };
  }

  static GroupElement fromMap(Map<String, dynamic> map) {
    return GroupElement(map['title'], map['enabled']);
  }
}
