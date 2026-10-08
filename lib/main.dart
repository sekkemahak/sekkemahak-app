import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() {
  runApp(const SekkeMahakApp());
}

class SekkeMahakApp extends StatelessWidget {
  const SekkeMahakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'سکه ماهک',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.amber,
        fontFamily: 'Vazirmatn',
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  InAppWebViewController? _webViewController;
  final String homeUrl = 'https://sekkemahak.ir';
  bool isLoading = true;
  bool hasInternet = true;
  bool canGoBack = false;
  int currentTab = 0;

  final List<_TabItem> tabs = [
    _TabItem(title: 'خانه', url: 'https://sekkemahak.ir', icon: Icons.home),
    _TabItem(title: 'دسته‌بندی', url: 'https://sekkemahak.ir/shop', icon: Icons.grid_view),
    _TabItem(title: 'سبد خرید', url: 'https://sekkemahak.ir/cart', icon: Icons.shopping_cart),
    _TabItem(title: 'حساب من', url: 'https://sekkemahak.ir/my-account', icon: Icons.person),
  ];

  @override
  void initState() {
    super.initState();
    _checkInternet();
    Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        hasInternet = result != ConnectivityResult.none;
      });
      if (hasInternet) _reload();
    });
  }

  Future<void> _checkInternet() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      hasInternet = result != ConnectivityResult.none;
    });
  }

  void _reload() {
    _webViewController?.reload();
  }

  Future<void> _goToTab(int index) async {
    setState(() => currentTab = index);
    if (index == 0) {
      await _webViewController?.loadUrl(
        urlRequest: URLRequest(url: WebUri(homeUrl)),
      );
    } else {
      await _webViewController?.loadUrl(
        urlRequest: URLRequest(url: WebUri(tabs[index].url)),
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (await _webViewController?.canGoBack() ?? false) {
      await _webViewController?.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            await SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سکه ماهک'),
          centerTitle: true,
          backgroundColor: Colors.amber,
        ),
        body: hasInternet
            ? Stack(
                children: [
                  InAppWebView(
                    initialUrlRequest: URLRequest(url: WebUri(homeUrl)),
                    initialOptions: InAppWebViewGroupOptions(
                      crossPlatform: InAppWebViewOptions(
                        javaScriptEnabled: true,
                        useHybridComposition: true,
                      ),
                    ),
                    onWebViewCreated: (controller) {
                      _webViewController = controller;
                    },
                    onLoadStart: (controller, url) {
                      setState(() => isLoading = true);
                    },
                    onLoadStop: (controller, url) async {
                      setState(() => isLoading = false);
                      canGoBack = await controller.canGoBack();
                    },
                    shouldOverrideUrlLoading: (controller, action) async {
                      final url = action.request.url.toString();
                      if (url.startsWith('https://sekkemahak.ir')) {
                        return NavigationActionPolicy.ALLOW;
                      }
                      if (url.startsWith('http')) {
                        await launchUrl(
                          action.request.url!,
                          mode: LaunchMode.externalApplication,
                        );
                        return NavigationActionPolicy.CANCEL;
                      }
                      return NavigationActionPolicy.ALLOW;
                    },
                  ),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator()),
                ],
              )
            : _buildNoInternet(),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: currentTab,
          onTap: _goToTab,
          selectedItemColor: Colors.amber,
          items: tabs
              .map((t) => BottomNavigationBarItem(
                    icon: Icon(t.icon),
                    label: t.title,
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildNoInternet() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              'اتصال اینترنت برقرار نیست',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'لطفاً اتصال اینترنت خود را بررسی کنید',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _checkInternet();
                if (hasInternet) _reload();
              },
              child: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem {
  final String title;
  final String url;
  final IconData icon;
  _TabItem({required this.title, required this.url, required this.icon});
}
