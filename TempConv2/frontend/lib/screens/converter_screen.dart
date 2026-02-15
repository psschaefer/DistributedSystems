import 'package:flutter/material.dart';
import 'package:grpc/grpc.dart';
import '../generated/tempconv.pb.dart';
import '../grpc_client.dart';
import '../src/grpc_base_url_stub.dart'
    if (dart.library.html) '../src/grpc_base_url_web.dart' as grpc_base_url;

/// Turns a gRPC or other exception into a short user-facing summary.
String formatErrorSummary(Object e) {
  if (e is GrpcError) {
    final code = e.codeName ?? '${e.code}';
    final msg = (e.message ?? '').trim();
    if (msg.isEmpty) return 'Backend error ($code)';
    if (msg.length <= 120) return '$code: $msg';
    return '$code: ${msg.substring(0, 117)}...';
  }
  final s = e.toString();
  return s.length <= 120 ? s : '${s.substring(0, 117)}...';
}

/// Full error details for debugging (copyable).
String formatErrorDetails(Object e, [Object? stackTrace]) {
  final buf = StringBuffer();
  if (e is GrpcError) {
    buf.writeln('code: ${e.code}');
    buf.writeln('codeName: ${e.codeName}');
    buf.writeln('message: ${e.message ?? ""}');
    if (e.details != null && e.details!.isNotEmpty) buf.writeln('details: ${e.details}');
    if (e.rawResponse != null) buf.writeln('rawResponse: ${e.rawResponse}');
    if (e.trailers != null && e.trailers!.isNotEmpty) buf.writeln('trailers: ${e.trailers}');
  } else {
    buf.writeln(e.toString());
  }
  if (stackTrace != null) buf.writeln('\n$stackTrace');
  return buf.toString().trim();
}

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  final TextEditingController _inputController = TextEditingController();
  String _result = '';
  bool _isLoading = false;
  bool _isCelsiusToFahrenheit = true;
  String? _errorMessage;
  String? _errorDetails;

  String get _grpcBaseUrl => grpc_base_url.grpcWebBaseUrl;

  Future<void> _convert() async {
    final inputText = _inputController.text.trim();
    if (inputText.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a temperature value';
        _errorDetails = null;
        _result = '';
      });
      return;
    }

    final value = double.tryParse(inputText);
    if (value == null) {
      setState(() {
        _errorMessage = 'Please enter a valid number';
        _errorDetails = null;
        _result = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _errorDetails = null;
    });

    try {
      final client = createTempConvClient(_grpcBaseUrl);
      final request = ConversionRequest(value: value);
      final response = _isCelsiusToFahrenheit
          ? await client.celsiusToFahrenheit(request)
          : await client.fahrenheitToCelsius(request);

      setState(() {
        _result = response.description;
        _isLoading = false;
      });
    } catch (e, st) {
      setState(() {
        _errorMessage = formatErrorSummary(e);
        _errorDetails = formatErrorDetails(e, st);
        _isLoading = false;
      });
      debugPrint('Convert error: $e\n$st');
    }
  }

  void _swapConversion() {
    setState(() {
      _isCelsiusToFahrenheit = !_isCelsiusToFahrenheit;
      _result = '';
      _errorMessage = null;
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fromUnit = _isCelsiusToFahrenheit ? 'Celsius' : 'Fahrenheit';
    final toUnit = _isCelsiusToFahrenheit ? 'Fahrenheit' : 'Celsius';
    final fromSymbol = _isCelsiusToFahrenheit ? '\u00B0C' : '\u00B0F'; // °C / °F

    return Scaffold(
      appBar: AppBar(
        title: const Text('TempConv2 (gRPC)'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.thermostat,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Temperature Converter',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '$fromUnit → $toUnit (gRPC)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _inputController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Enter temperature',
                    suffixText: fromSymbol,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.edit),
                  ),
                  onSubmitted: (_) => _convert(),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _swapConversion,
                  icon: const Icon(Icons.swap_vert),
                  label: Text('Swap to $toUnit → $fromUnit'),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _isLoading ? null : _convert,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.calculate),
                  label: Text(_isLoading ? 'Converting...' : 'Convert'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: theme.colorScheme.onErrorContainer,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: theme.colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_errorDetails != null && _errorDetails!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Theme(
                            data: theme.copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              childrenPadding: const EdgeInsets.only(top: 4),
                              title: Text(
                                'Show full details',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onErrorContainer,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              children: [
                                SelectableText(
                                  _errorDetails!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onErrorContainer,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                if (_result.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 40,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _result,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
