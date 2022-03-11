import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:starklicht_flutter/controller/starklicht_bluetooth_controller.dart';
import 'package:lottie/lottie.dart';

class _ConnectionsWidgetState extends State<ConnectionsWidget> {
  BluetoothController<BluetoothDevice> controller = BluetoothControllerWidget();
  List<BluetoothDevice> foundDevices = <BluetoothDevice>[];
  Set<BluetoothDevice> connectedDevices = {};
  bool mock = true;
  Map<BluetoothDevice, StarklichtBluetoothOptions> options = {};
  bool _isLoading = false;

  BluetoothState state = BluetoothState.unknown;

  StreamSubscription<dynamic>? stream;


  @override
  void initState() {
    super.initState();
    setState(() {
      _isLoading = true;
    });
    controller.connectedDevicesStream().then((value) {
      setState(() {
        _isLoading = false;
      });
      connectedDevices = value.toSet();
      stream?.cancel();
      stream = controller.getConnectionStream().listen((d) {
        setState(() {
          connectedDevices.add(d);
        });
      });
      setState(() {
        options = controller.getOptions();
      });
    });
    controller.stateStream().listen((event) {
      setState(() {
        state = event;
      });
    });
  }

  List<String> getPlaceholderTitleAndSubtitle() {
    if(state == BluetoothState.unauthorized || state == BluetoothState.unknown
    || state == BluetoothState.unavailable) {
      return ["Bluetooth ist nicht verfügbar", "Eventuell fehlen Berechtigungen für den\n Standortzugriff oder Bluetooth."];
    }
    if(state == BluetoothState.off) {
      return ["Bluetooth ist aus", "Du kannst Bluetooth in deinen \nGeräteeinstellungen anschalten."];
    }
    return ["Keine aktiven Verbindungen", "Bitte verbinde dich zunächst mit einem Starklicht."];
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child: ListView.builder(
          shrinkWrap: connectedDevices.isEmpty,
            itemCount: connectedDevices.isEmpty || _isLoading
                || state == BluetoothState.unknown ||
                state == BluetoothState.off ||
                state == BluetoothState.unauthorized ||
                state == BluetoothState.unavailable
                ?1:connectedDevices.length,
            itemBuilder: (BuildContext context, int index) {
              print(index);
              if (_isLoading) {
                return CircularProgressIndicator();
              }
              else if (connectedDevices.isEmpty) {
                return Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Lottie.asset(
                            'assets/rocket.json',
                          ),
                          // Image.asset('assets/searching-for-devices.png'),
                          Text(
                            "${getPlaceholderTitleAndSubtitle()[0]}\n",
                            style: TextStyle(
                                fontSize: 20
                            ),
                          ),
                          Text(
                            "${getPlaceholderTitleAndSubtitle()[1]}\n",
                            style: TextStyle(
                                color: Colors.grey
                            ),
                          ),
                          if(state == BluetoothState.on) ElevatedButton(
                            child: Text("Gerät suchen"),
                            onPressed: () {
                              showDialog(context: context, builder: (_) {
                                return const SearchWidget();
                              });
                            },
                          )
                        ]
                    )
                );
              } else {
                var d = connectedDevices.toList()[index];
                return Card(
                    margin: EdgeInsets.all(8.0),
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    child: InkWell(child: Column(
                        children: [
                          ListTile(
                              leading: Icon(Icons.lightbulb),
                              title: Text(d.name),
                              subtitle: Text(d.id.id),
                              trailing: Switch(
                                value: options[d]!.active,
                                onChanged: (value) {
                                  setState(() {
                                    options[d]!.active = value;
                                  });
                                  controller.setInverse(d, options[d]!.active);
                                },
                                activeTrackColor: Colors.blueGrey,
                                activeColor: Colors.white,
                              )
                          )
                        ]
                    ),
                      onTap: () => showDialog(context: context, builder: (_) {
                        return AlertDialog(
                          title: Text(d.name),
                          content: Column(
                            children: [
                              Text("Hallo Tobias. Ich hoffe dir geht es gut. Leider gibt es den Inverse Modus noch nicht. Danke.")
                            ],
                          ),
                        );
                      }),
                    ));
              }
            }
        )
      ),
        floatingActionButton: state == BluetoothState.on?FloatingActionButton(
        onPressed:  () => {
          showDialog(context: context, builder: (_) {
            return const SearchWidget();
          })
        },
        child: const Icon(Icons.add),
        // backgroundColor: Colors.white,
      ):null,
    );
  }

  @override
  void dispose() {
    stream?.cancel();
    super.dispose();
  }
}

class ConnectionsWidget extends StatefulWidget {
  const ConnectionsWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ConnectionsWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  BluetoothController controller = BluetoothControllerWidget();
  List<BluetoothDevice> foundDevices = <BluetoothDevice>[];
  bool _scanning = false;
  StreamSubscription? subscription;
  StreamSubscription? deviceSubscription;

  void scan() {
    foundDevices.clear();
    subscription?.cancel();
    deviceSubscription?.cancel();
    deviceSubscription = controller.scan(4).asBroadcastStream().listen((a) {
      setState(() {
        foundDevices.add(a);
      });
    });
    subscription = controller.scanning().asBroadcastStream().listen((event) {
      setState(() {
        _scanning = event;
      });
    });
  }


  @override
  void initState() {
    super.initState();
    scan();
  }

  @override
  void dispose() {
    subscription?.cancel();
    deviceSubscription?.cancel();
    super.dispose();
  }

  String getTitle() {
    return _scanning?"Suche":foundDevices.isEmpty?"Keine Geräte gefunden":"Mit Gerät verbinden";
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
        title: Text(getTitle()),
        children: <Widget>[
          ...foundDevices.map((e) => SimpleDialogOption(
            padding: const EdgeInsets.all(20),
            onPressed: () {
              controller.connect(e);
              Navigator.pop(context);
            },
            child: Text(e.name),
          )),
          if (_scanning) ...[
            SimpleDialogOption(
                child: Center(
                    child: Column(
                      children: const [CircularProgressIndicator()],
                    )
                )
            )
          ]
          else ...[
            Center(
                child: Column(
                  children: [ElevatedButton(onPressed: scan, child: Text("Erneut suchen"))
                  ],
                )
            )
          ]
        ]
    );
  }

}


class SearchWidget extends StatefulWidget {
  const SearchWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SearchWidgetState();
}
