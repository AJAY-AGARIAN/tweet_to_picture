import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:widgets_to_image/widgets_to_image.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  late bool isLoaded;
  String tweetId = "1586059640374456320";

  // WidgetsToImageController to access widget
  WidgetsToImageController controller = WidgetsToImageController();

  // to save image bytes of widget
  Uint8List? bytes;

  @override
  void initState() {
    super.initState();
    isLoaded = false;
    // Enable virtual display.
    if (Platform.isAndroid) WebView.platform = AndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Twitter Embed"),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          bytes = await controller.capture();
          if (bytes != null) {
            saveImage(bytes!, tweetId);
          }
        },
        label: const Text("Capture"),
      ),
      body: Stack(
        children: [
          WidgetsToImage(
            controller: controller,
            child: WebView(
              initialUrl: Uri.dataFromString(
                getHtmlString(tweetId),
                mimeType: 'text/html',
                encoding: Encoding.getByName('utf-8'),
              ).toString(),
              javascriptMode: JavascriptMode.unrestricted,
              javascriptChannels: <JavascriptChannel>{}..add(
                  JavascriptChannel(
                    name: 'Twitter',
                    onMessageReceived: (JavascriptMessage message) {
                      setState(() {
                        isLoaded = true;
                        final previewHeight = double.parse(message.message);
                      });
                    },
                  ),
                ),
            ),
          ),
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(
                milliseconds: 300,
              ),
              child: isLoaded
                  ? const SizedBox.shrink()
                  : const CircularProgressIndicator(),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future saveImage(Uint8List bytes, String tweetId) async {
    final result =
        await ImageGallerySaver.saveImage(bytes, quality: 90, name: tweetId);
    log("000000000");
    log(result.toString());
    /*final appStorage = await getApplicationDocumentsDirectory();
    String path = "${appStorage.path}/$tweetId.png";
    final file = File(path);
    file.writeAsBytes(bytes).then((value) {
      log("Saved @ " + path);
    });*/
  }
}

String getHtmlString(String tweetId) {
  return """
      <html>
      
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>
           
            *{box-sizing: border-box;margin:0px; padding:0px;}
              #container {
                        display: flex;
                        justify-content: center;
                        margin: 0 auto;
                        max-width:95%;
                        max-height:100%;
                    }       
          </style>
        </head>

        <body>

            <div id="container"></div>
                
        </body>

        <script id="twitter-wjs" type="text/javascript" async defer src="https://platform.twitter.com/widgets.js" onload="createMyTweet()"></script>

        <script>
        
       

      function  createMyTweet() {  

         var twtter = window.twttr;
  
         twttr.widgets.createTweet(
          '$tweetId',
          document.getElementById('container'),
          {
            theme:"dark",
          }
        ).then( function( el ) {

              const widget = document.getElementById('container');
              Twitter.postMessage(widget.clientHeight);

        });
      }

        </script>
        
      </html>
    """;
}
