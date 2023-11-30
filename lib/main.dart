import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
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

const minSize = Size(1200, 800);
const String appTitle = "WonderWall";
const String baseURL = "https://api.unsplash.com/";
late final String clientId;
late final bool fromAutostart;
final String wallpaperPath = "${Platform.environment["tmp"]!}\\$appTitle\\wallpaper.png";
Timer? scheduledTimer;

void main(args) async {
  args = {
    for (var arg in [for (var arg in args) arg.split("=")]) arg[0]: arg[1]
  };
  fromAutostart = bool.parse(args["fromAutostart"] ?? "false", caseSensitive: false);

  WidgetsFlutterBinding.ensureInitialized();
  // TODO change to secrets.json
  Map<String, dynamic> secrets = jsonDecode(await rootBundle.loadString("assets/my_secrets.json"));
  clientId = secrets["clientId"]!;

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  launchAtStartup.setup(
    appName: packageInfo.appName,
    appPath: Platform.resolvedExecutable,
    args: ["fromAutostart=true"],
  );

  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow();
  await windowManager.setMinimumSize(minSize);
  await windowManager.setSize(minSize);
  await windowManager.setTitle(appTitle);
  await windowManager.center();
  runApp(const MyApp());
}

void scheduleTask(void Function() callback, DateTime time) {
  if (scheduledTimer != null) {
    scheduledTimer!.cancel();
  }
  Duration duration = time.difference(DateTime.now());
  scheduledTimer = Timer(duration, () {
    scheduledTimer = null;
    callback();
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener {
  bool loading = true;
  Image? currentWallpaper;
  late bool wallpaperOnStart;
  late bool wallpaperOnInterval;
  late int intervalHour;
  late int intervalMinute;
  late List<Group> groups;
  Map<String, String?> credits = {
    "photographer_name": "Unknown",
    "photographer_url": null,
    "shareURL": null,
  };

  void newWallpaperFromGroups(List<Group> groups) async {
    List<Group> groupsToChooseFrom =
        groups.where((element) => element.enabled && element.searchTerms.where((element) => element.enabled).toList().isNotEmpty).toList();
    if (groupsToChooseFrom.isEmpty) return;

    Random random = Random();
    Group group = groupsToChooseFrom[random.nextInt(groupsToChooseFrom.length)];
    newWallpaperFromGroup(group, random);
  }

  void newWallpaperFromGroup(Group group, [Random? random]) async {
    random ??= Random();
    List<GroupElement> searchTermsToChooseFrom = group.searchTerms.where((element) => element.enabled).toList();
    if (searchTermsToChooseFrom.isEmpty) return;
    String searchTerm = searchTermsToChooseFrom[random.nextInt(searchTermsToChooseFrom.length)].title;
    newWallpaperFromSearchTerm(searchTerm);
  }

  void newWallpaperFromSearchTerm(String searchTerm) async {
    Map<String, String> params = {
      "client_id": clientId,
      "query": searchTerm,
      "orientation": "landscape",
    };
    Map<String, dynamic> response = await sendGetRequest("${baseURL}photos/random", params);
    String url = response["urls"]["raw"];
    setState(() {
      credits = {
        "photographer_name": const Utf8Codec().decode((response["user"]["name"] as String).codeUnits),
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
    prefs.setBool("wallpaperOnStart", wallpaperOnStart);
    prefs.setBool("wallpaperOnInterval", wallpaperOnInterval);
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
    wallpaperOnStart = prefs.getBool("wallpaperOnStart") ?? true;
    wallpaperOnInterval = prefs.getBool("wallpaperOnInterval") ?? true;
    intervalHour = prefs.getInt("intervalHour") ?? 0;
    intervalMinute = prefs.getInt("intervalMinute") ?? 0;
    String? groupsString = prefs.getString("groups");
    if (groupsString != null) {
      groups = List<Group>.from(jsonDecode(groupsString).map((e) => Group.fromMap(e)).toList());
    }
    credits = {
      "photographer_name": prefs.getString("photographer_name") ?? "Unknown",
      "photographer_url": prefs.getString("photographer_url"),
      "shareURL": prefs.getString("shareURL"),
    };
  }

  void setGroups(List<Group> groups) {
    setState(() {
      this.groups = groups;
    });
    saveSettings();
  }

  void setWallpaperOnStart(bool value) {
    setState(() {
      wallpaperOnStart = value;
    });
    saveSettings();
  }

  void setWallpaperOnInterval(bool value) {
    setState(() {
      wallpaperOnInterval = value;
    });
    saveSettings();

    if (wallpaperOnInterval) {
      scheduleNextWallpaper(intervalHour, intervalMinute);
    } else {
      if (scheduledTimer != null) {
        scheduledTimer!.cancel();
      }
    }
  }

  void setIntervalTime(int hour, int minute) {
    setState(() {
      intervalHour = hour;
      intervalMinute = minute;
    });
    saveSettings();
    scheduleNextWallpaper(intervalHour, intervalMinute);
  }

  void scheduleNextWallpaper(int hour, int minute) {
    DateTime time = DateTime.now();
    if (time.hour > hour || (time.hour == hour && time.minute >= minute)) {
      time = time.add(const Duration(days: 1));
    }
    time = DateTime(time.year, time.month, time.day, hour, minute);
    scheduleTask(() {
      if (wallpaperOnInterval) {
        newWallpaperFromGroups(groups);
        scheduleNextWallpaper(hour, minute);
      }
    }, time);
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
      if (wallpaperOnStart) {
        newWallpaperFromGroups(groups);
      }
      if (!fromAutostart) {
        windowManager.show();
      }
      loading = false;
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
      MenuItemLabel(label: "New Wallpaper", onClicked: (menuItem) => newWallpaperFromGroups(groups)),
      MenuSeparator(),
      MenuItemLabel(label: "Credits:", enabled: false),
      MenuItemLabel(
        label: "Open image on Unsplash",
        enabled: credits["shareURL"] != null,
        onClicked: (_) => launchUrl(Uri.parse(credits["shareURL"]!)),
      ),
      MenuItemLabel(
        label: "Photographer: ${credits["photographer_name"]!}",
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
      home: loading
          ? const CircularProgressIndicator()
          : Settings(
              currentWallpaper: currentWallpaper,
              credits: credits,
              groups: groups,
              wallpaperOnStart: wallpaperOnStart,
              wallpaperOnInterval: wallpaperOnInterval,
              intervalHour: intervalHour,
              intervalMinute: intervalMinute,
              setGroups: setGroups,
              newWallpaperFromGroups: newWallpaperFromGroups,
              newWallpaperFromGroup: newWallpaperFromGroup,
              newWallpaperFromSearchTerm: newWallpaperFromSearchTerm,
              setWallpaperOnStart: setWallpaperOnStart,
              setWallpaperOnInterval: setWallpaperOnInterval,
              setIntervalTime: setIntervalTime,
            ),
    );
  }

  @override
  void onWindowClose() async {
    await windowManager.hide();
  }
}
