import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'main.dart';
import 'package:intl/intl.dart';

class CovidGraph extends StatefulWidget {
  CovidGraph(
      {Key key,
      this.title,
      this.graphcolor,
      this.positivepatients,
      this.totalPositiveCases})
      : super(key: key);
  final String title;
  final List<List<TimeSeriesPrice>> positivepatients;
  final int totalPositiveCases;
  final Color graphcolor;
  @override
  _CovidGraphState createState() => _CovidGraphState();
}

class _CovidGraphState extends State<CovidGraph> {
  List<String> casedatelist = [];
  List<Widget> children = [];
  String seriesrow1 = '';
  String seriesrow2 = '';
  String selecteddate = "";
  num valuerow1 = 0;
  num valuerow2 = 0;
  @override
  void initState() {
    super.initState();
    selecteddate = DateFormat('yyyy年MM月dd日')
        .format(widget.positivepatients.first.last.time);
    valuerow1 = widget.positivepatients.first.last.value;
    valuerow2 = widget.positivepatients.last.last.value;
  }

  DateTime _time;
  Map<String, num> _measures;
  @override
  Widget build(BuildContext context) {
    if (mounted) {
      var series = [
        new charts.Series<TimeSeriesPrice, DateTime>(
            id: widget.title,
            colorFn: (_, __) =>
                charts.ColorUtil.fromDartColor(widget.graphcolor),
            domainFn: (TimeSeriesPrice sales, _) => sales.time,
            measureFn: (TimeSeriesPrice sales, _) => sales.value,
            data: widget.positivepatients[0]),
        new charts.Series<TimeSeriesPrice, DateTime>(
            id: '移動平均',
            colorFn: (_, __) =>
                charts.ColorUtil.fromDartColor(Colors.teal[500]),
            domainFn: (TimeSeriesPrice sales, _) => sales.time,
            measureFn: (TimeSeriesPrice sales, _) => sales.value,
            data: widget.positivepatients[1])
          ..setAttribute(charts.rendererIdKey, 'average'),
      ];
      _onSelectionChanged(charts.SelectionModel model) {
        final selectedDatum = model.selectedDatum;

        DateTime time;
        final measures = <String, num>{};
        if (selectedDatum.isNotEmpty) {
          time = selectedDatum.first.datum.time;
          selectedDatum.forEach((charts.SeriesDatum datumPair) {
            measures[datumPair.series.displayName] = datumPair.datum.value;
          });
        }

        // Request a build.
        setState(() {
          _time = time;
          _measures = measures;
        });
      }

      //チャートのウィジェット
      children = <Widget>[
        new SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          //height: 200,
          child: new charts.TimeSeriesChart(series,
              animate: false,
              defaultRenderer: new charts.BarRendererConfig<DateTime>(),
              defaultInteractions: false,
              selectionModels: [
                new charts.SelectionModelConfig(
                  type: charts.SelectionModelType.info,
                  changedListener: _onSelectionChanged,
                )
              ],
              behaviors: [
                new charts.PanAndZoomBehavior(),
                new charts.SelectNearest(),
                new charts.DomainHighlighter()
              ],
              customSeriesRenderers: [
                new charts.LineRendererConfig(
                    // ID used to link series to this renderer.
                    customRendererId: 'average',
                    includeArea: true,
                    stacked: true)
              ]),
        ),
        new Text(selecteddate,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text('${widget.title}: $valuerow1 名', style: TextStyle(fontSize: 18)),
        Text('移動平均: ${valuerow2.toInt()} 名', style: TextStyle(fontSize: 18))
      ];
    }
    if (_time != null) {
      setState(() {
        selecteddate = DateFormat('yyyy年MM月dd日').format(_time);
      });
    }
    _measures?.forEach((String series, num value) {
      if (series == widget.title) {
        setState(() {
          valuerow1 = value;
        });
      } else {
        setState(() {
          valuerow2 = value;
        });
      }
    });

    var center = Center(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[] + children),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: center,
    );
  }
}
