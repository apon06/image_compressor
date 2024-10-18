// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:typed_data';
import 'dart:io';
import 'package:animated_button/animated_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:before_after/before_after.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ImageCompressorPage extends StatefulWidget {
  const ImageCompressorPage({super.key});

  @override
  ImageCompressorPageState createState() => ImageCompressorPageState();
}

class ImageCompressorPageState extends State<ImageCompressorPage> {
  List<File> _images = [];
  List<File> _compressedImages = [];
  double _quality = 50.0;
  String _format = 'jpeg';
  bool _isLoading = false;

  Future<void> _saveCustomProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('quality', _quality);
    await prefs.setString('format', _format);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile Saved!")),
    );
  }

  Future<void> _loadCustomProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _quality = prefs.getDouble('quality') ?? 50.0;
      _format = prefs.getString('format') ?? 'jpeg';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile Loaded!")),
    );
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    setState(() {
      _images = pickedFiles.map((file) => File(file.path)).toList();
      _compressedImages.clear();
    });
  }

  Future<File> _convertImage(File file, String format) async {
    final bytes = await file.readAsBytes();
    String newPath = file.path;
    if (format == 'png') {
      newPath = newPath.replaceAll(".jpg", ".png").replaceAll(".jpeg", ".png");
    } else if (format == 'webp') {
      newPath =
          newPath.replaceAll(".jpg", ".webp").replaceAll(".jpeg", ".webp");
    }
    return File(newPath)..writeAsBytesSync(bytes);
  }

  Future<void> _compressImages() async {
    if (_images.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    List<File> compressedFiles = [];

    for (var image in _images) {
      final imageBytes = image.readAsBytesSync();
      final compressedImageBytes = await FlutterImageCompress.compressWithList(
        imageBytes,
        quality: _quality.toInt(),
      );

      final directory = await getTemporaryDirectory();
      final filePath =
          '${directory.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(filePath);
      await file.writeAsBytes(compressedImageBytes);

      compressedFiles.add(await _convertImage(file, _format));
    }

    setState(() {
      _compressedImages = compressedFiles;
      _isLoading = false;
    });
  }

  Future<void> _captureAndSave() async {
    if (_compressedImages.isEmpty) return;

    for (var i = 0; i < _compressedImages.length; i++) {
      final imageFile = _compressedImages[i];
      final imageBytes = await imageFile.readAsBytes();
      final result = await ImageGallerySaverPlus.saveImage(
        Uint8List.fromList(imageBytes),
        quality: _quality.toInt(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['isSuccess'] == true
                ? 'Image saved to gallery!'
                : 'Failed to save image',
          ),
        ),
      );
    }
  }

  Future<void> _deleteImage(int index) async {
    final confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Image"),
          content: const Text("Are you sure you want to delete this image?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text("Delete"),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _compressedImages.removeAt(index);
      });
    }
  }

  Future<void> _shareImage(File imageFile) async {
    await Share.shareXFiles([XFile(imageFile.path)],
        text: 'Check out this compressed image!');
  }

  void _showPreview(File original, File compressed) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Preview Before Saving'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BeforeAfter(
                before: Image.file(original),
                after: Image.file(compressed),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Compressor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _captureAndSave,
          ),
          IconButton(
            icon: const Icon(FontAwesomeIcons.github),
            onPressed: () async {
              String codeUrl = 'https://github.com/gokeihub/image_compressor';
              final Uri url = Uri.parse(codeUrl);
              if (await canLaunch(url.toString())) {
                await launch(url.toString());
              } else {
                await launch(url.toString());
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Quality: ${_quality.toInt()}',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Slider(
                      value: _quality,
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: _quality.toInt().toString(),
                      onChanged: (value) {
                        setState(() {
                          _quality = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedButton(
                  onPressed: _pickImages,
                  color: Colors.blue,
                  duration: 5,
                  height: 50,
                  width: 150,
                  child: const Text(
                    'Pick Images',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedButton(
                  onPressed: _compressImages,
                  color: Colors.blue,
                  duration: 5,
                  height: 50,
                  width: 150,
                  child: const Text(
                    'Compress Images',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else
              Expanded(
                child: _compressedImages.isEmpty
                    ? const Center(child: Text('No images to display'))
                    : MasonryGridView.count(
                        crossAxisCount: 2,
                        itemCount: _compressedImages.length,
                        itemBuilder: (BuildContext context, int index) {
                          final image = _compressedImages[index];
                          final originalImage = _images[index];
                          return GestureDetector(
                            onLongPress: () => _deleteImage(index),
                            onTap: () => _showPreview(originalImage, image),
                            child: Card(
                              elevation: 5,
                              margin: const EdgeInsets.all(4),
                              child: Column(
                                children: [
                                  Image.file(
                                    image,
                                    fit: BoxFit.cover,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Size: ${_getSizeInKB(image)} KB',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.share),
                                              onPressed: () =>
                                                  _shareImage(image),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        mainAxisSpacing: 4.0,
                        crossAxisSpacing: 4.0,
                      ),
              ),
          ],
        ),
      ),
    );
  }

  String _getSizeInKB(File file) {
    final bytes = file.lengthSync();
    return (bytes / 1024).toStringAsFixed(2);
  }
}
