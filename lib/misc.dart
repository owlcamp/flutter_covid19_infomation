import 'main.dart';
import 'package:moving_average/moving_average.dart';

List nonlineargraph( List<TimeSeriesPrice> series, ){
  int diff = 0;
  List<TimeSeriesPrice> seriesnl = [];
  List<TimeSeriesPrice> seriesav = [];
  List<num> averagelist = [];
     
    for (var i = 1; i < series.length; i++) {
      double valuetoadd =
          series[i].value - series[i - 1].value;
      if (valuetoadd < 0 ){
        valuetoadd = 0;
      }
      averagelist.add(valuetoadd); 
      seriesnl.add(new TimeSeriesPrice(series[i].time,
          valuetoadd));
      if (i == series.length - 2) {
        diff = (series[i + 1].value - series[i].value)
            .toInt();
      }
    }
    List<num> movingAverage2 = movingAverage(averagelist,2 , includePartial: true);
    double ppavalue = 0;
     for (var i = 0; i < movingAverage2.length; i++) {
      if (ppavalue == 0){
        ppavalue = seriesnl[i].value;
           seriesav.add( new TimeSeriesPrice(seriesnl[i].time, ppavalue ));
      }else{ 
           seriesav.add( new TimeSeriesPrice(seriesnl[i].time, movingAverage2[i] ));
      }

    }
    return [seriesnl, diff, seriesav];

    
}

