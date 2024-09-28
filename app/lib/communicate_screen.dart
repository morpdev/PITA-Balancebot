import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import './screen_size.dart';
import './constants.dart';
import './home_screen.dart';

class CommunicateScreen extends StatefulWidget {
  final BluetoothDevice device;

  CommunicateScreen({this.device});
  @override
  _CommunicateScreenState createState() => _CommunicateScreenState();
}

class _CommunicateScreenState extends State<CommunicateScreen> {
  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection _connection;

  bool _isConnecting = false;
  bool _isConnected = false;

  List<int> _receiveBuffer = [];
  String _receivedString = '';
  double _pitaAngle = 0.0;

  @override
  void initState() {
    super.initState();

    _bluetooth.state.then((state) {
      if (state != BluetoothState.STATE_ON) {
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(
          builder: (context) {
            return HomeScreen();
          },
        ), (route) => false);
      }
    });

    setState(() {
      _isConnecting = true;
    });

    BluetoothConnection.toAddress(widget.device.address).then((connection) {
      _connection = connection;
      _receiveBuffer.clear();
      _receivedString = '';

      setState(() {
        _isConnecting = false;
        _isConnected = true;
      });

      _connection.input.listen((Uint8List data) {
        data.forEach((element) {
          _receiveBuffer.add(element);
          if (_receiveBuffer.contains(83) && _receiveBuffer.contains(70)) {
            _receivedString = '';
            for (var i = _receiveBuffer.indexOf(83) + 1;
                i < _receiveBuffer.indexOf(70);
                i++) {
              _receivedString +=
                  String.fromCharCode(_receiveBuffer.elementAt(i));
            }
            setState(() {
              _pitaAngle = double.tryParse(_receivedString) ?? 0.0;
            });
            _receiveBuffer.clear();
            print(_pitaAngle);
          } else if (!_receiveBuffer.contains(83) &&
              _receiveBuffer.contains(70)) {
            _receiveBuffer.clear();
          }
        });
      }).onDone(() {
        setState(() {
          _isConnected = false;
        });

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('هشدار'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text('ارتباط با دستگاه مورد نظر قطع شد.'),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('تایید'),
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(
                      builder: (context) {
                        return HomeScreen();
                      },
                    ), (route) => false);
                  },
                ),
              ],
            );
          },
        );
      });
    }).catchError((e) {
      setState(() {
        _isConnecting = false;
        _isConnected = false;
      });
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('خطا'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(e.toString()),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('تایید'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    });

    _bluetooth.onStateChanged().listen((BluetoothState state) {
      if (state != BluetoothState.STATE_ON) {
        _connection.dispose();
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(
          builder: (context) {
            return HomeScreen();
          },
        ), (route) => false);
      }
    });
  }

  @override
  void dispose() {
    _connection.dispose();
    super.dispose();
  }

  void _sendCharacter(String direction) async {
    try {
      _connection.output.add(utf8.encode(direction));
      await _connection.output.allSent;
    } catch (e) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('خطا'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(e.toString()),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('تایید'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      setState(() {});
    }
  }

  double _visualAngleMultiplier(double angle) {
    angle = angle.abs();
    if (angle <= 2) {
      return angle * 5;
    } else if (angle > 2 && angle <= 5) {
      return angle * 2;
    } else {
      return angle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('کنترل پیتا'),
      ),
      body: (_isConnecting)
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(
                    height: adaptiveScreenHeight(10.0),
                  ),
                  Text(
                    'در حال اتصال...',
                    style: TextStyle(
                      fontSize: adaptiveScreenHeight(16.0),
                      fontWeight: FontWeight.bold,
                      color: Constants.disabledColor,
                    ),
                  ),
                ],
              ),
            )
          : (_isConnected)
              ? Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: adaptiveScreenHeight(10.0),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Text(
                            (_pitaAngle < 0)
                                ? (-1 * _pitaAngle).toString() + '\u00B0-'
                                : _pitaAngle.toString() + '\u00B0',
                            style: TextStyle(
                              fontSize: adaptiveScreenHeight(24.0),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Image.asset(
                            'assets/images/angle.png',
                            height: adaptiveScreenHeight(30.0),
                          ),
                          SizedBox(
                            height: adaptiveScreenHeight(20.0),
                          ),
                          RotationTransition(
                            alignment: Alignment.bottomCenter,
                            turns: AlwaysStoppedAnimation(
                                _visualAngleMultiplier(_pitaAngle) / 360.0),
                            child: Image.asset(
                              'assets/images/bot.png',
                              height: adaptiveScreenHeight(200.0),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(Icons.arrow_upward),
                                onPressed: () {
                                  _sendCharacter('1');
                                },
                                iconSize: adaptiveScreenHeight(72.0),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: Icon(Icons.arrow_back),
                                onPressed: () {
                                  _sendCharacter('3');
                                },
                                iconSize: adaptiveScreenHeight(72.0),
                              ),
                              IconButton(
                                icon: Icon(Icons.arrow_forward),
                                onPressed: () {
                                  _sendCharacter('4');
                                },
                                iconSize: adaptiveScreenHeight(72.0),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(Icons.arrow_downward),
                                onPressed: () {
                                  _sendCharacter('2');
                                },
                                iconSize: adaptiveScreenHeight(72.0),
                              ),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                )
              : Center(
                  child: Text(
                    'اتصال با شکست مواجه شد.',
                    style: TextStyle(
                      fontSize: adaptiveScreenHeight(16.0),
                      fontWeight: FontWeight.bold,
                      color: Constants.disabledColor,
                    ),
                  ),
                ),
    );
  }
}
