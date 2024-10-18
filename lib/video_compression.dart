// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_compress_plus/video_compress_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class VideoCompressApp extends StatelessWidget {
  const VideoCompressApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Compress App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: VideoCompressPage(),
    );
  }
}

class VideoCompressPage extends StatefulWidget {
  const VideoCompressPage({super.key});

  @override
  VideoCompressPageState createState() => VideoCompressPageState();
}

class VideoCompressPageState extends State<VideoCompressPage> {
  String? _selectedVideoPath;
  String? _compressedVideoPath;
  bool _isCompressing = false;

  @override
  void dispose() {
    // Release resources used by video_compress package
    VideoCompress.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null) {
      setState(() {
        _selectedVideoPath = result.files.single.path;
        _compressedVideoPath = null;
      });
    }
  }

  Future<void> _compressVideo() async {
    if (_selectedVideoPath == null) return;

    setState(() {
      _isCompressing = true;
    });

    final info = await VideoCompress.compressVideo(
      _selectedVideoPath!,
      quality: VideoQuality.MediumQuality, // Choose the desired quality
      deleteOrigin: false, // If true, the original video will be deleted
    );

    setState(() {
      _compressedVideoPath = info!.file!.path;
      _isCompressing = false;
    });
  }

  Future<void> _saveCompressedVideo() async {
    if (_compressedVideoPath == null) return;

    Directory? directory;
    if (Platform.isAndroid) {
      // For Android, save to the Downloads directory
      directory = Directory('/storage/emulated/0/Download');
    } else if (Platform.isIOS) {
      // For iOS, save to the app's documents directory
      directory = await getApplicationDocumentsDirectory();
    }

    if (directory != null && await directory.exists()) {
      final newFilePath =
          '${directory.path}/compressed_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final File compressedFile = File(_compressedVideoPath!);
      final savedFile = await compressedFile.copy(newFilePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video saved to: ${savedFile.path}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save the video.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Compress App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _pickVideo,
              child: Text('Pick Video'),
            ),
            SizedBox(height: 16),
            _selectedVideoPath != null
                ? Text('Selected video: $_selectedVideoPath')
                : Text('No video selected'),
            SizedBox(height: 16),
            _selectedVideoPath != null
                ? ElevatedButton(
                    onPressed: _compressVideo,
                    child: _isCompressing
                        ? CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : Text('Compress Video'),
                  )
                : Container(),
            SizedBox(height: 16),
            _compressedVideoPath != null
                ? Column(
                    children: [
                      Text('Compressed video saved at: $_compressedVideoPath'),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _saveCompressedVideo,
                        child: Text('Save Compressed Video'),
                      ),
                    ],
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}
