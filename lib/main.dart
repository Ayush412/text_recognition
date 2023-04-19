import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool textScanning = false;
  XFile? imageFile;
  int? totalFiles;
  int? currentFile;
  String scannedText = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Text Recognition example"),
      ),
      body: Center(
          child: SingleChildScrollView(
        child: Container(
            margin: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (textScanning) const CircularProgressIndicator(),
                if (!textScanning && imageFile == null)
                  Container(
                    width: 300,
                    height: 300,
                    color: Colors.grey[300]!,
                  ),
                if (imageFile != null) ...[
                  Container(
                    width: MediaQuery.of(context).size.width,
                    constraints: BoxConstraints(maxHeight: 300),
                    child: Image.file(
                      File(imageFile!.path),
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        padding: const EdgeInsets.only(top: 10),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            primary: Colors.white,
                            onPrimary: Colors.grey,
                            shadowColor: Colors.grey[400],
                            elevation: 10,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0)),
                          ),
                          onPressed: textScanning
                              ? null
                              : () {
                                  getImage(ImageSource.gallery);
                                },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 5, horizontal: 5),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.image,
                                  size: 30,
                                ),
                                Text(
                                  "Gallery",
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey[600]),
                                )
                              ],
                            ),
                          ),
                        )),
                    Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        padding: const EdgeInsets.only(top: 10),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            primary: Colors.white,
                            onPrimary: Colors.grey,
                            shadowColor: Colors.grey[400],
                            elevation: 10,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0)),
                          ),
                          onPressed: textScanning
                              ? null
                              : () {
                                  getImage(ImageSource.camera);
                                },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 5, horizontal: 5),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  size: 30,
                                ),
                                Text(
                                  "Camera",
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey[600]),
                                )
                              ],
                            ),
                          ),
                        )),
                    Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        padding: const EdgeInsets.only(top: 10),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            primary: Colors.white,
                            onPrimary: Colors.grey,
                            shadowColor: Colors.grey[400],
                            elevation: 10,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0)),
                          ),
                          onPressed: textScanning
                              ? null
                              : () {
                                  getBulkImages();
                                },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 5, horizontal: 5),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.folder,
                                  size: 30,
                                ),
                                Text(
                                  "Bulk Images",
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey[600]),
                                )
                              ],
                            ),
                          ),
                        )),
                  ],
                ),
                if (totalFiles != null && currentFile != null) ...[
                  SizedBox(height: 20),
                  Text(
                    totalFiles == currentFile
                        ? 'Done!'
                        : 'Processing ($currentFile/$totalFiles)...',
                    style: TextStyle(fontSize: 16),
                  )
                ],
                if (scannedText != "" && !textScanning) ...[
                  Container(
                    padding: const EdgeInsets.only(top: 10),
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: Icon(Icons.copy),
                      onPressed: () async {
                        await Clipboard.setData(
                            ClipboardData(text: scannedText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Text copied to clipboard'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    child: SelectableText(
                      scannedText,
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ],
              ],
            )),
      )),
    );
  }

  void getImage(ImageSource source) async {
    try {
      final pickedImage = await ImagePicker().pickImage(source: source);
      if (pickedImage != null) {
        textScanning = true;
        totalFiles = null;
        currentFile = null;
        imageFile = null;
        setState(() {});
        getRecognizedText(pickedImage);
      }
    } catch (e) {
      textScanning = false;
      imageFile = null;
      scannedText = "Error occurred while scanning";
      setState(() {});
    }
  }

  getBulkImages() async {
    if (await Permission.storage.request().isGranted) {
      imageFile = null;
      textScanning = true;
      totalFiles = null;
      currentFile = null;
      setState(() {});
      final downloadDirectory = await getExternalStorageDirectory();
      String filePath =
          '${downloadDirectory?.path}/TextScan_${DateTime.now().toIso8601String()}.txt';

      final imageDirectory = await getDirectory();
      List<FileSystemEntity> fileList = await imageDirectory.list().toList();
      List<File> imageFiles = [];
      List<String> imageExtensions = ['jpg', 'jpeg', 'png'];

      for (FileSystemEntity file in fileList) {
        if (file is File &&
            imageExtensions.contains(file.path.split('.').last)) {
          imageFiles.add(file);
        }
      }

      if (imageFiles.isNotEmpty) {
        totalFiles = imageFiles.length;
        int count = 0;
        String allRecognizedText = "";
        for (File file in imageFiles) {
          count++;
          setState(() {
            currentFile = count;
          });
          String recognizedText =
              await getRecognizedText(XFile(file.path), isBulk: true);
          allRecognizedText += recognizedText + '\n';
        }
        File textFile = File(filePath);
        await textFile.writeAsString(allRecognizedText);
        scannedText = 'Text from all images saved to:\n$filePath';
      } else {
        scannedText = 'No images in folder';
      }
      imageFile = null;
      textScanning = false;
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enable storage permission'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<Directory> getDirectory() async {
    return await FilePicker.platform.getDirectoryPath().then((dir) {
      return Directory(dir!);
    });
  }

  Future<String> getRecognizedText(XFile image, {bool isBulk = false}) async {
    final inputImage = InputImage.fromFilePath(image.path);

    //Look for a face
    final faceDetector = GoogleMlKit.vision.faceDetector();
    final recognizedFaceList = await faceDetector.processImage(inputImage);
    faceDetector.close();
    if (recognizedFaceList.isEmpty) {
      if (!isBulk)
        setState(() {
          imageFile = image;

          textScanning = false;
          scannedText = "No faces found, make sure the ID has a face on it";
        });
      return scannedText;
    }

    // Get text
    final textDetector = GoogleMlKit.vision.textRecognizer();
    RecognizedText recognizedText = await textDetector.processImage(inputImage);
    await textDetector.close();

    scannedText = "";
    bool foundCollege = false;
    scannedText = scannedText +
        'File Name: ${path.basename(image.path)}\n' +
        'Total Blocks: ${recognizedText.blocks.length}\n';
    int blockIndex = -1;
    for (TextBlock block in recognizedText.blocks) {
      blockIndex++;
      if (checkForMatch(block)) {
        scannedText = scannedText + 'Match found in block index: $blockIndex\n';
        for (TextLine line in block.lines) {
          scannedText = scannedText + line.text + "\n";
        }
        foundCollege = true;
        break;
      } else {
        continue;
      }
    }
    if (!foundCollege && !isBulk) {
      setState(() {
        imageFile = image;
        textScanning = false;
        scannedText = "No college found";
      });
      return scannedText;
    }

    if (!isBulk)
      setState(() {
        imageFile = image;
        textScanning = false;
      });
    return scannedText;
  }

  bool checkForMatch(TextBlock block) {
    final matchList = ['university', 'college', 'school', 'institute'];
    return matchList.any((match) => block.text.toLowerCase().contains(match));
  }

  @override
  void initState() {
    super.initState();
  }
}
