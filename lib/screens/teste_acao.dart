import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("TESTEE"),
      ),
      body: Center(
        //simplesmente adiciono o widget do webview informando qual é a uri inicial do site
          child: InAppWebView(
            initialUrlRequest:URLRequest(url: WebUri("http://127.0.0.1:8000/forgot-password")),
            onLoadStart: (controller, url) {
              setState(() {
                //this.url = url.toString();
                //urlController.text = this.url;
              });
              print("onLoadStart");
            },
            onLoadStop: (controller, url) async {
              setState(() {
                //this.url = url.toString();
                //urlController.text = this.url;
              });
              print("onLoadStop");
            },
            onReceivedError: (controller, request, error) {
              print("onReceivedError");
            },
            onProgressChanged: (controller, progress) {
              setState(() {
                //this.progress = progress / 100;
                //urlController.text = url;
              });
              print("onProgressChanged");
            },
            onUpdateVisitedHistory: (controller, url, androidIsReload) {
              print("onUpdateVisitedHistory");
            },
            onConsoleMessage: (controller, consoleMessage) {
              if (kDebugMode) {
                print(consoleMessage);
              }
            },
          )
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){} ,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
