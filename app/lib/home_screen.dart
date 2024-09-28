import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import './constants.dart';
import './screen_size.dart';
import './discovery_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  String _bluetoothName = '';
  String _bluetoothAddress = '';

  @override
  void initState() {
    super.initState();

    _bluetooth.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    _bluetooth.name.then((name) {
      setState(() {
        _bluetoothName = name;
      });
    });

    Future.doWhile(() async {
      if (await _bluetooth.isEnabled) {
        return false;
      }
      await Future.delayed(Duration(milliseconds: 500));
      return true;
    }).then((_) {
      _bluetooth.address.then((address) {
        setState(() {
          _bluetoothAddress = address;
        });
      });
    });

    _bluetooth.onStateChanged().listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;
      });
    });
  }

  @override
  void dispose() {
    _bluetooth.setPairingRequestHandler(null);
    super.dispose();
  }

  void _toggleBluetooth() async {
    if (_bluetoothState.isEnabled) {
      await _bluetooth.requestDisable();
    } else {
      await _bluetooth.requestEnable();
    }
    setState(() {});
  }

  void _openSettings() {
    _bluetooth.openSettings();
  }

  @override
  Widget build(BuildContext context) {
    ScreenSize().init(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('پیتا'),
        actions: [
          (_bluetoothState.isEnabled)
              ? IconButton(
                  icon: Icon(Icons.bluetooth),
                  onPressed: _toggleBluetooth,
                )
              : Container(),
        ],
      ),
      body: (_bluetoothState.isEnabled)
          ? Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: EdgeInsets.all(adaptiveScreenHeight(20.0)),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'نام دستگاه',
                              style: TextStyle(
                                fontSize: adaptiveScreenHeight(24.0),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _bluetoothName,
                              style: TextStyle(
                                fontSize: adaptiveScreenHeight(20.0),
                                fontWeight: FontWeight.w400,
                                color: Constants.disabledColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: adaptiveScreenHeight(10.0),
                      ),
                      Container(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'آدرس دستگاه',
                              style: TextStyle(
                                fontSize: adaptiveScreenHeight(24.0),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _bluetoothAddress,
                              style: TextStyle(
                                fontSize: adaptiveScreenHeight(20.0),
                                fontWeight: FontWeight.w500,
                                color: Constants.disabledColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: adaptiveScreenHeight(10.0),
                      ),
                      ElevatedButton(
                        onPressed: _openSettings,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: adaptiveScreenWidth(15.0),
                            vertical: adaptiveScreenHeight(10.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.settings),
                              SizedBox(
                                width: adaptiveScreenWidth(10.0),
                              ),
                              Text('تنظیمات'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: adaptiveScreenWidth(10.0),
                    vertical: adaptiveScreenHeight(7.0),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) {
                            return DiscoveryScreen();
                          },
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: adaptiveScreenHeight(10.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search),
                          SizedBox(
                            width: adaptiveScreenWidth(10.0),
                          ),
                          Text('جستجو دستگاه ها'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: (_bluetoothState == BluetoothState.STATE_OFF ||
                      _bluetoothState == BluetoothState.STATE_ON)
                  ? IconButton(
                      onPressed: _toggleBluetooth,
                      icon: (_bluetoothState.isEnabled)
                          ? Icon(
                              Icons.bluetooth,
                              color: Theme.of(context).primaryColor,
                            )
                          : Icon(
                              Icons.bluetooth_disabled,
                              color: Constants.disabledColor,
                            ),
                      iconSize: adaptiveScreenHeight(72.0),
                    )
                  : CircularProgressIndicator(),
            ),
    );
  }
}
