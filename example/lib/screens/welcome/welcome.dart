import 'package:example/features/media_devices/ui/AudioInputSelector.dart';
import 'package:example/features/media_devices/ui/AudioOutputSelector.dart';
import 'package:example/features/media_devices/ui/VideoInputSelector.dart';
import 'package:flutter/material.dart';

class Welcome extends StatefulWidget {
  static const String routePath = '/';

  const Welcome({Key? key}) : super(key: key);

  @override
  _WelcomeState createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> {
  final TextEditingController _textEditingController = TextEditingController();
  String url = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'mediasoup-client-flutter',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        shadowColor: Colors.grey,
        elevation: 5,
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.only(top: 15),
          margin: const EdgeInsets.symmetric(horizontal: 15),
          alignment: Alignment.center,
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(
                    Radius.circular(10.0),
                  ),
                ),
                child: TextField(
                  style: const TextStyle(
                    // fontSize: 15.0,
                    color: Colors.black,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.only(left: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 1,
                        style: BorderStyle.solid,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 1,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    hintText: 'Room url (empty = random room)',
                    hintStyle: TextStyle(
                      fontSize: 15.0,
                      color: Colors.black.withAlpha(90),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 1,
                        style: BorderStyle.solid,
                      ),
                    ),
                    suffixIcon: url.isNotEmpty
                        ? GestureDetector(
                            child: const Icon(
                              Icons.close,
                              color: Colors.black,
                            ),
                            onTap: () {
                              _textEditingController.clear();
                              setState(() {
                                url = '';
                              });
                            },
                          )
                        : null,
                  ),
                  maxLines: 1,
                  onChanged: (value) {
                    setState(() {
                      url = value;
                    });
                  },
                  controller: _textEditingController,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/room',
                    arguments: url,
                  );
                },
                style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.black)),
                child: Text(url.isNotEmpty ? 'Join' : 'Join to Random Room'),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.mic),
                      Text(
                        'Audio Input',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                  const AudioInputSelector(),
                ],
              ),
              Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.videocam),
                      Text(
                        'Video Input',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                  const VideoInputSelector(),
                ],
              ),
              Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.videocam),
                      Text(
                        'Audio Output',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                  const AudioOutputSelector(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
