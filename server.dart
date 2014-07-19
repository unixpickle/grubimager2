import 'dart:io';
import 'package:query_string/query_string.dart';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('Usage: dart server.dart <port>');
    stderr.flush().then((_) => exit(1));
    return;
  }

  var port = int.parse(args[0]);
  var bindCb = (x) => x.listen(requestHandler);
  var errorCb = (_) {
    print('Failed to listen on port $port');
    exit(1);
  };

  HttpServer.bind(InternetAddress.ANY_IP_V4, port).then(bindCb)
  .catchError(errorCb);
}

void requestHandler(HttpRequest request) {
  var uri = request.uri.toString();
  if (uri == '/script.js') {
    return serveFile('build/script.js', 'text/javascript', request);
  } else if (uri == '/script.dart') {
    return serveFile('script.dart', 'application/dart', request);
  } else if (uri == '/script.js.map') {
    return serveFile('build/script.js.map', 'application/octet-stream',
      request);
  } else if (['/', ''].contains(uri)) {
    return serveFile('index.html', 'text/html', request);
  }

  var response = request.response;
  response.statusCode = 404;
  response.headers.contentType = 'text/plain';
  response..write('404 not found: $uri')..close();
}

void serveFile(String path, String type, HttpRequest request) {
  var response = request.response;
  new File(path).readAsBytes().then((body) {
    response.headers.contentType = type;
    response..add(body)..close();
  }).catchError((error) {
    response.headers.contentType = 'text/plain';
    response.statusCode = 500;
    response..write('Error reading file: $error')..close();
  });
}
