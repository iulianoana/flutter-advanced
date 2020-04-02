import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'auth.dart' as fbAuth;
import 'storage.dart' as fbStorage;
import 'database.dart' as fbDatabase;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:path/path.dart'; //needed for basename

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final FirebaseApp app = await FirebaseApp.configure(
      name: 'firebaseapp',
      options: new FirebaseOptions( // Taken from google-services.json file
          googleAppID: '1:91956350870:android:3fdefccd00b63954e757b7', // mobilesdk_app_id
          gcmSenderID: '91956350870', // project_number
          apiKey: 'AIzaSyDsmp6LnFU32P-y2NrhbXw5DQJyNqss2Eg', // current_key
          projectID: 'fir-app-eb02c', // project_id
          databaseURL: 'https://fir-app-eb02c.firebaseio.com/', // firebase_url
      )
  );


  final FirebaseStorage storage = new FirebaseStorage(
    app: app,
    storageBucket: 'gs://fir-app-eb02c.appspot.com' // Firebase > Storage
  );

  final FirebaseDatabase database = new FirebaseDatabase(app: app);

  runApp(new MaterialApp(
    home: new MyApp(app: app, database: database, storage: storage,),
  ),);
}

class MyApp extends StatefulWidget {
  MyApp({this.app, this.database, this.storage});
  final FirebaseStorage storage;
  final FirebaseApp app;
  final FirebaseDatabase database;

  @override
  _State createState() => new _State(app: app, database: database, storage: storage);
}

class _State extends State<MyApp> {
  _State({this.app, this.database, this.storage});
  final FirebaseStorage storage;
  final FirebaseApp app;
  final FirebaseDatabase database;

  String _status;
  String _location;
  StreamSubscription<Event> _counterSubscription;

  String _username;

  @override
  void initState() {
    super.initState();
    fbDatabase.init(database);
    _status = 'Not Authenticated';
    _signIn();
  }

  void _signOut() async {
    if(await fbAuth.signOut()) {
      setState(() {
        _status = 'Signed out';
      });
    }else{
      setState(() {
        _status = 'Signed in';
      });
    }
  }

  void _signIn() async {
    if(await fbAuth.signInGoogle()) {
      _username = await fbAuth.getUserId();
      setState(() {
        _status = 'Signed in';
      });
      _initDatabase(database);
    }else{
      setState(() {
        _status = 'Could not sign in';
      });
    }
  }

  void _addData() async {
    fbDatabase.addData(_username);
    setState(() {
      _status = 'Data added';
    });
  }

  void _removeData() async {
    fbDatabase.removeData(_username);
    setState(() {
      _status = 'Data removed';
    });
  }

  void _setData(String key, String value) async {
    fbDatabase.setData(_username, key, value);
    setState(() {
      _status = 'Data set';
    });
  }

  void _updateData(String key, String value) async {
    fbDatabase.updateData(_username, key, value);
    setState(() {
      _status = 'Data updated';
    });
  }

  void _initDatabase(FirebaseDatabase database) async {
    await fbDatabase.init(database);

    _counterSubscription = fbDatabase.counterRef.onValue.listen((event) {
      setState(() {
        fbDatabase.error = null;
        fbDatabase.counter = event.snapshot.value ?? 0;
      });
    }, onError: (Object o) {
      final DatabaseError error = o;
      setState(() {
        fbDatabase.error = error;
      });
      print('Error initiating the Database: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Firebase'),
      ),
      body: new Container(
        padding: new EdgeInsets.all(32.0),
        child: new Center(
          child: new Column(
            children: <Widget>[
              new Text(_status),
              new Visibility(
                child: new Text('${fbDatabase.error}'),
                visible: fbDatabase.error != null,),
              new RaisedButton(
                onPressed: _signOut,
                child: new Text('Sign out'),
              ),
              new Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  new RaisedButton(
                    onPressed: _signIn,
                    child: new Text('Sign in Google'),
                  ),
                ],
              ),
              new Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  new RaisedButton(
                    onPressed: _addData,
                    child: new Text('Add Data'),
                  ),
                  new RaisedButton(
                    onPressed: _removeData,
                    child: new Text('Remove Data'),
                  ),
                ],
              ),
              new Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  new RaisedButton(
                    onPressed: () => _setData('Key2', 'This is a set value'),
                    child: new Text('Set Data'),
                  ),
                  new RaisedButton(
                    onPressed: () => _updateData('Key2', 'Key2 has been updated'),
                    child: new Text('Update Data'),
                  ),
                ],
              ),
            ]
          ),
        ),
      ),
    );
  }
}