import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:cronet_http/cronet_http.dart';
import 'package:yt_music/helpers.dart';

import 'modals/yt_config.dart';

class YTClient {
  YTClient({required this.config}) {
    headers = initializeHeaders(config.visitorData);
    context = initializeContext(
      language: config.language,
      location: config.location,
      clientName: config.clientName,
      clientVersion: config.clientVersion,
    );
    ytmParams = '?alt=json&key=${config.apiKey}';
  }

  Map<String, String> headers = {};
  Map<String, dynamic> context = {};
  int? signatureTimestamp;
  YTConfig config;
  static String ytmParams = '';

  static final Client client = _createClient();
  static const ytmDomain = 'music.youtube.com';
  static const httpsYtmDomain = 'https://music.youtube.com';
  static const baseApiEndpoint = '/youtubei/v1/';

  static final ValueNotifier<int> lastConnectionErrorTime = ValueNotifier<int>(
    0,
  );
  ValueNotifier<int> get lastConnectionError => lastConnectionErrorTime;

  static Client _createClient() {
    if (Platform.isAndroid) {
      return CronetClient.defaultCronetEngine();
    }
    return Client();
  }

  void refreshContext() {
    context = initializeContext();
  }

  static Future<YTConfig?> getConfig() async {
    Map<String, String> newHeaders = initializeHeaders('');
    final response = await _sendGetRequest(httpsYtmDomain, newHeaders);
    final reg = RegExp(r'ytcfg\.set\s*\(\s*({.+?})\s*\)\s*;');
    RegExpMatch? matches = reg.firstMatch(response.body);
    if (matches != null) {
      final ytcfg = json.decode(matches.group(1).toString());
      return YTConfig(
        visitorData: ytcfg['VISITOR_DATA'] ?? ytcfg['EOM_VISITOR_DATA'],
        language: ytcfg['HL'],
        location: ytcfg['GL'],
        apiKey: ytcfg['INNERTUBE_API_KEY'],
        clientName: ytcfg['INNERTUBE_CLIENT_NAME'],
        clientVersion: ytcfg['INNERTUBE_CLIENT_VERSION'],
      );

      // ytcfg['INNERTUBE_API_VERSION'] eg -> v1
    }
    return null;
  }

  void updateConfig({
    String? visitorData,
    String? language,
    String? location,
    String? apiKey,
    String? clientName,
    String? clientVersion,
  }) {
    config = YTConfig(
      visitorData: visitorData ?? config.visitorData,
      language: language ?? config.language,
      location: location ?? config.location,
      apiKey: apiKey ?? config.apiKey,
      clientName: clientName ?? config.clientName,
      clientVersion: clientVersion ?? config.clientVersion,
    );
  }

  Future<Response> sendGetRequest(
    String url,
    Map<String, String>? headers,
  ) async {
    try {
      final Uri uri = Uri.parse(url);
      final Response response = await client.get(uri, headers: headers);
      return response;
    } catch (e) {
      debugPrint("Exception in YTClient::sendGetRequest: $e");
      lastConnectionErrorTime.value = DateTime.now().millisecondsSinceEpoch;
      return Response.bytes([], 503);
    }
  }

  static Future<Response> _sendGetRequest(
    String url,
    Map<String, String>? headers,
  ) async {
    try {
      final Uri uri = Uri.parse(url);
      final Response response = await client.get(uri, headers: headers);
      return response;
    } catch (e) {
      debugPrint("Exception in YTClient::_sendGetRequest: $e");
      lastConnectionErrorTime.value = DateTime.now().millisecondsSinceEpoch;
      return Response.bytes([], 503);
    }
  }

  Future<Response> addPlayingStats(String videoId, Duration time) async {
    try {
      final Uri uri = Uri.parse(
        'https://music.youtube.com/api/stats/watchtime?ns=yt&ver=2&c=WEB_REMIX&cmt=${(time.inMilliseconds / 1000)}&docid=$videoId',
      );
      final Response response = await client.get(uri, headers: headers);
      return response;
    } catch (e) {
      debugPrint("Exception in YTClient::addPlayingStats: $e");
      lastConnectionErrorTime.value = DateTime.now().millisecondsSinceEpoch;
      return Response.bytes([], 503);
    }
  }

  Future<Map> sendRequest(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    String additionalParams = '',
  }) async {
    try {
      body = {...body, ...context};
      headers = {...this.headers, ...?headers};

      final Uri uri = Uri.parse(
        httpsYtmDomain +
            baseApiEndpoint +
            endpoint +
            ytmParams +
            additionalParams,
      );
      final response = await client.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map;
      } else {
        return {};
      }
    } catch (e) {
      debugPrint("Exception in YTClient::sendRequest: $e");
      lastConnectionErrorTime.value = DateTime.now().millisecondsSinceEpoch;
      return {};
    }
  }
}
