import 'package:flutter/material.dart';
import "dart:convert";
import 'dart:io';

Future<List> prefecturesMap(File jsonfile) async {
  Future<List> prefecturelist = jsonfile
      .readAsString()
      .then((fileContents) => json.decode(fileContents))
      .then((jsonData) {
    var jsonmap = jsonData["prefectures-map"];
    return jsonmap;
  });
  print('object $prefecturelist');
  return prefecturelist;
}

Map regionmap() {
  Map regions = {

    '北海道　東北': ["北海道","青森県", "岩手県", "宮城県", "秋田県", "山形県", "福島県"],
    '関東': ["茨城県", "栃木県", "群馬県", "埼玉県", "千葉県", "神奈川県", "東京都"],
    "中部": ["新潟県", "富山県", "石川県", "福井県", "山梨県", "長野県", "岐阜県", "静岡県", "愛知県"],
    "近畿": ["三重県", "滋賀県", "京都府", "大阪府", "兵庫県", "奈良県", "和歌山県"],
    "中国": ["鳥取県", "島根県", "岡山県", "広島県", "山口県"],
    "四国": ["徳島県", "香川県", "愛媛県", "高知県"],
    "九州": ["福岡県", "佐賀県", "長崎県", "熊本県", "大分県", "宮崎県", "鹿児島県", "沖縄県"]
  };
  return regions;
}

// Create a string composed with all provinces
String proviceText(String region) {
  Map regions = regionmap();
  List provinces = regions[region];
  String tempstring = '';
  for (var i = 0; i < provinces.length; i++) {
    tempstring = tempstring + provinces[i] + ' ';
  }
  return tempstring;
}

class Region extends StatefulWidget {
  Region({Key key, this.prefectures, this.provinceanddata}) : super(key: key);
  final List prefectures;
  final Map provinceanddata;
  @override
  _RegionState createState() => _RegionState();
}

class _RegionState extends State<Region> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('地方を選択して下さい',style: TextStyle(fontSize: 18))),
      body: regionListView(context, widget.provinceanddata),
    );
  }
}

// replace this function with the code in the examples
Widget regionListView(BuildContext contex, Map provinceanddata) {
  // backing data
  final region = ['北海道　東北', '関東', '中部', '近畿', '中国', '四国', '九州'];
  return ListView.builder(
    itemCount: region.length,
    itemBuilder: (context, index) {
      return   Column(
        children: <Widget>[
          ListTile(
        title: Text(region[index]),
     
        onTap: () async {
          var result = await Navigator.push(
            context,
            // Create the SelectionScreen in the next step.
            MaterialPageRoute(
                builder: (context) => Province(
                      region: region[index],
                      provinceanddata: provinceanddata,
                    )),
          );
          Navigator.pop(context, result);
        },),
        Divider(),
        ] 
      
      );
    },
  );
}

class Province extends StatefulWidget {
  Province({Key key, this.region, this.provinceanddata}) : super(key: key);
  final String region;
  final Map provinceanddata;

  @override
  _ProvinceState createState() => _ProvinceState();
}

class _ProvinceState extends State<Province> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("県名を選択して下さい", style: TextStyle(fontSize: 18))),
      body: provinceListView(context, widget.region, widget.provinceanddata),
    );
  }
}

// replace this function with the code in the examples
Widget provinceListView(
    BuildContext context, String region, Map provinceanddata) {
  // backing data
  Map regionm = regionmap();
  List provinces = regionm[region];

  return ListView.builder(
    itemCount: provinces.length,
    itemBuilder: (context, index) {
      return 
       Column(
        children: <Widget>[
      ListTile(
        title: Text(provinces[index]),
        subtitle: Text("感染者数 "+provinceanddata[provinces[index]].toString()),
        onTap: () {
          Navigator.pop(context, provinces[index]);
          
           },),
        Divider(),
        ] 
      );
    },
  );
}
