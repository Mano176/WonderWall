import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:wonderwall/auth_manager.dart';
import 'package:wonderwall/data.dart';
import 'package:wonderwall/pages/settings.dart' as settings_page;
import 'package:wonderwall/util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_tray/system_tray.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';


const minSize = Size(1200, 900);
const String appTitle = "WonderWall";
const String baseURL = "https://api.unsplash.com/";
late final String unsplashClientId;
late final String googleClientId;
late final String googleClientSecret;
late final bool fromAutostart;
final String wallpaperPath = "${Platform.environment["tmp"]!}\\$appTitle\\wallpaper.png";
Timer? scheduledTimer;

void main(args) async {
  args = {
    for (var arg in [for (var arg in args) arg.split("=")]) arg[0]: arg[1]
  };
  fromAutostart = bool.parse(args["fromAutostart"] ?? "false", caseSensitive: false);

  WidgetsFlutterBinding.ensureInitialized();
  Map<String, dynamic> secrets = jsonDecode(await rootBundle.loadString("assets/${kDebugMode ? "debug_secrets.json" : "secrets.json"}"));
  unsplashClientId = secrets["unsplashClientId"]!;
  googleClientId = secrets["googleClientId"]!;
  googleClientSecret = secrets["googleClientSecret"]!;

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
  User? user;
  bool loading = true;
  Image? currentWallpaper;
  late bool wallpaperOnStart;
  late bool wallpaperOnInterval;
  Map<String, int>? lastChanged;
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
    if (groupsToChooseFrom.isEmpty) {
      newWallpaper();
    } else {
      Random random = Random();
      Group group = groupsToChooseFrom[random.nextInt(groupsToChooseFrom.length)];
      newWallpaperFromGroup(group, random);
    }
  }

  void newWallpaperFromGroup(Group group, [Random? random]) async {
    random ??= Random();
    List<GroupElement> searchTermsToChooseFrom = group.searchTerms.where((element) => element.enabled).toList();
    newWallpaper(searchTermsToChooseFrom.isEmpty ? null : searchTermsToChooseFrom[random.nextInt(searchTermsToChooseFrom.length)].title);
  }

  void newWallpaper([String? searchTerm]) async {
    Map<String, String> params = {
      "client_id": unsplashClientId,
      "orientation": "landscape",
    };
    if (searchTerm != null) {
      params["query"] = searchTerm;
    }
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

    DateTime time = DateTime.now();
    lastChanged = {
      "year": time.year,
      "month": time.month,
      "day": time.day,
      "hour": time.hour,
      "minute": time.minute,
    };
    saveSettings();
  }

  void saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("wallpaperOnStart", wallpaperOnStart);
    prefs.setBool("wallpaperOnInterval", wallpaperOnInterval);
    prefs.setInt("intervalHour", intervalHour);
    prefs.setInt("intervalMinute", intervalMinute);
    if (lastChanged != null) {
      prefs.setInt("lastChangedYear", lastChanged!["year"]!);
      prefs.setInt("lastChangedMonth", lastChanged!["month"]!);
      prefs.setInt("lastChangedDay", lastChanged!["day"]!);
      prefs.setInt("lastChangedHour", lastChanged!["hour"]!);
      prefs.setInt("lastChangedMinute", lastChanged!["minute"]!);
    }
    var groupsMap = groups.map((e) => e.toMap()).toList();
    var spaces = ' ' * 4;
    var encoder = JsonEncoder.withIndent(spaces);
    print("SETTINGS:");
    print(encoder.convert(groupsMap));
    prefs.setString("groups", jsonEncode(groupsMap));
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
    AuthManager.accessToken = prefs.getString("google_accesstoken");
    wallpaperOnStart = prefs.getBool("wallpaperOnStart") ?? true;
    wallpaperOnInterval = prefs.getBool("wallpaperOnInterval") ?? true;
    int? lastChangedYear = prefs.getInt("lastChangedYear");
    int? lastChangedMonth = prefs.getInt("lastChangedMonth");
    int? lastChangedDay = prefs.getInt("lastChangedDay");
    int? lastChangedHour = prefs.getInt("lastChangedHour");
    int? lastChangedMinute = prefs.getInt("lastChangedMinute");
    if ([lastChangedYear, lastChangedMonth, lastChangedDay, lastChangedHour, lastChangedMinute].every((element) => element != null)) {
      lastChanged = {
        "year": lastChangedYear!,
        "month": lastChangedMonth!,
        "day": lastChangedDay!,
        "hour": lastChangedHour!,
        "minute": lastChangedMinute!,
      };
    }
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

  void setGroups(List<Group> groups, [bool save = true]) {
    setState(() {
      this.groups = groups;
    });
    if (save) {
      saveSettings();
    }
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
      await initializeFirebase();

      windowManager.addListener(this);
      windowManager.setPreventClose(true);
      await loadSettings();
      initSystemTray();
      if (wallpaperOnInterval) {
        scheduleNextWallpaper(intervalHour, intervalMinute);
      }
      bool changeBecauseInterval = false;
      DateTime now = DateTime.now();
      if (wallpaperOnInterval && lastChanged != null) {
        DateTime lastChangedTime =
            DateTime(lastChanged!["year"]!, lastChanged!["month"]!, lastChanged!["day"]!, lastChanged!["hour"]!, lastChanged!["minute"]!);
        DateTime changeTime = DateTime(now.year, now.month, now.day, intervalHour, intervalMinute);
        if (changeTime.isAfter(lastChangedTime) && now.isAfter(changeTime)) {
          changeBecauseInterval = true;
        }
      }
      if (wallpaperOnStart || changeBecauseInterval) {
        newWallpaperFromGroups(groups);
      }
      if (!fromAutostart) {
        windowManager.show();
      }
      setState(() {
        loading = false;
      });
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
      MenuItemLabel(label: "New Random Wallpaper", onClicked: (menuItem) => newWallpaper()),
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

  Future<void> initializeFirebase() async {
    // Firebase Start

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Auth Start
    FirebaseAuth.instance
    .authStateChanges()
    .listen((User? user) async {
      setState(() {
        this.user = user;
      });
      if (user == null) {
        print('User is currently signed out!');
      } else {
        print('User is signed in!');
        print(user);

        // Firestore Start
        // FirebaseFirestore db = FirebaseFirestore.instance;

        // final dbuser = <String, dynamic>{
        //   "first": "Ada",
        //   "last": "Lovelace",
        //   "born": 1815
        // };

        // // Add a new document with a generated ID
        // db.collection("users").add(dbuser).then((DocumentReference doc) => {
        //   print('DocumentSnapshot added with ID: ${doc.id}')
        // });

        // await db.collection("users").get().then((event) {
        //   for (var doc in event.docs) {
        //     print("${doc.id} => ${doc.data()}");
        //   }
        // });
        //Firestore End
      }
    });
    // Auth End


    // Firebase End
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      theme: ThemeData.from(colorScheme: const ColorScheme.dark().copyWith(primary: Colors.white)),
      home: loading
          ? const Center(
              child: SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(),
            ))
          : settings_page.Settings(
              user: user,
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
              newWallpaper: newWallpaper,
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
