// gRPC client for TempConvService (hand-written to match proto).
import 'package:grpc/grpc.dart';
import 'tempconv.pb.dart';

final _celsiusToFahrenheit = ClientMethod<ConversionRequest, ConversionResponse>(
  '/tempconv.TempConvService/CelsiusToFahrenheit',
  (ConversionRequest r) => r.writeToBuffer(),
  (List<int> bytes) => ConversionResponse.mergeFromBuffer(bytes),
);

final _fahrenheitToCelsius = ClientMethod<ConversionRequest, ConversionResponse>(
  '/tempconv.TempConvService/FahrenheitToCelsius',
  (ConversionRequest r) => r.writeToBuffer(),
  (List<int> bytes) => ConversionResponse.mergeFromBuffer(bytes),
);

class TempConvServiceClient extends Client {
  TempConvServiceClient(super.channel);

  ResponseFuture<ConversionResponse> celsiusToFahrenheit(
    ConversionRequest request, {
    CallOptions? options,
  }) =>
      $createUnaryCall(_celsiusToFahrenheit, request, options: options);

  ResponseFuture<ConversionResponse> fahrenheitToCelsius(
    ConversionRequest request, {
    CallOptions? options,
  }) =>
      $createUnaryCall(_fahrenheitToCelsius, request, options: options);
}
