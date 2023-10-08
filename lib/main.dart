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
  Map<String, dynamic> secrets = jsonDecode(await File("secrets.json").readAsString());
  clientId = secrets["clientId"]!;

  WidgetsFlutterBinding.ensureInitialized();
  await WindowManager.instance.ensureInitialized();
  windowManager.waitUntilReadyToShow().then((_) async {
    await windowManager.setTitle(appTitle);
  });
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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

  void newBackground() async {
    if (groups.isEmpty) return;
    Random random = Random();
    Group group = groups[random.nextInt(groups.length)];
    String searchTerm = group.searchTerms[random.nextInt(group.searchTerms.length)].title;

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
    //initSystemTray();
    super.initState();
    loadSettings().then((_) => newBackground());
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
    return MaterialApp(
      title: appTitle,
      theme: ThemeData.from(colorScheme: const ColorScheme.dark().copyWith(primary: Colors.white)),
      home: MainPage(groups: groups, setGroups: setGroups),
    );
  }
}
