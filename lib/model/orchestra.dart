import 'dart:async';
import 'package:collection/src/iterable_extensions.dart';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:starklicht_flutter/messages/imessage.dart';
import 'package:starklicht_flutter/model/lamp_groups_enum.dart';
import 'package:starklicht_flutter/view/time_picker.dart';

import '../controller/starklicht_bluetooth_controller.dart';
import '../messages/color_message.dart';
import '../view/orchestra_timeline_view.dart';

enum NodeType { NOT_DEFINED, TIME, REPEAT, MESSAGE, WAIT }

enum WaitType { NONE, TIME, USER_INPUT }

abstract class INode extends StatefulWidget {
  INode({Key? key}) : super(key: key);
  abstract NodeType type;
}

enum CardIndicator { COLOR, GRADIENT, PROGRESS }

abstract class EventNode extends INode {
  EventNode(
      {Key? key,
      update,
      onDelete,
      required this.waitForUserInput,
      required this.delay})
      : super(key: key);

  CardIndicator get cardIndicator;

  Future<void> execute();

  bool hasLamps();

  get lamps;
  String getTitle();

  bool displayAsProgressBar();

  double toPercentage();

  Color toColor();

  Gradient? toGradient();

  Duration? delayAfterwards();

  bool manualDelayAfterwards();

  Widget getSubtitle(BuildContext context, TextStyle textStyle);

  String getSubtitleText();

  String formatTime() {
    var minutes = delay.inMinutes.remainder(60);
    var seconds = delay.inSeconds.remainder(60);
    var millis = delay.inMilliseconds.remainder(1000);
    var str = "";
    if (waitForUserInput) {
      return "Auf Benutzereingabe warten";
    }
    if (minutes > 0) {
      str += "$minutes Minuten ";
    }
    if (seconds > 0) {
      str += "$seconds Sekunden ";
    }
    if (millis > 0) {
      str += "$millis Millisekunden ";
    }
    if (str.trim().isEmpty) {
      return "Ohne Zeitverzögerung";
    }
    return str.trim();
  }

  Duration delay;
  bool waitForUserInput;
  EventStatus status = EventStatus.NONE;
  double? progress;

  Map<String, dynamic> toJson();
}

class MessageNode extends EventNode {
  @override
  final Set<String> lamps;
  List<String> activeLamps = [];
  IBluetoothMessage message;
  ValueChanged<IBluetoothMessage>? onUpdateMessage;

  @override
  String getTitle() {
    switch (message.messageType) {
      case MessageType.color:
        return "Farbe";
      case MessageType.interpolated:
        return "Animation";
      case MessageType.request:
        // TODO: Handle this case.
        break;
      case MessageType.onoff:
        // TODO: Handle this case.
        break;
      case MessageType.poti:
        // TODO: Handle this case.
        break;
      case MessageType.brightness:
        return "Helligkeit";
        break;
      case MessageType.save:
        // TODO: Handle this case.
        break;
      case MessageType.clear:
        // TODO: Handle this case.
        break;
    }
    return "Unbekannt";
  }

  MessageNode(
      {Key? key,
      required this.lamps,
      required this.message,
      update,
      onDelete,
      bool waitForUserInput = false,
      Duration delay = Duration.zero})
      : super(
            key: key,
            update: update,
            onDelete: onDelete,
            waitForUserInput: waitForUserInput,
            delay: delay);

  @override
  State<StatefulWidget> createState() => MessageNodeState();

  @override
  NodeType type = NodeType.MESSAGE;

  @override
  RichText getSubtitle(BuildContext context, TextStyle baseStyle) {
    return RichText(
        maxLines: 2, text: TextSpan(style: baseStyle, text: "Unbekannt"));
  }

  @override
  displayAsProgressBar() {
    return message.displayAsProgressBar();
  }

  @override
  toColor() {
    assert(cardIndicator == CardIndicator.COLOR);
    return message.toColor();
  }

  @override
  toGradient() {
    assert(cardIndicator == CardIndicator.GRADIENT);
    return message.toGradient();
  }

  @override
  toPercentage() {
    assert(cardIndicator == CardIndicator.PROGRESS);
    return message.toPercentage();
  }

  @override
  bool hasLamps() {
    return true;
  }

  @override
  Duration? delayAfterwards() {
    return const Duration(seconds: 1);
  }

  @override
  bool manualDelayAfterwards() {
    return false;
  }

  @override
  CardIndicator get cardIndicator {
    return message.indicator;
  }

  @override
  Future<void> execute() async {
    print("Sending a message of ${message.messageType}");
    if (lamps.isEmpty) {
      BluetoothControllerWidget().broadcast(message);
    } else {
      BluetoothControllerWidget().broadcastToGroups(message, lamps);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {"message": message.toJson()};
  }

  @override
  String getSubtitleText() {
    switch (message.messageType) {
      case MessageType.color:
        return "Setze die Farbe ${message.retrieveText()}";
      case MessageType.interpolated:
        return "Spiele die Animation ${message.retrieveText()}";

      case MessageType.request:
        break;
      case MessageType.onoff:
        break;
      case MessageType.poti:
        break;
      case MessageType.brightness:
        return "Setze die Helligkeit auf ${message.retrieveText()}";
      case MessageType.save:
        break;
      case MessageType.clear:
        break;
    }
    return "";
  }
}

class ParentNode extends INode {
  List<EventNode> events;
  EventStatus status;
  String? title;
  ParentNode(
      {Key? key,
      update,
      onDelete,
      this.type = NodeType.NOT_DEFINED,
      this.events = const [],
      this.title,
      this.status = EventStatus.NONE})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => ParentNodeState();

  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "messages": events.map((e) => e.toJson()),
    };
  }

  @override
  NodeType type;
}

class AddNode extends INode {
  AddNode({Key? key}) : super(key: key);

  @override
  NodeType type = NodeType.NOT_DEFINED;

  @override
  State<StatefulWidget> createState() => AddNodeState();
}

abstract class INodeState<T extends INode> extends State<T> {}

class AddNodeState extends INodeState<AddNode> {
  @override
  Widget build(BuildContext context) {
    return DottedBorder(
        borderType: BorderType.RRect,
        dashPattern: const [5, 5],
        radius: const Radius.circular(8),
        color: Colors.blueAccent,
        child: Padding(
            padding: const EdgeInsets.all(58),
            child: Center(
                child: IconButton(
              onPressed: () => {},
              color: Colors.blueAccent,
              icon: const Icon(Icons.add),
            ))));
  }
}

class MessageNodeState extends INodeState<MessageNode>
    with TickerProviderStateMixin {
  List<SBluetoothDevice> connectedDevices = [];
  Map<String, bool> active = {};
  StreamSubscription<dynamic>? myStream;

  @override
  void initState() {
    myStream?.cancel();
    myStream =
        BluetoothControllerWidget().connectedDevicesStream().listen((event) {
      setState(() {
        connectedDevices = event;
        active = {for (var e in event) e.device.id.id: true};
      });
    });
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _myAnimation = CurvedAnimation(curve: Curves.linear, parent: _controller);
    widget.onUpdateMessage = (m) {
      print("UPDATES MESSAGE");
      setState(() {
        widget.message = m;
        print(widget.message);
      });
    };
  }

  void updateActive() {
    setState(() {
      widget.activeLamps = active.entries
          .where((element) => element.value == true)
          .map((e) => e.key)
          .toList();
    });
  }

  @override
  void dispose() {
    myStream?.cancel();
    super.dispose();
  }

  String getTitle() {
    switch (widget.message.messageType) {
      case MessageType.color:
        return "Farbe";
      case MessageType.interpolated:
        return "Animation";
        break;
      case MessageType.request:
        break;
      case MessageType.onoff:
        break;
      case MessageType.poti:
        break;
      case MessageType.brightness:
        return "Helligkeit";
      case MessageType.save:
        break;
      case MessageType.clear:
        break;
    }
    return "Nicht definiert";
  }

  String getPostfix() {
    return "senden";
  }

  String getText() {
    return widget.message.retrieveText();
  }

  Color getColor() {
    return widget.message.toColor();
  }

  Widget getAvatar(String name) {
    var group = LampGroups.values
        .firstWhereOrNull((e) => name.toLowerCase() == e.name.toLowerCase());
    if (group != null) {
      return Icon(group.icon, size: 18);
    }
    return Text(name[0].toUpperCase());
  }

  late Animation<double> _myAnimation;
  late AnimationController _controller;
  bool timeIsExtended = false;

  @override
  Widget build(BuildContext context) {
    TextEditingController textController = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
                children: widget.lamps
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(left: 4, right: 4),
                          child: Chip(
                            avatar: CircleAvatar(
                              child: getAvatar(e),
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                            ),
                            label: Text(e),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onDeleted: () => {
                              setState(() {
                                widget.lamps.remove(e);
                              })
                            },
                          ),
                        ))
                    .toList()
                  ..add(Padding(
                    padding: const EdgeInsets.only(left: 4, right: 4),
                    child: ActionChip(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (_) {
                              return AlertDialog(
                                title: const Text(
                                    "Gruppenbeschränkung hinzufügen"),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Vorlagen"),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Wrap(
                                        children: LampGroups.values
                                            .map((e) => ActionChip(
                                                avatar: CircleAvatar(
                                                  foregroundColor:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .onPrimary,
                                                  backgroundColor:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                  child: Icon(e.icon, size: 18),
                                                ),
                                                label:
                                                    Text(e.name.toLowerCase()),
                                                onPressed: () => {
                                                      textController.text =
                                                          e.name.toLowerCase()
                                                    }))
                                            .toList(),
                                      ),
                                    ),
                                    TextFormField(
                                      controller: textController,
                                      decoration: const InputDecoration(
                                          labelText: "Lampengruppe definieren"),
                                    )
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    child: const Text("Abbrechen"),
                                    onPressed: () => {Navigator.pop(context)},
                                  ),
                                  TextButton(
                                      child: const Text("Speichern"),
                                      onPressed: () {
                                        if (textController.text
                                            .trim()
                                            .isNotEmpty) {
                                          setState(() {
                                            widget.lamps.add(
                                                textController.text.trim());
                                          });
                                        }
                                        Navigator.pop(context);
                                      })
                                ],
                              );
                            });
                      },
                      label: const Icon(Icons.add),
                    ),
                  )))),
        const Divider(),
        ListTile(
          title: TextButton(
            onPressed: () {
              setState(() {
                timeIsExtended = !timeIsExtended;
              });
              if (timeIsExtended) {
                _controller.forward();
              } else {
                _controller.reverse();
              }
            },
            child: RichText(
                text: TextSpan(children: [
              TextSpan(
                  text: "Dauer: ",
                  style: Theme.of(context).textTheme.bodyMedium),
              WidgetSpan(
                  child: Icon(Icons.access_time,
                      size: 16,
                      color: Theme.of(context).colorScheme.inverseSurface)),
              TextSpan(
                  text: " ${widget.formatTime()}",
                  style: Theme.of(context).textTheme.bodyMedium)
            ])),
          ),
          trailing: IconButton(
            icon: RotationTransition(
              turns: Tween(begin: 0.0, end: 0.5).animate(_controller),
              child: const Icon(Icons.expand_more),
            ),
            onPressed: () {
              setState(() {
                timeIsExtended = !timeIsExtended;
              });
              if (timeIsExtended) {
                _controller.forward();
              } else {
                _controller.reverse();
              }
            },
          ),
        ),
        AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: timeIsExtended ? null : 0,
            child: SizeTransition(
              sizeFactor: Tween<double>(begin: 0, end: 1).animate(_controller),
              child: Column(
                children: [
                  CheckboxListTile(
                      value: widget.waitForUserInput,
                      onChanged: (t) => {
                            setState(() {
                              widget.waitForUserInput = t!;
                            })
                          },
                      title: const Text("Auf Benutzereingabe warten")),
                  if (widget.message is ColorMessage &&
                      !widget.waitForUserInput) ...[
                    CheckboxListTile(
                        value: widget.waitForUserInput,
                        onChanged: (t) => {setState(() {})},
                        title: const Text("Sanfter Übergang")),
                  ]
                ],
              ),
            )),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: timeIsExtended && !widget.waitForUserInput ? 100 : 0.000001,
          child: TimePicker(
            small: true,
            onChanged: (t) => {
              setState(() {
                widget.delay = t;
              })
            },
          ),
        )
      ],
    );
  }
}

class ParentNodeState extends INodeState<ParentNode> {
  String getTitle() {
    return widget.title ?? "Unbenannt";
  }

  @override
  Widget build(BuildContext context) {
    return Text(getTitle());
  }
}
