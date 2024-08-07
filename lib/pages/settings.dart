import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wonderwall/auth_manager.dart';
import 'package:wonderwall/data.dart';
import 'package:wonderwall/main.dart';

class Settings extends StatefulWidget {
  final User? user;
  final Image? currentWallpaper;
  final Map<String, String?> credits;
  final Map<String, bool> allowedOrientations;
  final List<Group> groups;
  final bool wallpaperOnStart;
  final bool wallpaperOnInterval;
  final int intervalHour;
  final int intervalMinute;
  final Function(Map<String, bool>) setAllowedOrientations;
  final Function(List<Group> groups, [bool save]) setGroups;
  final Function(List<Group> groups) newWallpaperFromGroups;
  final Function(Group group, [Random? random]) newWallpaperFromGroup;
  final Function(List<String> allowedOrientations, [String? searchTerm, Random? random]) newWallpaper;
  final Function(bool bool) setWallpaperOnStart;
  final Function(bool bool) setWallpaperOnInterval;
  final Function(int hour, int minute) setIntervalTime;

  const Settings(
      {super.key,
      required this.user,
      required this.currentWallpaper,
      required this.credits,
      required this.allowedOrientations,
      required this.groups,
      required this.wallpaperOnStart,
      required this.wallpaperOnInterval,
      required this.intervalHour,
      required this.intervalMinute,
      required this.setAllowedOrientations,
      required this.setGroups,
      required this.newWallpaperFromGroups,
      required this.newWallpaperFromGroup,
      required this.newWallpaper,
      required this.setWallpaperOnStart,
      required this.setWallpaperOnInterval,
      required this.setIntervalTime});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool isProfilePopupOpen = false;

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

  Widget buildGroup({required Group group, required Function(List<Group> groups, [bool save]) setGroups}) {
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
                      setGroups(widget.groups, false);
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
                  group.editDate = DateTime.now();
                  setGroups(widget.groups);
                },
                onHover: (value) {
                  if (widget.groups.any((e) => e.isEditing) || widget.groups.any((e) => e.searchTerms.any((e) => e.isEditing))) return;
                  group.isHovering = value ?? false;
                  setGroups(widget.groups, false);
                },
                onEdit: () {
                  group.isEditing = !group.isEditing;
                  setGroups(widget.groups);
                },
                onDelete: () {
                  DateTime deletionDateTime = DateTime.now();
                  group.deleted = true;
                  group.editDate = deletionDateTime;
                  for (GroupElement element in group.searchTerms) {
                    element.deleted = true;
                    element.editDate = deletionDateTime;
                  }
                  setGroups(widget.groups);
                },
                setTitle: (value) {
                  DateTime renameDateTime = DateTime.now();
                  List<GroupElement> oldSearchTerms = group.searchTerms.map((searchTerm) => GroupElement(searchTerm.title, renameDateTime, true, searchTerm.enabled)).toList();
                  Group oldGroup = Group(group.title, renameDateTime, true, group.enabled, group.open, oldSearchTerms);
                  int index = widget.groups.indexOf(group);
                  widget.groups.insert(index, oldGroup);
                  Group? groupWithSameTitle = widget.groups.where((group) => group.title == value).firstOrNull;
                  if (groupWithSameTitle != null) {
                    widget.groups.remove(groupWithSameTitle);
                    group.searchTerms = groupWithSameTitle.searchTerms;
                    group.open = true;
                  }
                  group.title = value;
                  setGroups(widget.groups);
                },
                onSetAsWallpaper: () {
                  widget.newWallpaperFromGroup(group);
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
                  for (GroupElement element in group.searchTerms.where((element) => !element.deleted))
                    checkboxListTile(
                      title: element.title,
                      titleSize: 15,
                      selected: element.enabled,
                      isHovering: element.isHovering,
                      isEditing: element.isEditing,
                      onSelected: group.enabled
                          ? (value) {
                              element.enabled = value!;
                              DateTime editDate = DateTime.now();
                              element.editDate = editDate;
                              group.editDate = editDate;
                              setGroups(widget.groups);
                            }
                          : null,
                      onHover: (value) {
                        if (widget.groups.any((e) => e.isEditing) || widget.groups.any((e) => e.searchTerms.any((e) => e.isEditing))) return;
                        element.isHovering = value ?? false;
                        setGroups(widget.groups, false);
                      },
                      onEdit: () {
                        element.isEditing = !element.isEditing;
                        setGroups(widget.groups);
                      },
                      onDelete: () {
                        element.deleted = true;
                        element.editDate = DateTime.now();
                        setGroups(widget.groups);
                      },
                      setTitle: (value) {
                        DateTime renameDateTime = DateTime.now();
                        GroupElement oldSearchTerm = GroupElement(element.title, renameDateTime, true, element.enabled);
                        int index = group.searchTerms.indexOf(element);
                        group.searchTerms.insert(index, oldSearchTerm);
                        group.searchTerms.removeWhere((element) => element.title == value);
                        element.title = value;
                        element.editDate = renameDateTime;
                        setGroups(widget.groups);
                      },
                      onSetAsWallpaper: () {
                        widget.newWallpaper(widget.allowedOrientations.keys.where((orientation) => widget.allowedOrientations[orientation]!).toList(), element.title, null);
                      },
                    ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: OutlinedButton(
                      onPressed: () {
                        GroupElement element = GroupElement("New Search Term", DateTime.now(), false, true);
                        element.isEditing = true;
                        group.searchTerms.add(element);
                        setGroups(widget.groups);
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
        child: Stack(
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text("Search Terms", style: TextStyle(fontSize: 30)),
                      for (Group group in widget.groups.where((group) => !group.deleted))
                        buildGroup(
                          group: group,
                          setGroups: widget.setGroups,
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(50, 8, 8, 8),
                        child: OutlinedButton(
                          onPressed: () {
                            Group group = Group("New Group", DateTime.now(), false, true, true, []);
                            group.isEditing = true;
                            widget.groups.add(group);
                            widget.setGroups(widget.groups);
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
                          value: widget.wallpaperOnStart,
                          onChanged: (checked) => widget.setWallpaperOnStart(checked!)),
                      CheckboxListTile(
                          title: const Text("New Wallpaper every 24 hours"),
                          value: widget.wallpaperOnInterval,
                          onChanged: (checked) => widget.setWallpaperOnInterval(checked!)),
                      Center(
                        child: OutlinedButton(
                          onPressed: widget.wallpaperOnInterval
                              ? () => showTimePicker(context: context, initialTime: TimeOfDay(hour: widget.intervalHour, minute: widget.intervalMinute)).then((value) {
                                    if (value != null) {
                                      widget.setIntervalTime(value.hour, value.minute);
                                    }
                                  })
                              : null,
                          child: Text("New Wallpaper at ${widget.intervalHour.toString().padLeft(2, "0")}:${widget.intervalMinute.toString().padLeft(2, "0")}"),
                        ),
                      ),
                      const Text("Allowed orientations", style: TextStyle(fontSize: 20)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: widget.allowedOrientations.keys.map((orientation) =>
                          Row(
                            children: [
                              Checkbox(value: widget.allowedOrientations[orientation], onChanged: widget.allowedOrientations[orientation]! && widget.allowedOrientations.values.where((value) => value).length == 1 ? null : (checked) {
                                widget.allowedOrientations[orientation] = checked!;
                                widget.setAllowedOrientations(widget.allowedOrientations);
                              }),
                              Text(orientation.substring(0, 1).toUpperCase()+orientation.substring(1))
                            ],
                          )).toList(),
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
                                    return widget.currentWallpaper == null
                                        ? const Text("No Wallpaper Selected", style: TextStyle(color: Colors.white))
                                        : widget.currentWallpaper!;
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
                                      onPressed: widget.credits["shareURL"] == null ? null : () => launchUrl(Uri.parse(widget.credits["shareURL"]!)),
                                      child: const Text("Open image on Unsplash"),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: OutlinedButton(
                                      onPressed: widget.credits["photographer_url"] == null ? null : () => launchUrl(Uri.parse(widget.credits["photographer_url"]!)),
                                      child: Text("Photographer:\n${widget.credits["photographer_name"]}", textAlign: TextAlign.center),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 18.0),
                                    child: Divider(),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: OutlinedButton(onPressed: () => widget.newWallpaperFromGroups(widget.groups), child: const Text("New Wallpaper")),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: OutlinedButton(onPressed: () => widget.newWallpaper(widget.allowedOrientations.keys.where((orientation) => widget.allowedOrientations[orientation]!).toList()), child: const Text("New Random Wallpaper")),
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
            Align(
              alignment: Alignment.topRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: () {
                      const Icon notLoggedInIcon = Icon(Icons.account_circle, size: 30,);
                      if (widget.user == null) {
                        return notLoggedInIcon;
                      }

                      for (UserInfo userInfo in widget.user!.providerData) {
                        if (userInfo.photoURL != null && userInfo.photoURL != "") {
                          return Image.network(userInfo.photoURL!, width: 30, height: 30);
                        }
                      }
                      return notLoggedInIcon;
                    }(),
                  onPressed: () {
                    setState(() {
                      isProfilePopupOpen = !isProfilePopupOpen;
                    });
                  },),
                  Visibility(
                    visible: isProfilePopupOpen,
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white),
                        borderRadius: const BorderRadius.all(Radius.circular(12)),
                        color: Theme.of(context).colorScheme.background,
                      ),
                      child: Column(
                        
                        children: [
                          Visibility(
                            visible: widget.user != null,
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Text(
                                () {
                                  if (widget.user != null) {
                                    for (UserInfo userInfo in widget.user!.providerData) {
                                      if (userInfo.displayName != null && userInfo.displayName != "") {
                                        return "Logged in as\n${userInfo.displayName!}";
                                      }
                                    }
                                  }
                                  return "";
                                }(),
                              textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: OutlinedButton(
                              onPressed: widget.user == null? () => AuthManager.signIn(googleClientId, googleClientSecret) : AuthManager.signOut, 
                              child: Text(widget.user == null? "Login" : "Logout"),
                            ),
                          )
                        ],
                      ),
                    )
                  )
                ], 
              ),
            ),
          ],
        ),
      ),
    );
  }
}
