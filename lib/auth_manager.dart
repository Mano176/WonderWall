import 'dart:io';

import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_to_front/window_to_front.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:oauth2/oauth2.dart';

const String redirectURL = "http://localhost:";
const String googleAuthApi = "https://accounts.google.com/o/oauth2/v2/auth";
const String googleTokenApi = "https://oauth2.googleapis.com/token";
const String revokeTokenUrl = 'https://oauth2.googleapis.com/revoke';

class AuthManager {
  static String? accessToken;
  static HttpServer? redirectServer;

  static Future<oauth2.Client> _getOauthClient(Uri redirectUrl, String googleClientId, String googleClientSecret) async {
    oauth2.AuthorizationCodeGrant grant = oauth2.AuthorizationCodeGrant(
      googleClientId,
      Uri.parse(googleAuthApi),
      Uri.parse(googleTokenApi),
      httpClient: JsonAcceptingHttpClient(), 
      secret: googleClientSecret
    );

    var authorizationUrl = grant.getAuthorizationUrl(redirectUrl, scopes: ["https://www.googleapis.com/auth/userinfo.email", "https://www.googleapis.com/auth/userinfo.profile"]);
    await redirect(authorizationUrl);
    var responseQueryParameters = await listen();
    var client = await grant.handleAuthorizationResponse(responseQueryParameters);
    return client;
  }

  static Future<void> redirect(Uri authorizationUri) async {
    if (await canLaunchUrl(authorizationUri)){
      await launchUrl(authorizationUri);
    } else{
      throw Exception('Can not launch $authorizationUri');
    }
  }

  static Future<Map<String, String>> listen() async {
    var request = await redirectServer!.first;
    var params = request.uri.queryParameters;
    await WindowToFront.activate();

    request.response.statusCode = 200;
    request.response.headers.set('content-type', 'text/plain');
    request.response.writeln('Please close the tab');

    await request.response.close();
    await redirectServer!.close();
    redirectServer = null;

    return params;
  }

  static Future<User?> signIn(String googleClientId, String googleClientSecret) async {
    await redirectServer?.close();
    redirectServer = await HttpServer.bind('localhost', 0);
    final redirectUrl = redirectURL + redirectServer!.port.toString();

    oauth2.Client authenticatedHttpClient = await _getOauthClient(Uri.parse(redirectUrl), googleClientId, googleClientSecret);
    Credentials credentials = authenticatedHttpClient.credentials;
    accessToken = credentials.accessToken;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("google_accesstoken", accessToken!);

    AuthCredential authCredential = GoogleAuthProvider.credential(
      idToken: credentials.idToken,
      accessToken: credentials.accessToken
    );

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(authCredential);
      return userCredential.user;
    } on FirebaseAuthException catch (error) {
      throw Exception('Could not authenticate: $error');
    }
  }

  static void signOut() async {
    await FirebaseAuth.instance.signOut();
    await http.post(Uri.parse("https://accounts.google.com/o/oauth2/revoke?token=$accessToken"));
    accessToken = null;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("google_accesstoken", "");
  }


}

class JsonAcceptingHttpClient extends http.BaseClient {
  final _httpClient = http.Client();
  
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Accept'] = 'application/json';

    return _httpClient.send(request);
  }
}