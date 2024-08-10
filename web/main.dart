// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:shelf_static/shelf_static.dart' as shelf_static;
import 'prediction.dart';

Future<void> main() async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final cascade = Cascade().add(_staticHandler).add(_router.call);

  final server = await shelf_io.serve(
    logRequests().addHandler(cascade.handler),
    InternetAddress.anyIPv4,
    port,
  );

  print('Serving at http://${server.address.host}:${server.port}');
  _watch.start();
}

final _staticHandler =
    shelf_static.createStaticHandler('public', defaultDocument: 'index.html');
final _router = shelf_router.Router()
  ..get(
    '/time',
    (request) => Response.ok(DateTime.now().toUtc().toIso8601String()),
  )
  ..post("/prediction", _predictionHandler)
  ..get('/info.json', _infoHandler);
String _jsonEncode(Object? data) =>
    const JsonEncoder.withIndent(' ').convert(data);

const _jsonHeaders = {
  'content-type': 'application/json',
};

final _watch = Stopwatch();

int _requestCount = 0;

final _dartVersion = () {
  final version = Platform.version;
  return version.substring(0, version.indexOf(' '));
}();

Response _infoHandler(Request request) => Response(
      200,
      headers: {
        ..._jsonHeaders,
        'Cache-Control': 'no-store',
      },
      body: _jsonEncode(
        {
          'Dart version': _dartVersion,
          'uptime': _watch.elapsed.toString(),
          'requestCount': ++_requestCount,
        },
      ),
    );

Future<Response> _predictionHandler(Request request) async {
  final body = await request.readAsString();
  final jsonData = jsonDecode(body);
  final url = jsonData['url'];

  final prediction = new Prediction(url);
  final result = await prediction.result();

  return Response(
    200,
    headers: {
      ..._jsonHeaders,
      'Cache-Control': 'no-store',
    },
    body: _jsonEncode(
      {'result': result},
    ),
  );
}
