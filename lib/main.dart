import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'dart:convert';
import 'package:aws_ai/src/RekognitionHandler.dart';

const String GOOGLE_VISION = 'GOOGLE_VISION';
const String AWS_REKOGNITION = 'AWS_REKOGNITION';

void main() =>
    runApp(new MaterialApp(title: "Camera App", home: LandingScreen()));

class LandingScreen extends StatefulWidget {
  @override
  _LandingScreenState createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  File imageFile;
  List<ImageLabel> _currentLabelLabels = <ImageLabel>[];
  String _currentLabelAWS;
  String _selectedScanner = GOOGLE_VISION;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Suprimentos"),
        ),
        body: Container(
          child: Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildScanner(context),
              _decideImageView(),
              RaisedButton(
                onPressed: () {
                  _showChoiceDialog(context);
                },
                child: Text("Selected Image!"),
              ),
              _currentLabelLabels.length > 0
                  ? buildLabelList(_currentLabelLabels)
                  : Text(""),
              _currentLabelAWS != null
                  ? buildJSONAWS(_currentLabelAWS)
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

    if (_selectedScanner == GOOGLE_VISION) {
      readImage();
    } else {
      readImageAWS();
    }
  }

  _openCamera(BuildContext context) async {
    var picture = await ImagePicker.pickImage(source: ImageSource.camera);
    this.setState(() {
      imageFile = picture;
    });
    Navigator.of(context).pop();
    if (_selectedScanner == GOOGLE_VISION) {
      readImage();
    } else {
      readImageAWS();
    }
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
      // print(text);
    }
    setState(() {
      _currentLabelLabels = labelsImage;
    });
  }

  Future readImageAWS() async {
    String accessKey, secretKey, region;
    RekognitionHandler rekognition =
        new RekognitionHandler(accessKey, secretKey, region);
    String labelsArray = await rekognition.detectLabels(imageFile);

    //final labelsJson = json.decode(labelsArray);
    Map<String, dynamic> imageLabel = jsonDecode(labelsArray);
    setState(() {
      _currentLabelAWS = 'Name: ' +
          imageLabel['Labels'][0]['Name'] +
          '\n' +
          'Name: ' +
          imageLabel['Labels'][1]['Name'] +
          '\n' +
          'Name: ' +
          imageLabel['Labels'][2]['Name'] +
          '\n' +
          'Name: ' +
          imageLabel['Labels'][3]['Name'];
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

  Widget _buildScanner(BuildContext context) {
    return Wrap(
      children: <Widget>[
        RadioListTile<String>(
          title: Text('Google Vision'),
          groupValue: _selectedScanner,
          value: GOOGLE_VISION,
          onChanged: onScannerSelected,
        ),
        RadioListTile<String>(
          title: Text('AWS Rekognition'),
          groupValue: _selectedScanner,
          value: AWS_REKOGNITION,
          onChanged: onScannerSelected,
        ),
      ],
    );
  }

  void onScannerSelected(String scanner) {
    setState(() {
      _selectedScanner = scanner;
      _currentLabelLabels = <ImageLabel>[];
      _currentLabelAWS = null;
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

  Widget buildJSONAWS(String text) {
    return Expanded(
      flex: 1,
      child: Container(
        child: Text(text),
      ),
    );
  }
}
