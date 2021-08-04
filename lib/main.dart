import 'dart:ui';
import 'package:flutter/material.dart';
//my imports below:
import 'package:english_words/english_words.dart'; // Importing the package
import 'package:path_provider/path_provider.dart'; // for local storage
import 'dart:io'; //to write data to files
import 'package:permission_handler/permission_handler.dart'; //for permissions
import 'dart:convert'; // for json serialization

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WordPair Generator',

      theme: ThemeData(
        //changing the App's theme
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.amber,
      ),

      home: RandomWords(), // Removed Scafold to use randomwords instead
    );
  }
}

//Making Wordpair serializable by extending the class
List<WordPairExt> wordPairExtFromJson(String str) => List<WordPairExt>.from(json.decode(str).map((x) => WordPairExt.fromJson(x)));

String wordPairExtToJson(List<WordPairExt> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class WordPairExt extends WordPair {
  String first;
  String second;

  WordPairExt({
    this.first,
    this.second,
  }) : super(first, second);

  factory WordPairExt.fromJson(Map<String, dynamic> json) => WordPairExt(
        first: json["first"],
        second: json["second"],
      );

  Map<String, dynamic> toJson() => {
        "first": first,
        "second": second,
      };
}

//the main stateful widget
class RandomWords extends StatefulWidget {
  const RandomWords({Key key}) : super(key: key);
  @override
  _RandomWordsState createState() => _RandomWordsState();
}

//Adding a widgets binding Observer to control lifecycle
class _RandomWordsState extends State<RandomWords> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    Permission.storage.request(); //request storage permission
    WidgetsBinding.instance.addObserver(this);
    loadWords(); //Calling the reading function (may obviously fail..but hey!)
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    //life cycle
    super.didChangeAppLifecycleState(state);
    // callbacks
    switch (state) {
      case AppLifecycleState.resumed:
        // widget is resumed
        loadWords(); //Calling the reading function
        break;
      case AppLifecycleState.inactive:
        // widget is inactive
        saveWords(); //calling the saving function
        break;
      case AppLifecycleState.paused:
        // widget is paused
        saveWords(); //calling the saving function
        break;
      case AppLifecycleState.detached:
        // widget is detached
        saveWords(); //calling the saving function
        break;
    }
    print('AppLifecycleState: $state');
  }

  @override
  void dispose() {
    saveWords(); //calling the saving function
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  final _suggestions = <WordPairExt>[]; //Using extended Word pair class instead
  final _saved = Set<WordPairExt>();

  final _biggerFont = const TextStyle(fontSize: 23.0, fontWeight: FontWeight.bold);

  Widget _buildSuggestions() {
    //The function that builds the ListView
    return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemBuilder: /*1*/ (context, i) {
          if (i.isOdd) return const Divider(); /*2*/

          final index = i ~/ 2; /*3*/

          if (index >= _suggestions.length) {
            generateWordPairs().take(10).forEach((pair) {
              _suggestions.add(WordPairExt(first: pair.first, second: pair.second));
            }); /*4*/
            //_suggestions.addAll(generateWordPairs().take(10).cast());
          }
          return _buildRow(_suggestions[index]);
        });
  }
  //explanations here:
  /* * 1: item builder is called once by pair and places each in a ListTile
     * if its an odd (not even) row it adds a divider instead
     * 2: adds a 1 pixel high Divider before each row in the ListView
     * 3: divides i by 2 but return an INTEGER from the quotient
     * 4:If the end of ListView is reached 10 more are generated and added to
     * the suggestions List.
     *build row is called for every wordPair  */

//The buildRow function
  Widget _buildRow(WordPairExt pair) {
    //using extended Word pair instead
    final alreadySaved = _saved.contains(pair);
    return ListTile(
      title: Text(
        pair.asPascalCase,
        style: _biggerFont,
      ),
      trailing: Icon(alreadySaved ? Icons.star : Icons.star_border, color: alreadySaved ? Colors.yellow : null),
      onTap: () {
        setState(() {
          if (alreadySaved) {
            _saved.remove(pair);
          } else {
            _saved.add(pair);
          }
        });
        saveWords(); //calling the saving function
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //Added the scaffold here to add buildSuggestions to body
      appBar: AppBar(
        title: const Text('WordPair Generator'),
        actions: [
          IconButton(icon: Icon(Icons.list_rounded), onPressed: _pushSaved)
        ],
      ),
      body: _buildSuggestions(),
    );
  }

  //function that create the new page
  void _pushSaved() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        //new page builder function
        builder: (BuildContext context) {
          final tiles = _saved.map(
            (WordPair pair) {
              return ListTile(
                title: Text(
                  pair.asPascalCase,
                  style: _biggerFont,
                ),
              );
            },
          );
          final divided = tiles.isNotEmpty ? ListTile.divideTiles(context: context, tiles: tiles).toList() : <Widget>[];
          return Scaffold(
            appBar: AppBar(
              title: Text('favorites WordPairs'),
            ),
            body: ListView(children: divided),
          );
        },
      ),
    );
  }

  //Async function to get the local storage path
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

//Async function to get a file for local save
  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/wordpairs.txt');
  }

//Async function to save the words to the file
  Future<File> saveWords() async {
    final file = await _localFile;
    List<WordPairExt> savedList = _saved.toList();
    // Write the file
    String data = jsonEncode(savedList);
    file.writeAsString('$data', mode: FileMode.write);
    print('file saved'); //for debugging purposes lol
    return file;
  }

  //ASync function to read the saved words file and load them
  void loadWords() async {
    try {
      final file = await _localFile;
      String savedString = '';
      // Read the file and store the string
      await file.readAsString().then((content) => savedString = content);
      List<WordPairExt> savedWordPairsList = wordPairExtFromJson(savedString);
      print(savedWordPairsList);
      setState(() {
        _suggestions.addAll(savedWordPairsList);
        _saved.addAll(savedWordPairsList);
      });
      print('file read'); //haha..debugging go brrr
    } catch (e) {
      // If encountering an error
      print(e); //might wanna rethink the error handling

    }
  }
}
