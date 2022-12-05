import 'package:flutter/material.dart';

import 'orchestra_timeline_view.dart';

class OrchestraListView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => OrchestraLiveViewState();

  List<String> animations = [
    "Cowboy",
    "Fight Scene 1",
  ];
  List<String> subtitles = [
    "Timeline Editor with 45 Nodes, 3 Categories. Duration: 10 Minutes. Lorem Ipsum Dolor Set Alem MASCHALLA",
    "Crazy Show",
  ];
  List<String> images = [
    "https://saarlouis.my-movie-world.de/images/Breite_400px_RGB/p_99343.jpg",
    "https://de.web.img3.acsta.net/pictures/21/03/03/20/40/1002269.jpg",
  ];
  List<bool> playing = [
    false,
    false,
  ];
  VoidCallback? play;
  bool isPlaying = false;

  OrchestraTimeline orchestra = OrchestraTimeline();
}

class OrchestraLiveViewState extends State<OrchestraListView> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: widget.animations.length,
        itemBuilder: (BuildContext context, int index) {
          return Card(
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12))),
            child: InkWell(
              onTap: () => {
                showDialog(
                    context: context,
                    builder: (_) {
                      return AlertDialog(
                        backgroundColor:
                            Theme.of(context).scaffoldBackgroundColor,
                        insetPadding: const EdgeInsets.all(16),
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(widget.animations[index]),
                        content: SizedBox(
                            height: 20000,
                            width: 2000,
                            child: widget.orchestra),
                        actions: [
                          IconButton(
                              onPressed: () {
                                print(widget.orchestra.nodes[0].events.length);
                                setState(() {
                                  widget.isPlaying = true;
                                });
                                widget.orchestra.play?.call();
                              },
                              icon: widget.isPlaying
                                  ? const Icon(Icons.stop)
                                  : const Icon(Icons.play_arrow)),
                          TextButton(
                              onPressed: () => {Navigator.pop(context)},
                              child: const Text("Abbrechen")),
                          TextButton(
                              onPressed: () => {Navigator.pop(context)},
                              child: const Text("Speichern"))
                        ],
                      );
                    })
              },
              child: ListTile(
                contentPadding: const EdgeInsets.all(18),
                title: Text(widget.animations[index],
                    style: Theme.of(context).textTheme.headline5),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        children: const [
                          Icon(Icons.access_time, size: 16),
                          Text(" 5 Minuten "),
                          Icon(Icons.list_alt, size: 16),
                          Text(" 3 Effekte "),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(runSpacing: 4, spacing: 4, children: [
                        const Chip(label: Text("Kurzfilm")),
                        Chip(label: Text("Szene $index"))
                      ])
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }

  @override
  void initState() {
    super.initState();
    widget.orchestra.onFinishPlay = () => {
          setState(() {
            print("Setting ");
            widget.isPlaying = false;
          })
        };
  }
}
