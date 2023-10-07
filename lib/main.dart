import 'dart:isolate';

import 'package:window_manager/window_manager.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:system_tray/system_tray.dart';

const appTitle = "Random Desktop Background";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WindowManager.instance.ensureInitialized();
  windowManager.waitUntilReadyToShow().then((_) async {
    await windowManager.setTitle(appTitle);
  });
  runApp(const MyApp());
}

List<Group> groups = [
  Group("title1", true, true, [
    Element("title1-1", true),
    Element("title1-2", false),
    Element("title1-3", true),
  ]),
  Group("title2", true, false, [
    Element("title2-1", true),
    Element("title2-2", false),
    Element("title2-3", true),
  ]),
];

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      theme: ThemeData.from(colorScheme: const ColorScheme.dark().copyWith(primary: Colors.white)),
      home: const MainPage(),
    );
  }
}

class Group extends Element {
  bool open;
  List<Element> children;

  Group(super.title, super.enabled, this.open, this.children);
}

class Element {
  String title;
  bool enabled;
  bool isHovering = false;
  bool isEditing = false;
  Element(this.title, this.enabled);
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  void initState() {
    //initSystemTray();
    super.initState();
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
      MenuItemLabel(label: 'Show', onClicked: (menuItem) => appWindow.show()),
      MenuItemLabel(label: 'Hide', onClicked: (menuItem) => appWindow.hide()),
      MenuItemLabel(label: 'Exit', onClicked: (menuItem) => appWindow.close()),
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
                            });
                          },
                          onHover: (value) {
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
                            });
                          },
                          setTitle: (value) {
                            setState(() {
                              group.title = value;
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
                            for (var element in group.children)
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
                                        });
                                      }
                                    : null,
                                onHover: (value) {
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
                                    group.children.remove(element);
                                  });
                                },
                                setTitle: (value) {
                                  setState(() {
                                    element.title = value;
                                  });
                                },
                              ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      Element element = Element("New Element", true);
                                      element.isEditing = true;
                                      group.children.add(element);
                                    });
                                  },
                                  child: const Text("Add Element")),
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
