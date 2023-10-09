import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart';
import 'package:random_desktop_background/data.dart';
import 'package:random_desktop_background/pages/main_page.dart';
import 'package:random_desktop_background/util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/material.dart';

const String appTitle = "Random Desktop Background";
const String baseURL = "https://api.unsplash.com/";
late final String clientId;

void main() async {
  const bool fromAutostart = bool.fromEnvironment("fromAutostart");

  Map<String, dynamic> secrets = jsonDecode(await File("secrets.json").readAsString());
  clientId = secrets["clientId"]!;

  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow();
  await windowManager.setTitle(appTitle);
  await windowManager.setMinimumSize(const Size(1000, 580));
  await windowManager.center();
  runApp(const MyApp(fromAutostart: fromAutostart));
}

void newBackgroundFromGroups(List<Group> groups) async {
  if (groups.isEmpty) return;
  Random random = Random();
  Group group = groups[random.nextInt(groups.length)];
  newBackgroundFromGroup(group, random);
}

void newBackgroundFromGroup(Group group, [Random? random]) async {
  random ??= Random();
  String searchTerm = group.searchTerms[random.nextInt(group.searchTerms.length)].title;
  newBackgroundFromSearchTerm(searchTerm);
}

void newBackgroundFromSearchTerm(String searchTerm) async {
  Map<String, String> params = {
    "client_id": clientId,
    "query": searchTerm,
    "orientation": "landscape",
  };
  Map<String, dynamic> response = await sendGetRequest("${baseURL}photos/random", params);

  String url = response["urls"]["raw"];
  String photographer = response["user"]["name"];
  String shareURL = response["links"]["html"];

  Response imageResponse = await get(Uri.parse(url));
  String path = "${Platform.environment["tmp"]!}\\$appTitle\\background.png";
  await saveTempFile(imageResponse.bodyBytes, path);
  changeWallpaper(path);
}

class MyApp extends StatefulWidget {
  final bool fromAutostart;

  const MyApp({super.key, this.fromAutostart = false});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener {
  late List<Group> groups = [];

  void saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("groups", jsonEncode(groups.map((e) => e.toMap()).toList()));
  }

  Future<void> loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? groupsString = prefs.getString("groups");
    if (groupsString != null) {
      setGroups(List<Group>.from(jsonDecode(groupsString).map((e) => Group.fromMap(e)).toList()));
    }
  }

  void setGroups(List<Group> groups, {bool save = true}) {
    setState(() {
      this.groups = groups;
    });
    if (save) {
      saveSettings();
    }
  }

  @override
  void initState() {
    super.initState();
    () async {
      windowManager.addListener(this);
      windowManager.setPreventClose(true);
      initSystemTray();
      await loadSettings();
      if (widget.fromAutostart) {
        newBackgroundFromGroups(groups);
      } else {
        windowManager.show();
      }
    }();
  }

  Future<void> initSystemTray() async {
    final AppWindow appWindow = AppWindow();
    final SystemTray systemTray = SystemTray();

    await systemTray.initSystemTray(
      title: appTitle,
      iconPath: "assets/logo.ico",
    );

    final Menu menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(label: "Show", onClicked: (menuItem) => appWindow.show()),
      MenuItemLabel(label: "Hide", onClicked: (menuItem) => appWindow.hide()),
      MenuItemLabel(label: "Exit", onClicked: (menuItem) => windowManager.destroy()),
    ]);
    await systemTray.setContextMenu(menu);

    // handle system tray left and right click
    systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == kSystemTrayEventClick || eventName == kSystemTrayEventRightClick) {
        systemTray.popUpContextMenu();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      theme: ThemeData.from(colorScheme: const ColorScheme.dark().copyWith(primary: Colors.white)),
      home: MainPage(groups: groups, setGroups: setGroups),
    );
  }

  @override
  void onWindowClose() async {
    await windowManager.hide();
  }
}
