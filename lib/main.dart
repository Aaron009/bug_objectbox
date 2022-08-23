import 'package:flutter/material.dart';
import 'dart:io';

import 'objectbox.g.dart';
import 'package:objectbox/objectbox.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  void initState() {
    initDataBase();
    super.initState();
  }

  void initDataBase() async {
    await dataBase.initDataBase();
    languageData = await dataBase.getLanguageData();
    setState(() {
    });

    if(languageData == null) {
      LanguageData d = LanguageData(localeString: 'SaveData');
      d.saveBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
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
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'language data: $languageData',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class _DataBox<T> {
  late Box<T> box;
  late Type _type;

  _DataBox({required this.box}) {
    _type = T;
  }

  Box<T>? getBox<T>() {
    if (_type == T) {
      return box as Box<T>;
    }
    return null;
  }
}

class DataBase {
  late final Store databaseStore;
  List<_DataBox> _boxList = [];

  Future initDataBase() async {
    Directory appDocDir = await getTemporaryDirectory();
    String appDocPath = p.join(appDocDir.path, 'flutter_database');
    // if(GetPlatform.isAndroid) {
    //   var d = Directory(appDocPath);
    //   if(d.existsSync()) {
    //     d.deleteSync(recursive: true);
    //   }
    // }
    databaseStore = await openStore(directory: appDocPath);
    // if (Sync.isAvailable()) {
    //
    //   //final ipSyncServer = '123.456.789.012';
    //   final ipSyncServer = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    //   final syncClient = Sync.client(
    //     databaseStore,
    //     'ws://$ipSyncServer:9999',
    //     SyncCredentials.none(),
    //   );
    //   syncClient.connectionEvents.listen(print);
    //   syncClient.start();
    // }
  }

  Box<T> getBox<T>() {
    for (var dataBox in _boxList) {
      var box = dataBox.getBox<T>();
      if (box != null) return box;
    }
    var box = Box<T>(databaseStore);
    _boxList.add(_DataBox<T>(box: box));
    return box;
  }

  Future<LanguageData?> getLanguageData() async {
    final box = getBox<LanguageData>();
    final query = box.query().build();
    final value = query.find();
    print("getLanguageData() $value");
    if (value.isNotEmpty) return value[0];
    return null;


    Stream<List<LanguageData>> stream = getBox<LanguageData>()
        .query()
        .watch(triggerImmediately: true)
        .map((query) => query.find());
    await for (List<LanguageData> value in stream) {
      print("Database LanguageData length: ${value.length}");
      if (value.isNotEmpty) return value[0];
      break;
    }
    return null;
  }
}

DataBase dataBase = DataBase();
LanguageData? languageData;

abstract class DataBox<T> {
  late Box<T> _dataBox;

  DataBox() {
    _dataBox = dataBase.getBox<T>();
  }

  void saveBox() {
    _dataBox.put(this as T);
  }

  void remove() {
    _dataBox.remove(databaseId);
  }

  void delete() => remove();

  int get databaseId;
}

@Entity()
class LanguageData extends DataBox<LanguageData> {

  late int id = 0;

  late String localeString;

  LanguageData({
    this.id = 0,
    this.localeString = '',
  });

  @override
  int get databaseId => id;

  String toString() {
    return 'Language localeString!';
  }
}
