
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
class Messages extends StatelessWidget {
  final bool loading;
  final String text;
  final String name;
  final bool type;
  final Color color;

  Messages(
      {this.text,
      this.name,
      this.type,
      this.loading,
      this.color: const Color(0xff1171b9)});

  List<Widget> responseMessage(context) {
    return <Widget>[
      loading == true
          ? Container(
              width: 90,
              height: 50,
              child: SpinKitThreeBounce(
                color: Color(0xff666666),
                size: 40.0,
              ),
            )
          : new Expanded(
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Card(
                    color: Colors.white,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        text,
                        style: TextStyle(
                            fontFamily: 'TextFont',
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    ];
  }

  List<Widget> userMessage(context) {
    return <Widget>[
      new Expanded(
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Card(
              color: color,
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  text,
                  style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'TextFont',
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return new Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: new Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: this.type ? userMessage(context) : responseMessage(context),
      ),
    );
  }
}
