import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

void main() => runApp(MaterialApp(
  debugShowCheckedModeBanner: false,
  home: MyApp(),
));

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {


  final CollectionReference _dref = Firestore.instance.collection('users');
  final DocumentReference _documentReference = Firestore.instance.document('users/parth');
  String _name,_age ;

  void _addToDb(String _name,int _age){
    Map<String,String> data = <String,String>{
      "name" : _name,
      "age" : _age.toString()
    };
    _dref.add(data).whenComplete((){
      print("Document Added");
    }).catchError((e)=> print(e.toString()));

  }

  void _fetchFromDb(){
    _documentReference.get().then((dataSnapshot){
      if(dataSnapshot.exists){
        print("The readed name data is " + dataSnapshot.data['name']);
        print("The readed age data is " + dataSnapshot.data['age']);
        Map<String,String> data = <String,String>{
          "name" : "Hello world",
          "age" : "Infinity"
        };
        _documentReference.updateData(data);

      }
    });
  }
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Firestore CRUD and Text Detector'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: Container(
        margin: EdgeInsets.only(left: 16.0,right: 16.0,top:30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(10.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11.0),
                  color: Colors.grey[200]

                ),
                child: TextFormField(
                  decoration: InputDecoration(
                    contentPadding:  EdgeInsets.all(10.0),
                    border: InputBorder.none,
                    hintText: 'Your name',
                    hintStyle: TextStyle(
                      fontSize: 20.0
                    )
                  ),
                  onChanged: (val){
                    setState(() {
                      _name = val ;
                    });
                  },
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 10.0,right: 10.0),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11.0),
                    color: Colors.grey[200]

                ),
                child: TextFormField(
                  keyboardType: TextInputType.numberWithOptions(),
                  decoration: InputDecoration(
                      contentPadding:  EdgeInsets.all(10.0),
                      border: InputBorder.none,
                      hintText: 'Your age',
                      hintStyle: TextStyle(
                          fontSize: 20.0
                      )
                  ),
                  onChanged: (val){
                    setState(() {
                      _age = val ;
                    });

                  },
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(top: 10.0,right: 10.0),
                  child: RaisedButton.icon( textColor: Colors.white,color: Colors.grey[900], icon: Icon(Icons.navigate_next), label: Text('submit'),
                  onPressed: (){
                    _addToDb(_name,int.parse(_age));
                    _fetchFromDb();


                  },
                  ),
                ),
              ],
            ),
            Container(
              height: 200.0,
              child: StreamBuilder(
                stream: Firestore.instance.collection('users').snapshots(),
                builder: (context,snapshot){
                  if(!snapshot.hasData) return Center(child: CircularProgressIndicator());
                  return ListView(
                    children: makeList(snapshot),
                  );
                },
              ),
            ),
            SizedBox(
              height: 10.0,
            ),
            RaisedButton(
              color: Colors.grey[900],
              elevation: 2.0,
              child: Text('Pick an image' , style: TextStyle(color: Colors.white),),
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder: (context){

                        return ImagePage();
                }));
              },
            )
          ],
        ),
      ),
    );
  }

  List <Widget> makeList(AsyncSnapshot snapshot) {
    return snapshot.data.documents.map<Widget>((docs){
      return Container(
        margin: EdgeInsets.only(top: 10.0),
        decoration: BoxDecoration(
          color: Colors.grey[100]
        ),
        child: ListTile(
          title: Text("User Name : " +docs["name"]),
          subtitle: Text("User Age : " + docs["age"]),
          onTap: (){},

        ),
      );


    }).toList();
  }


}

class ImagePage extends StatefulWidget {
  @override
  _ImagePageState createState() => _ImagePageState();
}

class _ImagePageState extends State<ImagePage> {
  File pickedImage ;
  bool isImagePicked = false ;
  List <String> words = [];
  String _textData ;

  @override
  void initState()  {
    super.initState();
    pickImageNow();
  }

  void pickImageNow()async{
    await pickImage();

  }

  Future pickImage()async {
    var tempStore = await ImagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      pickedImage = tempStore ;
      isImagePicked = true ;
      _textData = "";
      words.clear();
    });

    
  }
  Future readText() async {
    FirebaseVisionImage ourImage = FirebaseVisionImage.fromFile(pickedImage);
    TextRecognizer recognizeText = FirebaseVision.instance.textRecognizer();
    VisionText readText = await recognizeText.processImage(ourImage);
    for (TextBlock block in readText.blocks){
      for (TextLine line in block.lines){
        for (TextElement word in line.elements){
          words.add(word.text);
        }
      }
    }
    if(words.length > 0) {
      return words;
    }
    else return "Either no text or cannot detect" ;

  }
  
  @override
  Widget build(BuildContext context) {


    return Scaffold(
      appBar: AppBar(
        title: Text('Your picked image'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            isImagePicked ?
            Center(
              child: Container(
                margin: EdgeInsets.only(top: 18.0,left: 10.0,right: 10.0,bottom: 10.0),
                height: 400.0,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: FileImage(pickedImage),fit: BoxFit.contain
                  )
                ),
              ),
            ) : Center(child: Container(
              child: Text('No image selected yet !'),
            )),
            isImagePicked ?
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                RaisedButton(
                  onPressed: ()async{ await readText();},
                  child: Text('Read text ',style: TextStyle(color: Colors.white),),
                  color: Colors.black,
                ),
                RaisedButton(
                  onPressed: ()async{
                    setState(() {
                      _textData = "";
                      words.clear();
                    });
                    await pickImage();},
                  child: Text('Pick another image ',style: TextStyle(color: Colors.white),),
                  color: Colors.black,
                ),
              ],
            ):
                Container(),
            FutureBuilder(
              future: readText(),
              builder: (context,snapshot){
                _textData = snapshot.data.toString() ;
                if(!snapshot.hasData) return Center(child: CircularProgressIndicator(),);
                return Container(
                  margin: EdgeInsets.only(top: 10.0,left: 10.0,right: 10.0),
                  child: Text(
                    _textData,
                      style: TextStyle(
                        fontSize: 20.0
                      ),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}


