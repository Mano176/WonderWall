import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_tray/system_tray.dart';
import 'package:random_desktop_background/data.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late List<Group> groups = [];

  @override
  void initState() {
    //initSystemTray();
    super.initState();
    () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? groupsString = prefs.getString("groups");
      setState(() {
        if (groupsString != null) {
          groups = List<Group>.from(jsonDecode(groupsString).map((e) => Group.fromMap(e)).toList());
        }
      });
    }();
  }

  void save() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("groups", jsonEncode(groups.map((e) => e.toMap()).toList()));
  }

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
                    onPressed: () {
                      setTitle!(textController.text);
                      onEdit!();
                    },
                    icon: Icon(Symbols.edit, fill: isEditing ? 1 : 0)),
                IconButton(onPressed: onDelete, icon: const Icon(Symbols.delete)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> initSystemTray() async {
    String path = 'assets/logo.ico';

    final AppWindow appWindow = AppWindow();
    final SystemTray systemTray = SystemTray();

    await systemTray.initSystemTray(
      title: "system tray",
      iconPath: path,
    );

    final Menu menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(label: "Show", onClicked: (menuItem) => appWindow.show()),
      MenuItemLabel(label: "Hide", onClicked: (menuItem) => appWindow.hide()),
      MenuItemLabel(label: "Exit", onClicked: (menuItem) => appWindow.close()),
    ]);
    await systemTray.setContextMenu(menu);

    // handle system tray event
    systemTray.registerSystemTrayEventHandler((eventName) {
      debugPrint("eventName: $eventName");
      if (eventName == kSystemTrayEventClick) {
        appWindow.show();
      } else if (eventName == kSystemTrayEventRightClick) {
        systemTray.popUpContextMenu();
      }
    });
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
              Column(
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
                                setState(() {
                                  group.open = !group.open;
                                });
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
                            setState(() {
                              group.enabled = value!;
                              save();
                            });
                          },
                          onHover: (value) {
                            if (groups.any((e) => e.isEditing) || groups.any((e) => e.searchTerms.any((e) => e.isEditing))) return;
                            setState(() {
                              group.isHovering = value ?? false;
                            });
                          },
                          onEdit: () {
                            setState(() {
                              group.isEditing = !group.isEditing;
                            });
                          },
                          onDelete: () {
                            setState(() {
                              groups.remove(group);
                              save();
                            });
                          },
                          setTitle: (value) {
                            setState(() {
                              group.title = value;
                              save();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  AnimatedSize(
                    alignment: Alignment.topCenter,
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
                                        setState(() {
                                          element.enabled = value!;
                                          save();
                                        });
                                      }
                                    : null,
                                onHover: (value) {
                                  if (groups.any((e) => e.isEditing) || groups.any((e) => e.searchTerms.any((e) => e.isEditing))) return;
                                  setState(() {
                                    element.isHovering = value ?? false;
                                  });
                                },
                                onEdit: () {
                                  setState(() {
                                    element.isEditing = !element.isEditing;
                                  });
                                },
                                onDelete: () {
                                  setState(() {
                                    group.searchTerms.remove(element);
                                    save();
                                  });
                                },
                                setTitle: (value) {
                                  setState(() {
                                    element.title = value;
                                    save();
                                  });
                                },
                              ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      GroupElement element = GroupElement("New Search Term", true);
                                      element.isEditing = true;
                                      group.searchTerms.add(element);
                                      save();
                                    });
                                  },
                                  child: const Text("Add Search Term")),
                            )
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(50, 8, 8, 8),
              child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      Group group = Group("New Group", true, true, []);
                      group.isEditing = true;
                      groups.add(group);
                      save();
                    });
                  },
                  child: const Text("Add Group")),
            )
          ]),
        ),
      ),
    );
  }
}
