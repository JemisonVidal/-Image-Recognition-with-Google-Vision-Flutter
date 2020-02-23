import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

void main() =>
    runApp(new MaterialApp(title: "Camera App", home: LandingScreen()));

class LandingScreen extends StatefulWidget {
  @override
  _LandingScreenState createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  File imageFile;
  List<ImageLabel> _currentLabelLabels = <ImageLabel>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Main Screen"),
        ),
        body: Container(
          child: Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _decideImageView(),
              RaisedButton(
                onPressed: () {
                  _showChoiceDialog(context);
                },
                child: Text("Selected Image!"),
              ),
              _currentLabelLabels.length > 0
                  ? buildLabelList(_currentLabelLabels)
                  : Text("")
            ],
          )),
        ));
  }

  _openGallary(BuildContext context) async {
    var picture = await ImagePicker.pickImage(source: ImageSource.gallery);
    this.setState(() {
      imageFile = picture;
    });

    Navigator.of(context).pop();
    readImage();
  }

  _openCamera(BuildContext context) async {
    var picture = await ImagePicker.pickImage(source: ImageSource.camera);
    this.setState(() {
      imageFile = picture;
    });
    Navigator.of(context).pop();
    readImage();
  }

  Future readImage() async {
    final FirebaseVisionImage ourImage =
        FirebaseVisionImage.fromFile(imageFile);
    final ImageLabeler imageLabeler = FirebaseVision.instance.imageLabeler();
    final List<ImageLabel> labelsImage =
        await imageLabeler.processImage(ourImage);

    for (ImageLabel label in labelsImage) {
      final String text = label.text;
      final String entityId = label.entityId;
      final double confidence = label.confidence;
      print(text);
    }
    setState(() {
      _currentLabelLabels = labelsImage;
    });
  }

  Future<void> _showChoiceDialog(BuildContext context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Make a Choice!"),
            content: SingleChildScrollView(
                child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: Text("Gallary"),
                  onTap: () {
                    _openGallary(context);
                  },
                ),
                Padding(padding: EdgeInsets.all(10.0)),
                GestureDetector(
                  child: Text("Camera"),
                  onTap: () {
                    _openCamera(context);
                  },
                ),
              ],
            )),
          );
        });
  }

  Widget _decideImageView() {
    if (imageFile == null) {
      return Text("No image Selected!");
    } else {
      return Image.file(imageFile, width: 400, height: 400);
    }
  }

  Widget buildLabelList<T>(List<T> labelcodes) {
    if (labelcodes.length == 0) {
      return Expanded(
        flex: 1,
        child: Center(
          child: Text('Nothing detected',
              style: Theme.of(context).textTheme.subhead),
        ),
      );
    }
    return Expanded(
      flex: 1,
      child: Container(
        child: ListView.builder(
            padding: const EdgeInsets.all(1.0),
            itemCount: labelcodes.length,
            itemBuilder: (context, i) {
              var text;

              final labelcode = labelcodes[i];

              ImageLabel res = labelcode as ImageLabel;
              text = "Raw Value: ${res.text} - ${res.confidence}";

              return _buildTextRow(text);
            }),
      ),
    );
  }

  Widget _buildTextRow(text) {
    return ListTile(
      title: Text(
        "$text",
      ),
      dense: true,
    );
  }
}
