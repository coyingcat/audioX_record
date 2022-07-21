import 'dart:async';
import 'dart:io';

import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

class AudioRecorder {
  static const MethodChannel _channel = const MethodChannel('audio_recorder');

  /// use [LocalFileSystem] to permit widget testing
  static LocalFileSystem fs = LocalFileSystem();

  static Future start(String path, AudioOutputFormat audioOutputFormat) async {
    String extension;
    if (path != null) {
      if (audioOutputFormat != null) {
        if (_convertStringInAudioOutputFormat(p.extension(path)) !=
            audioOutputFormat) {
          extension = _convertAudioOutputFormatInString(audioOutputFormat);
          path += extension;
        } else {
          extension = p.extension(path);
        }
      } else {
        if (_isAudioOutputFormat(p.extension(path))) {
          extension = p.extension(path);
        } else {
          extension = ".m4a"; // default value
          path += extension;
        }
      }
      File file = fs.file(path);
      if (await file.exists()) {
        throw new Exception("A file already exists at the path :" + path);
      } else if (!await file.parent.exists()) {
        throw new Exception("The specified parent directory does not exist");
      }
    } else {
      extension = ".m4a"; // default value
    }
    return _channel
        .invokeMethod('start', {"path": path, "extension": extension});
  }

  static Future<void> pause() async {
    return _channel.invokeMethod('pause');
  }

  static Future<void> resume() async {
    return _channel.invokeMethod('resume');
  }

  static Future<Recording?> stop() async {
    Map<String, dynamic> response =
        Map.from(await _channel.invokeMethod('stop'));
    if (response != null) {
      int duration = response['duration'];
      String fmt = response['audioOutputFormat'];
      AudioOutputFormat? outputFmt = _convertStringInAudioOutputFormat(fmt);
      if (fmt != null && outputFmt != null) {
        Recording recording = new Recording(
            new Duration(milliseconds: duration),
            response['path'],
            outputFmt,
            response['audioOutputFormat']);
        return recording;
      }
    } else {
      return null;
    }
  }

  static Future<bool> get isRecording async {
    bool isRecording = await _channel.invokeMethod('isRecording');
    return isRecording;
  }

  static Future<bool> get hasPermissions async {
    bool hasPermission = await _channel.invokeMethod('hasPermissions');
    return hasPermission;
  }

  static AudioOutputFormat? _convertStringInAudioOutputFormat(
      String extension) {
    switch (extension) {
      case ".wav":
        return AudioOutputFormat.WAV;
      case ".mp4":
      case ".aac":
      case ".m4a":
        return AudioOutputFormat.AAC;
      default:
        return null;
    }
  }

  static bool _isAudioOutputFormat(String extension) {
    switch (extension) {
      case ".wav":
      case ".mp4":
      case ".aac":
      case ".m4a":
        return true;
      default:
        return false;
    }
  }

  static String _convertAudioOutputFormatInString(
      AudioOutputFormat outputFormat) {
    switch (outputFormat) {
      case AudioOutputFormat.WAV:
        return ".wav";
      case AudioOutputFormat.AAC:
        return ".m4a";
      default:
        return ".m4a";
    }
  }
}

enum AudioOutputFormat { AAC, WAV }

class Recording {
  // File path
  String path;
  // File extension
  String extension;
  // Audio duration in milliseconds
  Duration duration;
  // Audio output format
  AudioOutputFormat audioOutputFormat;

  Recording(this.duration, this.path, this.audioOutputFormat, this.extension);
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

const kStarted = "开始录音";
const kPaused = "暂停";

class _MyHomePageState extends State<MyHomePage> {
  String name = kStarted;

  Future<void> _audioGoOn() async {
    switch (name) {
      case kStarted:
        // Check permissions before starting
        bool hasPermissions = await AudioRecorder.hasPermissions;
        if (hasPermissions) {
          // Get the state of the recorder
          bool isRecording = await AudioRecorder.isRecording;
          if (isRecording == false) {
            await AudioRecorder.start("10100", AudioOutputFormat.AAC);
            setState(() {
              name = kPaused;
            });
          }
        }
        break;
      case kPaused:
        await AudioRecorder.pause();
        setState(() {
          name = "继续录音";
        });
        break;
      default:
        await AudioRecorder.resume();
        setState(() {
          name = kPaused;
        });
        break;
    }
  }

  Future<void> _audioEnd() async {
// Stop recording
    Recording? recording = await AudioRecorder.stop();
    if (recording != null) {
      String path = recording.path;
      AudioOutputFormat fmt = recording.audioOutputFormat;
      String ext = recording.extension;
      Duration duration = recording.duration;
      print(
          "Path : ${path},  Format : ${fmt},  Duration : ${duration},  Extension : ${ext},");
    }

    setState(() {
      name = kStarted;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> views = [
      ElevatedButton(
        child: Text(
          name,
          style: Theme.of(context).textTheme.headline4,
        ),
        onPressed: _audioGoOn,
      ),
    ];
    if (name != kStarted) {
      views.add(SizedBox(height: 80));
      views.add(ElevatedButton(
        child: Text(
          "结束录音",
          style: Theme.of(context).textTheme.headline4,
        ),
        onPressed: _audioEnd,
      ));
    }
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: views,
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
