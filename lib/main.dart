//データソース：東洋経済オンライン（github:kaz-ogiwara/covid19）から引用。
//jp.owlcamp.covid19
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'graph.dart';
import 'prefectures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'misc.dart';
import 'package:data_connection_checker/data_connection_checker.dart';
import "package:flutter/services.dart";
import 'about_page.dart';

void main() {
  runApp(MyApp());
}

class TimeSeriesPrice {
  final DateTime time;
  final double value;

  TimeSeriesPrice(this.time, this.value);
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MaterialApp(
      home: MyHomePage(title: 'コロナ感染症情報', province: '東京'),
      routes: <String, WidgetBuilder>{
        '/screen1': (BuildContext context) => new MyHomePage(),
        '/region': (BuildContext context) => new Region(),
        '/province': (BuildContext context) => new Province(),
        '/about': (BuildContext context) => new AboutS(),
      },
      title: '新型コロナウイルス\n国内感染情報',
      theme: ThemeData(
        primarySwatch: Colors.amber,
       
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title, this.province}) : super(key: key);

  final String title;
  final String province;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<TimeSeriesPrice> positivepatients = [];
  List<TimeSeriesPrice> _positivepatients = [];
  List<TimeSeriesPrice> recoveredpatients = [];
  List<TimeSeriesPrice> _recoveredpatients = [];
  List<TimeSeriesPrice> testedpatients = [];
  List<TimeSeriesPrice> _testedpatients = [];
  List<TimeSeriesPrice> positivepatientsnl = [];
  List<TimeSeriesPrice> recoveredpatientsnl = [];
  List<TimeSeriesPrice> testedpatientsnl = [];
  List<TimeSeriesPrice> positivepatientsav = [];
  List<TimeSeriesPrice> _positivepatientsav = [];
  List<TimeSeriesPrice> recoveredpatientsav = [];
  List<TimeSeriesPrice> _recoveredpatientsav = [];
  List<TimeSeriesPrice> testedpatientsav = [];
  List<TimeSeriesPrice> _testedpatientsav = [];

  List<String> casedatelist = [];
  List<Widget> frontpage = [];
  List<Widget> _frontpage = [];
  List prefecturelist;

  Map provinceanddata = new Map();
  bool filedl = false;
  String apptitle = 'Covid-19感染情報';
  String rawprefecture = "";
  String totalPositiveCasesString = '';

  String lastpositive = '';
  String lasttested = '';
  String lasthospitalized = '';
  String lastrecovered = '';
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  Future<String> activeprefecture;

  //感染者数、退院者数、患者数
  double titleFS = 30.0;
  double subtitleFS = 22.0;
  double plusSubtitleFS = 22.0;
  double miscFS = 17.0;

  List<Map> menucontent = [
    {
      'Title': '感染者数',
      "TitleFS": 34.0,
      'Subtitle': "",
      "SubtitleFS": 22.0,
      'PlusSubtitle': "",
      "PlusSubtitleFS": 22.0,
      "MiscFS": 18.0,
      'BGC': Color(0xffd8421e),
      "Graph": 0
    },
    {
      'Title': '退院者数',
      "TitleFS": 34.0,
      'Subtitle': "",
      "SubtitleFS": 28.0,
      'PlusSubtitle': "",
      "PlusSubtitleFS": 28.0,
      "MiscFS": 18.0,
      'BGC': Color(0xff76a62e),
      "Graph": 2
    },
    {
      'Title': 'PCR検査人数',
      "TitleFS": 34.0,
      'Subtitle': "",
      "SubtitleFS": 28.0,
      'PlusSubtitle': "",
      "PlusSubtitleFS": 28.0,
      "MiscFS": 18.0,
      'BGC': Color(0xff1f659b),
      "Graph": 3
    }
  ];

  @override
  void initState() {
    super.initState();
    activeprefecture = _prefs.then((SharedPreferences prefs) {
      setState(() {
        rawprefecture = (prefs.getString('prefecture') ?? "東京都");
        apptitle = (prefs.getString('prefecture') ?? "東京都") + '　Covid-19感染情報';
      });
    });

    for (var i = 0; i < menucontent.length; i++) {
      menucontent[i]['TitleFS'] = titleFS;
      menucontent[i]['SubtitleFS'] = subtitleFS;
      menucontent[i]['PlusSubtitleFS'] = plusSubtitleFS;
      menucontent[i]['MiscFS'] = miscFS;
    }
    connectionchecker();
  }

  void connectionchecker() async {
    bool checker = await DataConnectionChecker().hasConnection;
    if (checker == true) {
      print({"Connection ON"});
      initializeDownloader();
    } else {
      print({"Connection OFF"});
      _showDialog();
      buildMainWidget();
    }
  }

  void _showDialog() {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("データ通信エラー"),
          content: new Text("インターネットに接続できません"),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text(
                "Close",
                style: TextStyle(color: Colors.black),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String _tempPath = '';
    void findlocaldir() async {
    Directory tempDir = await getApplicationDocumentsDirectory();
    String tempPath = tempDir.path;
    setState(() {
      _tempPath = tempPath;
    });
  }

  chooseTheRightGraph(int graphno) {
    switch (graphno) {
      case 0:
        return [_positivepatients, _positivepatientsav];
        break;
      case 2:
        return [_recoveredpatients, _recoveredpatientsav];
        break;
      case 3:
        return [_testedpatients, _testedpatientsav];
        break;
      default:
    }
  }

  Future getjsonData(url) async {
    print('Calling uri: $url');
    // 4
    http.Response response = await http.get(url);
    // 5
    if (response.statusCode == 200) {
      // 6
      return response.body;
    } else {
      print(response.statusCode);
    }
  }

  void initializeDownloader() async {
    findlocaldir();
    await getjsonData(
            "https://raw.githubusercontent.com/kaz-ogiwara/covid19/master/data/data.json")
        .then((value) async {
      Map jsonmap = json.decode(value);
      prefecturelist = jsonmap['prefectures-map'];
      await _downloadFile(
              "https://raw.githubusercontent.com/kaz-ogiwara/covid19/master/data/prefectures-2.csv",
              "prefectures-2.csv")
          .then((value) async {
        print("DL ok ");
        await _downloadFile(
                "https://raw.githubusercontent.com/kaz-ogiwara/covid19/master/data/prefectures.csv",
                "prefectures.csv")
            .then((value) async {
          print("DL ok ");
          await _downloadFile(
                  "https://raw.githubusercontent.com/kaz-ogiwara/covid19/master/data/summary.csv",
                  "summary.csv")
              .then((value) async {
            print("File downloaded!");

            readfile();
          });
        });
      });
    });
  }

  //csvをダウンロードするファンクション

  Future<File> _downloadFile(String url, String filename) async {
    http.Client client = new http.Client();
    var req = await client.get(Uri.parse(url));
    var bytes = req.bodyBytes;
    String dir = (await getApplicationDocumentsDirectory()).path;
    File file = new File('$dir/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }

  void buildMainWidget() {
    frontpage = [];
    for (var i = 0; i < menucontent.length; i++) {
      Widget tempwidget = Expanded(
        flex: 2,
        child: GestureDetector(
          onTap: () async {
            Navigator.push(
              context,
              // Create the SelectionScreen in the next step.
              MaterialPageRoute(
                  builder: (context) => CovidGraph(
                        title: rawprefecture + ' ' + menucontent[i]['Title'],
                        positivepatients:
                            chooseTheRightGraph(menucontent[i]["Graph"]),
                        totalPositiveCases: 1,
                        graphcolor: menucontent[i]['BGC'],
                      )),
            );
          },
          child: Container(
            padding: const EdgeInsets.only(left: 20.0),
            decoration: BoxDecoration(color: menucontent[i]['BGC']),
            child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(menucontent[i]['Title'],
                              style: new TextStyle(
                                  fontSize: menucontent[i]['TitleFS'],
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70))
                        ],
                      ),
                      Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("累計",
                                style: new TextStyle(
                                    fontSize: menucontent[i]['MiscFS'],
                                    fontWeight: FontWeight.normal,
                                    color: Colors.white70)),
                            Text(menucontent[i]['Subtitle'] + '　名',
                                style: new TextStyle(
                                    fontSize: menucontent[i]['SubtitleFS'],
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70)),
                            Text("前日比 +",
                                style: new TextStyle(
                                    fontSize: menucontent[i]['MiscFS'],
                                    fontWeight: FontWeight.normal,
                                    color: Colors.white70)),
                            Text(menucontent[i]['PlusSubtitle'] + '　名',
                                style: new TextStyle(
                                    fontSize: menucontent[i]['PlusSubtitleFS'],
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70))
                          ])
                    ])),
          ),
        ),
      );
      frontpage.add(tempwidget);
    }

    setState(() {
      _frontpage = frontpage;
    });
  }

  //ファイフを読み込むとデータセットを準備するファンクション
  void readfile() async {
    positivepatients = [];
    _positivepatients = [];
    recoveredpatients = [];
    _recoveredpatients = [];
    testedpatients = [];
    _testedpatients = [];
    positivepatientsnl = [];
    recoveredpatientsnl = [];
    testedpatientsnl = [];
    casedatelist = [];
    frontpage = [];
    positivepatientsav = [];
    _positivepatientsav = [];
    recoveredpatientsav = [];
    _recoveredpatientsav = [];
    testedpatientsav = [];
    _testedpatientsav = [];
    var path = _tempPath + '/prefectures.csv';
    var csvtolist = await _loadCsvData(path);
    var path2 = _tempPath + '/prefectures-2.csv';
    var csvtolist2 = await _loadCsvData(path2);
    csvtolist.removeAt(0);
    csvtolist2.removeAt(0);
    int positivediff = 0;

    int recdiff = 0;
    int testdiff = 0;

    for (var i = 0; i < csvtolist.length; i++) {
      if (csvtolist[i][3] == rawprefecture) {
        positivepatients.add(new TimeSeriesPrice(
            DateTime(csvtolist[i][0], csvtolist[i][1], csvtolist[i][2]),
            double.parse(csvtolist[i][4].toString())));
        recoveredpatients.add(new TimeSeriesPrice(
            DateTime(csvtolist[i][0], csvtolist[i][1], csvtolist[i][2]),
            double.parse(csvtolist[i][6].toString())));
        lastpositive = csvtolist[i][4].toString();
        lastrecovered = csvtolist[i][6].toString();
      }
    }
    for (var i = 0; i < csvtolist2.length; i++) {
      if (csvtolist2[i][3] == rawprefecture) {
        if (csvtolist2[i][5] != "") {
          double valueToParse =
              double.parse(csvtolist2[i][5].toString()) ?? 0.0;
          testedpatients.add(new TimeSeriesPrice(
              DateTime(csvtolist2[i][0], csvtolist2[i][1], csvtolist2[i][2]),
              valueToParse));
          lasttested = csvtolist2[i][5].toString();
        }
      }
    }
    var posnl = nonlineargraph(positivepatients);
    positivepatientsnl = posnl[0];
    positivediff = posnl[1];
    var recnl = nonlineargraph(recoveredpatients);
    recoveredpatientsnl = recnl[0];
    recdiff = recnl[1];
    var tesnl = nonlineargraph(testedpatients);
    testedpatientsnl = tesnl[0];
    testdiff = tesnl[1];
    setState(() {
      _positivepatients = positivepatientsnl;
      _recoveredpatients = recoveredpatientsnl;
      _testedpatients = testedpatientsnl;
      _positivepatientsav = posnl[2];
      _recoveredpatientsav = recnl[2];
      _testedpatientsav = tesnl[2];
      menucontent[0]['Subtitle'] = lastpositive;
      menucontent[1]['Subtitle'] = lastrecovered;
      menucontent[2]['Subtitle'] = lasttested;
      menucontent[0]['PlusSubtitle'] = positivediff.toString();
      menucontent[1]['PlusSubtitle'] = recdiff.toString();
      menucontent[2]['PlusSubtitle'] = testdiff.toString();
    });

    for (var i = 0; i < prefecturelist.length; i++) {
      provinceanddata[prefecturelist[i]['ja']] = prefecturelist[i]['value'];
    }
    casedatelist = [];
    frontpage = [];

    buildMainWidget();
  }

  Future<List<List<dynamic>>> _loadCsvData(String path) async {
    final file = new File(path).openRead();
    return await file
        .transform(utf8.decoder)
        .transform(new CsvToListConverter())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              icon: Icon(Icons.info),
              onPressed: () {
                Navigator.push(
                  context,
                  // Create the SelectionScreen in the next step.
                  MaterialPageRoute(builder: (context) => AboutS()),
                );
              }),
          IconButton(
              icon: Icon(Icons.language),
              onPressed: () async {
                var result = await Navigator.push(
                  context,
                  // Create the SelectionScreen in the next step.
                  MaterialPageRoute(
                      builder: (context) => Region(
                            prefectures: prefecturelist,
                            provinceanddata: provinceanddata,
                          )),
                );
                if (result == null) {
                  result = rawprefecture;
                }
                SharedPreferences prefs = await _prefs;
                prefs.setString("prefecture", result);
                menucontent[0]['Subtitle'] = provinceanddata[result].toString();
                readfile();
                setState(() {
                  rawprefecture = result;
                  apptitle = result + " Covid-19感染情報";
                });
              })
        ],
        title: Text(apptitle, style: TextStyle(fontSize: 18),),
      ),
      body: Column(children: _frontpage),
    );
  }
}
