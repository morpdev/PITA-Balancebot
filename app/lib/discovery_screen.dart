import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import './home_screen.dart';
import './screen_size.dart';
import './constants.dart';
import './communicate_screen.dart';

class DiscoveryScreen extends StatefulWidget {
  @override
  _DiscoveryScreenState createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;

  StreamSubscription<BluetoothDiscoveryResult> _discoveryStream;
  List<BluetoothDiscoveryResult> _results = [];

  bool _isDiscovering = false;
  bool _isConnecting = false;
  bool _isUnpairing = false;

  @override
  void initState() {
    super.initState();

    _bluetooth.state.then((state) {
      if (state == BluetoothState.STATE_ON) {
        _startDiscovery();
      } else {
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(
          builder: (context) {
            return HomeScreen();
          },
        ), (route) => false);
      }
    });

    _bluetooth.onStateChanged().listen((BluetoothState state) {
      if (state != BluetoothState.STATE_ON) {
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
    _discoveryStream?.cancel();
    super.dispose();
  }

  void _startDiscovery() {
    setState(() {
      _isDiscovering = true;
      _results.clear();
    });

    _discoveryStream = _bluetooth.startDiscovery().listen((r) {
      setState(() {
        _results.add(r);
      });
    });

    _discoveryStream.onDone(() {
      setState(() {
        _isDiscovering = false;
      });
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _isConnecting = true;
    });

    if (device.isBonded) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) {
            _isConnecting = false;
            return CommunicateScreen(device: device);
          },
        ),
      );
    } else {
      final pairResult = await _bluetooth.bondDeviceAtAddress(device.address);

      if (pairResult) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              _isConnecting = false;
              return CommunicateScreen(device: device);
            },
          ),
        );
      } else {
        setState(() {
          _isConnecting = false;
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
                    Text('اتصال به دستگاه انتخاب شده، انجام نشد.'),
                    Text('دستگاه مورد نظر جفت نشد !'),
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
      }
    }
  }

  Future<void> _unpairDevice(BluetoothDiscoveryResult result) async {
    if (result.device.isBonded) {
      setState(() {
        _isUnpairing = true;
      });

      final unpairResult =
          await _bluetooth.removeDeviceBondWithAddress(result.device.address);

      setState(() {
        _isUnpairing = false;
        _results[_results.indexOf(result)] = BluetoothDiscoveryResult(
            device: BluetoothDevice(
              name: result.device.name ?? '',
              address: result.device.address,
              type: result.device.type,
              bondState: BluetoothBondState.none,
            ),
            rssi: result.rssi);
      });

      if (!unpairResult) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('خطا'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text('غیر مرتبط سازی با شکست مواجه شد.'),
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('دستگاه های در دسترس'),
        actions: [
          (!_isDiscovering && !_isConnecting && !_isUnpairing)
              ? IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: _startDiscovery,
                )
              : Container(),
        ],
      ),
      body: (_isDiscovering)
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(
                    height: adaptiveScreenHeight(10.0),
                  ),
                  Text(
                    'در حال جستجو...',
                    style: TextStyle(
                      fontSize: adaptiveScreenHeight(16.0),
                      fontWeight: FontWeight.bold,
                      color: Constants.disabledColor,
                    ),
                  ),
                ],
              ),
            )
          : (_results.length == 0)
              ? Center(
                  child: Text('هیچ دستگاهی یافت نشد !'),
                )
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (BuildContext context, index) {
                    return Card(
                      child: Padding(
                        padding: EdgeInsets.all(adaptiveScreenHeight(10.0)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _results[index].device.name,
                                  style: TextStyle(
                                    fontSize: adaptiveScreenHeight(20.0),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _results[index].device.address,
                                  style: TextStyle(
                                    fontSize: adaptiveScreenHeight(16.0),
                                    fontWeight: FontWeight.w500,
                                    color: Constants.disabledColor,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                (_isConnecting || _isUnpairing)
                                    ? CircularProgressIndicator()
                                    : InkWell(
                                        onTap: (_isConnecting || _isUnpairing)
                                            ? null
                                            : () async {
                                                await _connectToDevice(
                                                    _results[index].device);
                                              },
                                        onLongPress:
                                            (_isConnecting || _isUnpairing)
                                                ? null
                                                : () async {
                                                    await _unpairDevice(
                                                        _results[index]);
                                                  },
                                        child: Padding(
                                          padding: EdgeInsets.fromLTRB(
                                            adaptiveScreenHeight(10.0),
                                            adaptiveScreenHeight(10.0),
                                            adaptiveScreenHeight(10.0),
                                            0,
                                          ),
                                          child: Icon(
                                            Icons.link,
                                            size: adaptiveScreenHeight(36.0),
                                            color: (_results[index]
                                                    .device
                                                    .isBonded)
                                                ? Constants.greenColor
                                                : Theme.of(context)
                                                    .iconTheme
                                                    .color,
                                          ),
                                        ),
                                      ),
                                SizedBox(
                                  height: adaptiveScreenHeight(10.0),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('dBm'),
                                    SizedBox(
                                      width: adaptiveScreenWidth(3.0),
                                    ),
                                    Text('${-1 * _results[index].rssi}-'),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
