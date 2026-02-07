import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import '../../../../../app/services/payment_service.dart';

class PaymentWebView extends StatefulWidget {
  final String paymentUrl;
  final String title;

  const PaymentWebView({
    super.key,
    required this.paymentUrl,
    this.title = 'Secure Payment',
  });

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          onNavigationRequest: (NavigationRequest request) {
            // INTERCEPT SUCCESS URL
            if (request.url.startsWith(PaymentService.successRedirectUrl)) {
              Navigator.pop(context, true); // Return TRUE for success interception
              return NavigationDecision.prevent;
            }
            // INTERCEPT CANCEL URL
            if (request.url.startsWith(PaymentService.cancelRedirectUrl)) {
              Navigator.pop(context, false); // Return FALSE for cancellation
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false), // Treat manual close as cancel
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}