import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_compressor/video_compress.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Video_compressor',
      theme: ThemeData.dark(),
      home: Mainpage(),
    );
  }
}

//mainpage

class Mainpage extends StatefulWidget {
  const Mainpage({Key? key}) : super(key: key);

  @override
  _MainpageState createState() => _MainpageState();
}

class _MainpageState extends State<Mainpage> {
  File? fileVideo;
  Uint8List? thumbnailBytes;
  int? videoSize;
  MediaInfo? compressVideoInfo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Compress'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: clearSelection,
            child: Text('Clear'),
            style: TextButton.styleFrom(primary: Colors.white),
          )
        ],
      ),
      body: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.all(40),
        child: buildContent(),
      ),
    );
  }

  void clearSelection() => setState(() {
        compressVideoInfo = null;
        fileVideo = null;
      });

  Widget buildContent() {
    if (fileVideo == null) {
      return ButtonWidget(
        text: 'Pick Video',
        onClicked: pickVideo,
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buildThumbnail(),
          SizedBox(height: 24),
          buildVideoInfo(),
          SizedBox(height: 24),
          buildVideoCompressedInfo(),
          SizedBox(height: 24),
          ButtonWidget(text: 'Compress Video', onClicked: compressVideo)
        ],
      );
    }
  }

  Widget buildThumbnail() => thumbnailBytes == null
      ? CircularProgressIndicator()
      : Image.memory(
          thumbnailBytes!,
          height: 200,
        );

  Widget buildVideoInfo() {
    if (videoSize == null)
      return Container();
    else {
      final size = videoSize! / 1000;
      return Column(
        children: [
          Text(
            'Original Video Info',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Size $size KB',
            style: TextStyle(fontSize: 20),
          )
        ],
      );
    }
  }

  Future pickVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.getVideo(source: ImageSource.gallery);

    if (pickedFile == null) return;
    final file = File(pickedFile.path);

    setState(() => fileVideo = file);
    generateThumbnail(fileVideo!);
    getVideoSize(fileVideo!);
  }

  Future getVideoSize(File file) async {
    final size = await file.length();
    setState(() => videoSize = size);
  }

  Future generateThumbnail(File file) async {
    final thumbnailBytes = await VideoCompress.getByteThumbnail(file.path);

    setState(() => this.thumbnailBytes = thumbnailBytes);
  }

  Future compressVideo() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: ProgressDialogWidget(),
      ),
    );

    final info = await VideoCompressApi.compressVideo(fileVideo!);

    setState(() => compressVideoInfo = info);
    Navigator.of(context).pop();
  }

  Widget buildVideoCompressedInfo() {
    if (compressVideoInfo == null) return Container();
    final size = compressVideoInfo!.filesize! / 1000;
    return Column(
      children: [
        Text(
          'Compressed Video Info',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Size $size KB',
          style: TextStyle(fontSize: 20),
        ),
        Text(
          '${compressVideoInfo!.path}',
          textAlign: TextAlign.center,
        )
      ],
    );
  }
}

//button

class ButtonWidget extends StatelessWidget {
  final String text;
  final VoidCallback onClicked;
  const ButtonWidget({
    Key? key,
    required this.text,
    required this.onClicked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: Size.fromHeight(50),
          shape: StadiumBorder(),
        ),
        child: FittedBox(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ),
        onPressed: onClicked,
      );
}

class ProgressDialogWidget extends StatefulWidget {
  const ProgressDialogWidget({Key? key}) : super(key: key);

  @override
  _ProgressDialogWidgetState createState() => _ProgressDialogWidgetState();
}

class _ProgressDialogWidgetState extends State<ProgressDialogWidget> {
  late Subscription subscription;
  double? progress;

  @override
  void initState() {
    super.initState();
    subscription = VideoCompress.compressProgress$.subscribe((progress) {
      setState(() {
        this.progress = progress;
      });
    });
  }

  @override
  void dispose() {
    VideoCompress.cancelCompression();
    subscription.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = progress == null ? progress : progress! / 1000;
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Compressing video..',
            style: TextStyle(
              fontSize: 20,
            ),
          ),
          SizedBox(height: 24),
          LinearProgressIndicator(value: value, minHeight: 12),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => VideoCompress.cancelCompression(),
            child: Text('Cancel'),
          )
        ],
      ),
    );
  }
}
