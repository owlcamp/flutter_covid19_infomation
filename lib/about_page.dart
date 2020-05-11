import 'package:about/about.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutS extends StatelessWidget {
    AboutS({Key key,}) : super(key: key);

    Future<void> _launchInBrowser(String url) async {
    if (await canLaunch(url)) {
      await launch(
        url,
        forceSafariVC: false,
        forceWebView: false,
        headers: <String, String>{'my_header_key': 'my_header_value'},
      );
    } else {
      throw 'Could not launch $url';
    }
  }
  @override
  Widget build(BuildContext context) {
    //final isIos = Theme.of(context).platform == TargetPlatform.iOS;

     Widget aboutPage = AboutPage(
      title: Text('About'),
      applicationVersion: 'Version {{ version }}, build #4185563d',
      applicationDescription: Text(
        "このアプリについて\n■利用規約\nご自由にお使い頂けます。\nただし、このアプリによって生じたいかなる責任も開発者は負わないものとします。\n■謝辞\nデータソースは東洋経済オンライン社の「新型コロナウイルス国内感染の状況」を利用させて頂きました。\n日々のデータ更新について感謝致します。\n■ライセンス\n	MITライセンスとします。研究、調査、報道など、商用・非商用を問わずご自由にお使いください。\n著作権表示は「株式会社アウルキャンプ」または「OwlCamp INC.」としてください。\nこのプロジェクトによって生じたいかなる責任も開発者は負わないものとします。",
        textAlign: TextAlign.justify,
      ),
      applicationIcon: GestureDetector(onTap: (){
      _launchInBrowser("https://owlcamp.jp");
      },child:SizedBox(
        height: 150,
        child: Image(
          image: AssetImage('assets/c19.png'),
          width: 200,
        ),
      ),),
      applicationLegalese: '© OwlCamp INC.{{ year }}',
      children: <Widget>[],
    );
    return  aboutPage;
  }
}
