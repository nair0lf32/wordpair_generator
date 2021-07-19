import 'dart:ui';

import 'package:flutter/material.dart';
//my imports below:
import 'package:english_words/english_words.dart'; // Importing the package



void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WordPair Generator',

      theme: ThemeData(                 //changing the App's theme
        primaryColor: Colors.black,
      ),

      home: RandomWords(),         // Removed Scafold to use randomwords instead
    );
  }
}


//My new stateful widget
class RandomWords extends StatefulWidget {
  const RandomWords({Key? key}) : super(key: key);
  @override
  _RandomWordsState createState() => _RandomWordsState();

}


class _RandomWordsState extends State<RandomWords> {
  final _suggestions = <WordPair>[];
  final  _saved = <WordPair>{};
  final _biggerFont = const TextStyle(
      fontSize: 23.0,
      fontWeight: FontWeight.bold);

  Widget _buildSuggestions(){   //The function that builds the ListView
    return ListView.builder(
        padding: const EdgeInsets.all(16.0) ,
        itemBuilder:/*1*/ (context,i){
          if (i.isOdd) return const Divider(); /*2*/

          final index = i ~/ 2; /*3*/

          if (index >= _suggestions.length){
            _suggestions.addAll(generateWordPairs().take(10)); /*4*/
          }
          return _buildRow(_suggestions[index]);
        });
  }
  //explanations here:
  /*
     * 1: itembuilder is called once by wordpair and places each in a ListTile
     * if its an odd (not even row it adds a divider instead
     *
     * 2: adds a 1 pixel high Divider before eac row in the ListView
     * 3: divides i by 2 but return an INTEGER from the quotient
     * 4:If the end of ListView is reached 10 more are generated and added to
     * the suggestions List.
     *
     * _buildrow is called for every wordPair
     * */



  Widget _buildRow(WordPair pair){        //The buildRow function
    final alreadySaved = _saved.contains(pair);

    return ListTile(
      title: Text(
        pair.asPascalCase,
        style: _biggerFont,
      ),
      trailing: Icon(
        alreadySaved ? Icons.star: Icons.star_border,
        color: alreadySaved ? Colors.yellow: null
      ),
      onTap: (){
        setState(() {
          if(alreadySaved){
            _saved.remove(pair);
          }else{
            _saved.add(pair);
          }
        });


      },

    );

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(   //Added the scafold here to add buildSuggestions to body
      appBar: AppBar(
        title: const Text('WordPair Generator'),
        actions: [
          IconButton(icon: Icon(Icons.list_rounded),onPressed: _pushSaved)
        ],
      ),
      body: _buildSuggestions(),
    );

  }


  void _pushSaved(){              //function that create the new page
    Navigator.of(context).push(
      MaterialPageRoute<void>(
          builder: (BuildContext context){       //new page builder function
            final tiles = _saved.map(
                    (WordPair pair){
                      return ListTile(
                        title: Text(
                          pair.asPascalCase,
                          style: _biggerFont,
                        ),
                      );
                    },
                  );
            final divided = tiles.isNotEmpty
            ?ListTile.divideTiles(context: context,tiles: tiles).toList()
                :<Widget>[];
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




}
