import 'dart:math';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:random_desktop_background/data.dart';

class Settings extends StatelessWidget {
  final List<Group> groups;
  final Function(List<Group> groups) setGroups;
  final Function(Group group, [Random? random]) newBackgroundFromGroup;
  final Function(String searchTerm) newBackgroundFromSearchTerm;

  const Settings(
      {super.key, required this.groups, required this.setGroups, required this.newBackgroundFromGroup, required this.newBackgroundFromSearchTerm});

  Widget checkboxListTile({
    required String title,
    required double titleSize,
    required bool selected,
    required bool isHovering,
    required bool isEditing,
    required Function(bool?)? onSelected,
    required Function(bool?)? onHover,
    required Function()? onEdit,
    required Function()? onDelete,
    required Function()? onSetAsWallpaper,
    required Function(String)? setTitle,
  }) {
    TextEditingController textController = TextEditingController(text: title);
    return InkWell(
      onTap: () {
        if (onSelected != null) onSelected(!selected);
      },
      onHover: onHover,
      child: Row(
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: Checkbox(
              value: selected,
              onChanged: onSelected,
            ),
          ),
          Visibility(
            visible: isEditing,
            child: IntrinsicWidth(
              child: TextField(
                autofocus: true,
                controller: textController,
                style: TextStyle(fontSize: titleSize),
              ),
            ),
          ),
          Visibility(visible: !isEditing, child: Text(title, style: TextStyle(fontSize: titleSize))),
          Visibility(
            visible: isHovering || isEditing,
            child: Row(
              children: [
                IconButton(
                  tooltip: "Edit",
                  onPressed: () {
                    setTitle!(textController.text);
                    onEdit!();
                  },
                  icon: Icon(Symbols.edit, fill: isEditing ? 1 : 0),
                ),
                IconButton(
                  tooltip: "Delete",
                  onPressed: onDelete,
                  icon: const Icon(Symbols.delete),
                ),
                IconButton(
                  tooltip: "Set as Wallpaper",
                  onPressed: onSetAsWallpaper,
                  icon: const Icon(Symbols.wallpaper),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildGroup({required Group group, required Function(List<Group> groups) setGroups}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: AnimatedRotation(
                turns: group.open ? 0 : -0.25,
                duration: const Duration(milliseconds: 100),
                child: IconButton(
                    onPressed: () {
                      group.open = !group.open;
                      setGroups(groups);
                    },
                    icon: const Icon(Icons.arrow_drop_down)),
              ),
            ),
            Expanded(
              child: checkboxListTile(
                title: group.title,
                titleSize: 20,
                selected: group.enabled,
                isHovering: group.isHovering,
                isEditing: group.isEditing,
                onSelected: (value) {
                  group.enabled = value!;
                  setGroups(groups);
                },
                onHover: (value) {
                  if (groups.any((e) => e.isEditing) || groups.any((e) => e.searchTerms.any((e) => e.isEditing))) return;
                  group.isHovering = value ?? false;
                  setGroups(groups);
                },
                onEdit: () {
                  group.isEditing = !group.isEditing;
                  setGroups(groups);
                },
                onDelete: () {
                  groups.remove(group);
                  setGroups(groups);
                },
                setTitle: (value) {
                  group.title = value;
                  setGroups(groups);
                },
                onSetAsWallpaper: () {
                  newBackgroundFromGroup(group);
                },
              ),
            ),
          ],
        ),
        AnimatedSize(
          alignment: Alignment.topLeft,
          duration: const Duration(milliseconds: 100),
          child: SizedBox(
            height: group.open ? null : 0,
            child: Padding(
              padding: const EdgeInsets.only(left: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var element in group.searchTerms)
                    checkboxListTile(
                      title: element.title,
                      titleSize: 15,
                      selected: element.enabled,
                      isHovering: element.isHovering,
                      isEditing: element.isEditing,
                      onSelected: group.enabled
                          ? (value) {
                              element.enabled = value!;
                              setGroups(groups);
                            }
                          : null,
                      onHover: (value) {
                        if (groups.any((e) => e.isEditing) || groups.any((e) => e.searchTerms.any((e) => e.isEditing))) return;
                        element.isHovering = value ?? false;
                        setGroups(groups);
                      },
                      onEdit: () {
                        element.isEditing = !element.isEditing;
                        setGroups(groups);
                      },
                      onDelete: () {
                        group.searchTerms.remove(element);
                        setGroups(groups);
                      },
                      setTitle: (value) {
                        element.title = value;
                        setGroups(groups);
                      },
                      onSetAsWallpaper: () {
                        newBackgroundFromSearchTerm(element.title);
                      },
                    ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: OutlinedButton(
                        onPressed: () {
                          GroupElement element = GroupElement("New Search Term", true);
                          element.isEditing = true;
                          group.searchTerms.add(element);
                          setGroups(groups);
                        },
                        child: const Text("Add Search Term")),
                  )
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Search Terms", style: TextStyle(fontSize: 30)),
            for (Group group in groups)
              buildGroup(
                group: group,
                setGroups: setGroups,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(50, 8, 8, 8),
              child: OutlinedButton(
                onPressed: () {
                  Group group = Group("New Group", true, true, []);
                  group.isEditing = true;
                  groups.add(group);
                  setGroups(groups);
                },
                child: const Text("Add Group"),
              ),
            )
          ]),
        ),
      ),
    );
  }
}
