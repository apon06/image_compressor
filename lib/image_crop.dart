// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:animated_button/animated_button.dart';

class ImageCropPage extends StatefulWidget {
  const ImageCropPage({super.key});

  @override
  ImageCropPageState createState() => ImageCropPageState();
}

class ImageCropPageState extends State<ImageCropPage> {
  final CropController _cropController = CropController();
  File? _imageFile;
  Uint8List? _croppedData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Crop & Save Image',
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_imageFile == null && _croppedData == null)
              Center(
                child: AnimatedButton(
                  onPressed: _pickImage,
                  color: Colors.blue,
                  duration: 5,
                  height: 50,
                  width: 200,
                  child: Text(
                    'Select Image',
                    style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Raleway',
                        color: Colors.white),
                  ),
                ),
              ),
            if (_imageFile != null || _croppedData != null)
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Crop(
                      image: _croppedData ?? _imageFile!.readAsBytesSync(),
                      controller: _cropController,
                      onCropped: (croppedData) {
                        setState(() {
                          _croppedData = croppedData;
                        });
                      },
                      initialSize: 0.8,
                      maskColor: Colors.black.withOpacity(0.4),
                      baseColor: Colors.white,
                      cornerDotBuilder: (size, index) =>
                          DotControl(color: Colors.blueAccent),
                    ),
                    Positioned(
                      bottom: 20,
                      child: AnimatedButton(
                        onPressed: () {
                          _cropController.crop();
                        },
                        color: Colors.blue,
                        duration: 5,
                        height: 50,
                        width: 200,
                        child: Text(
                          'Crop Image',
                          style: TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 16,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_croppedData != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Image.memory(_croppedData!),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedButton(
                          onPressed: _saveCroppedImageToGallery,
                          color: Colors.green,
                          duration: 5,
                          height: 50,
                          width: 150,
                          child: Text(
                            'Save to Gallery',
                            style: TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        AnimatedButton(
                          onPressed: _pickNewImage,
                          color: Colors.blue,
                          duration: 5,
                          height: 50,
                          width: 150,
                          child: Text(
                            'Pick New Image',
                            style: TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 16,
                                color: Colors.white),
                          ),
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
  }

  Future<void> _pickImage() async {
    final pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _imageFile = File(pickedImage.path);
        _croppedData = null;
      });
    }
  }

  Future<void> _pickNewImage() async {
    setState(() {
      _croppedData = null;
      _imageFile = null;
    });
    _pickImage();
  }

  Future<void> _saveCroppedImageToGallery() async {
    if (_croppedData != null) {
      if (await _requestPermission()) {
        final result = await ImageGallerySaverPlus.saveImage(
          _croppedData!,
          quality: 100,
          name: "cropped_image_${DateTime.now().millisecondsSinceEpoch}",
        );
        final isSuccess = result['isSuccess'] ?? false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSuccess ? 'Image saved to gallery!' : 'Failed to save image!',
              style: TextStyle(
                fontFamily: 'Raleway',
                color: Colors.white,
              ),
            ),
            backgroundColor: isSuccess ? Colors.green : Colors.redAccent,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      return status.isGranted;
    }
    return true;
  }
}
