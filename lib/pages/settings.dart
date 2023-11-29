import 'dart:math';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wonderwall/data.dart';

class Settings extends StatelessWidget {
  final Image? currentWallpaper;
  final Map<String, String?> credits;
  final List<Group> groups;
  final bool wallpaperOnStart;
  final bool wallpaperOnInterval;
  final int intervalHour;
  final int intervalMinute;
  final Function(List<Group> groups) setGroups;
  final Function(List<Group> groups) newWallpaperFromGroups;
  final Function(Group group, [Random? random]) newWallpaperFromGroup;
  final Function(String searchTerm) newWallpaperFromSearchTerm;
  final Function(bool bool) setWallpaperOnStart;
  final Function(bool bool) setWallpaperOnInterval;
  final Function(int hour, int minute) setIntervalTime;

  const Settings(
      {super.key,
      required this.currentWallpaper,
      required this.credits,
      required this.groups,
      required this.wallpaperOnStart,
      required this.wallpaperOnInterval,
      required this.intervalHour,
      required this.intervalMinute,
      required this.setGroups,
      required this.newWallpaperFromGroups,
      required this.newWallpaperFromGroup,
      required this.newWallpaperFromSearchTerm,
      required this.setWallpaperOnStart,
      required this.setWallpaperOnInterval,
      required this.setIntervalTime});

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
                  newWallpaperFromGroup(group);
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
                        newWallpaperFromSearchTerm(element.title);
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
                      child: const Text("Add Search Term"),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
        const Divider(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
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
            const VerticalDivider(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("General Settings", style: TextStyle(fontSize: 30)),
                  CheckboxListTile(
                      title: const Text("New Wallpaper on app start"),
                      value: wallpaperOnStart,
                      onChanged: (checked) => setWallpaperOnStart(checked!)),
                  CheckboxListTile(
                      title: const Text("New Wallpaper every 24 hours"),
                      value: wallpaperOnInterval,
                      onChanged: (checked) => setWallpaperOnInterval(checked!)),
                  Center(
                    child: OutlinedButton(
                      onPressed: wallpaperOnInterval
                          ? () => showTimePicker(context: context, initialTime: TimeOfDay(hour: intervalHour, minute: intervalMinute)).then((value) {
                                if (value != null) {
                                  setIntervalTime(value.hour, value.minute);
                                }
                              })
                          : null,
                      child: Text("New Wallpaper at ${intervalHour.toString().padLeft(2, "0")}:${intervalMinute.toString().padLeft(2, "0")}"),
                    ),
                  ),
                  const Divider(),
                  const Text("Current Wallpaper", style: TextStyle(fontSize: 30)),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 640,
                          height: 640 / 1920 * 1080,
                          child: Container(
                            color: Colors.black,
                            child: Center(
                              child: () {
                                return currentWallpaper == null
                                    ? const Text("No Wallpaper Selected", style: TextStyle(color: Colors.white))
                                    : currentWallpaper!;
                              }(),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 400,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: OutlinedButton(
                                  onPressed: credits["shareURL"] == null ? null : () => launchUrl(Uri.parse(credits["shareURL"]!)),
                                  child: const Text("Open image on Unsplash"),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: OutlinedButton(
                                  onPressed: credits["photographer_url"] == null ? null : () => launchUrl(Uri.parse(credits["photographer_url"]!)),
                                  child: Text("Photographer:\n${credits["photographer_name"]}", textAlign: TextAlign.center),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 18.0),
                                child: Divider(),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: OutlinedButton(onPressed: () => newWallpaperFromGroups(groups), child: const Text("New Wallpaper")),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
