import 'package:grpc/grpc_web.dart';
import 'generated/tempconv_grpc.dart';

/// Creates a gRPC-Web channel and TempConvService client.
/// [baseUrl] should be the base URL of the gRPC-Web proxy (e.g. same origin /grpc).
TempConvServiceClient createTempConvClient(String baseUrl) {
  final uri = Uri.parse(baseUrl);
  final channel = GrpcWebClientChannel.xhr(uri);
  // On web, GrpcWebClientChannel is not a runtime subtype of ClientChannel; pass as dynamic.
  return TempConvServiceClient(channel as dynamic);
}
