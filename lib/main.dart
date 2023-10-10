import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:wonderwall/data.dart';
import 'package:wonderwall/pages/settings.dart';
import 'package:wonderwall/util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_tray/system_tray.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/material.dart';

const String appTitle = "WonderWall";
const String baseURL = "https://api.unsplash.com/";
late final String clientId;
late final bool fromAutostart;
final String wallpaperPath = "${Platform.environment["tmp"]!}\\$appTitle\\wallpaper.png";

void main() async {
  fromAutostart = const bool.fromEnvironment("fromAutostart");

  Map<String, dynamic> secrets = jsonDecode(await File("secrets.json").readAsString());
  clientId = secrets["clientId"]!;

  WidgetsFlutterBinding.ensureInitialized();

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  launchAtStartup.setup(
    appName: packageInfo.appName,
    appPath: Platform.resolvedExecutable,
    args: ["--dart-define", "fromAutostart=true"],
  );

  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow();
  await windowManager.setTitle(appTitle);
  await windowManager.setMinimumSize(const Size(1000, 600));
  await windowManager.center();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener {
  Image? currentWallpaper;
  late List<Group> groups = [];
  Map<String, String?> credits = {
    "photographer_name": "Unknown",
    "photographer_url": null,
    "shareURL": null,
  };

  void newBackgroundFromGroups(List<Group> groups) async {
    List<Group> groupsToChooseFrom =
        groups.where((element) => element.enabled && element.searchTerms.where((element) => element.enabled).toList().isNotEmpty).toList();
    if (groupsToChooseFrom.isEmpty) return;

    Random random = Random();
    Group group = groupsToChooseFrom[random.nextInt(groupsToChooseFrom.length)];
    newBackgroundFromGroup(group, random);
  }

  void newBackgroundFromGroup(Group group, [Random? random]) async {
    random ??= Random();
    List<GroupElement> searchTermsToChooseFrom = group.searchTerms.where((element) => element.enabled).toList();
    if (searchTermsToChooseFrom.isEmpty) return;
    String searchTerm = searchTermsToChooseFrom[random.nextInt(searchTermsToChooseFrom.length)].title;
    newBackgroundFromSearchTerm(searchTerm);
  }

  void newBackgroundFromSearchTerm(String searchTerm) async {
    if (!searchTerm.toLowerCase().contains("wallpaper")) {
      searchTerm += " wallpaper";
    }
    Map<String, String> params = {
      "client_id": clientId,
      "query": searchTerm,
      "orientation": "landscape",
    };
    Map<String, dynamic> response = await sendGetRequest("${baseURL}photos/random", params);
    String url = response["urls"]["raw"];
    setState(() {
      credits = {
        "photographer_name": response["user"]["name"],
        "photographer_url": response["user"]["links"]["html"],
        "shareURL": response["links"]["html"],
      };
      saveSettings();
      initSystemTray();
    });

    Response imageResponse = await get(Uri.parse(url));
    setState(() {
      currentWallpaper = Image.memory(imageResponse.bodyBytes);
    });
    await saveTempFile(imageResponse.bodyBytes, wallpaperPath);
    changeWallpaper(wallpaperPath);
  }

  void saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("groups", jsonEncode(groups.map((e) => e.toMap()).toList()));
    if (credits["photographer_name"] != null) {
      prefs.setString("photographer_name", credits["photographer_name"]!);
    }
    if (credits["photographer_url"] != null) {
      prefs.setString("photographer_url", credits["photographer_url"]!);
    }
    if (credits["shareURL"] != null) {
      prefs.setString("shareURL", credits["shareURL"]!);
    }
  }

  Future<void> loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? groupsString = prefs.getString("groups");
    if (groupsString != null) {
      setGroups(List<Group>.from(jsonDecode(groupsString).map((e) => Group.fromMap(e)).toList()));
    }
    credits = {
      "photographer_name": prefs.getString("photographer_name") ?? "Unknown",
      "photographer_url": prefs.getString("photographer_url"),
      "shareURL": prefs.getString("shareURL"),
    };
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
    File file = File(wallpaperPath);
    if (file.existsSync()) {
      currentWallpaper = Image.file(file);
    }
    () async {
      windowManager.addListener(this);
      windowManager.setPreventClose(true);
      await loadSettings();
      initSystemTray();
      if (fromAutostart) {
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
      toolTip: appTitle,
      iconPath: "assets/logo.ico",
    );

    final Menu menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(label: "New Background", onClicked: (menuItem) => newBackgroundFromGroups(groups)),
      MenuSeparator(),
      MenuItemLabel(label: "Credits:", enabled: false),
      MenuItemLabel(
        label: "Open image on Unsplash",
        enabled: credits["shareURL"] != null,
        onClicked: (_) => launchUrl(Uri.parse(credits["shareURL"]!)),
      ),
      MenuItemLabel(
        label: "Photographer: ${credits["photographer_name"]}",
        enabled: credits["photographer_url"] != null,
        onClicked: (_) => launchUrl(Uri.parse(credits["photographer_url"]!)),
      ),
      MenuSeparator(),
      MenuItemLabel(label: "Settings", onClicked: (menuItem) => appWindow.show()),
      MenuItemCheckbox(
        label: "Autostart",
        checked: await launchAtStartup.isEnabled(),
        onClicked: (_) async {
          if (await launchAtStartup.isEnabled()) {
            launchAtStartup.disable();
          } else {
            launchAtStartup.enable();
          }
          initSystemTray();
        },
      ),
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
      home: Settings(
        currentWallpaper: currentWallpaper,
        credits: credits,
        groups: groups,
        setGroups: setGroups,
        newBackgroundFromGroups: newBackgroundFromGroups,
        newBackgroundFromGroup: newBackgroundFromGroup,
        newBackgroundFromSearchTerm: newBackgroundFromSearchTerm,
      ),
    );
  }

  @override
  void onWindowClose() async {
    await windowManager.hide();
  }
}
