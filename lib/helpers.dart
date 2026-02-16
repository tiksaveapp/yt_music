Map<String, String> initializeHeaders(String visitorData) {
  Map<String, String> h = {
    "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36 Edg/105.0.1343.42",
    'accept': '*/*',
    'accept-encoding': 'gzip, deflate',
    'content-type': 'application/json',
    'content-encoding': 'gzip',
    "Origin": "https://music.youtube.com",
    'cookie': 'CONSENT=YES+1',
    'Accept-Language': 'en',
    'X-Goog-Visitor-Id': visitorData,
  };

  return h;
}

Map<String, dynamic> initializeContext({
  String location = 'IN',
  String language = 'en',
  String clientName = 'WEB_REMIX',
  String? clientVersion,
}) {
  if (clientVersion == null || clientVersion.isEmpty) {
    final DateTime now = DateTime.now();
    final String year = now.year.toString();
    final String month = now.month.toString().padLeft(2, '0');
    final String day = now.day.toString().padLeft(2, '0');
    final String date = year + month + day;
    clientVersion = '1.$date.01.00';
  }
  return {
    'context': {
      'client': {
        "hl": language,
        "gl": location,
        'clientName': clientName,
        'clientVersion': clientVersion,
      },
      'user': {},
    },
  };
}

dynamic nav(dynamic root, List<dynamic> items, {bool noneIfAbsent = false}) {
  try {
    for (var k in items) {
      root = root?[k];
    }
    return root;
  } catch (err) {
    if (noneIfAbsent) {
      return null;
    } else {
      rethrow;
    }
  }
}

String getContinuationString(dynamic ctoken) {
  return "&ctoken=$ctoken&continuation=$ctoken";
}
