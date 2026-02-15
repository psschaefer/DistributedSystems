// Web: use browser origin so requests hit the same host. When using Flutter dev server
// (e.g. localhost:12345), origin has no proxy → 404. So point to Envoy (port 8080) on localhost.
import 'dart:html' as html;

String get grpcWebBaseUrl {
  final o = html.window.location;
  final isLocalDev = o.hostname == 'localhost' || o.hostname == '127.0.0.1';
  final isNotPort80 = o.port != '80' && o.port.isNotEmpty;
  if (isLocalDev && isNotPort80) {
    return '${o.protocol}//${o.hostname}:8080';
  }
  return o.origin;
}
