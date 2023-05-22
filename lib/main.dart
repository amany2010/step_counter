import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() => runApp(const StepMentoringApp());

/// Stateful widget to fetch and then display video content.
class StepMentoringApp extends StatefulWidget {
  const StepMentoringApp({super.key});

  @override
  _StepMentoringAppState createState() => _StepMentoringAppState();
}

class _StepMentoringAppState extends State<StepMentoringApp> {
  late VideoPlayerController _controller;
  double lastMagnitude = 0,accMagnitudeAvg=0;
  int steps = 0;
  bool startFlag = false, stopFlag = false;
  late List<double> sensorMag = [];
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];
  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset("assets/background.mp4")
      ..initialize().then((_) {
        // Once the video has been loaded we play the video and set looping to true.
        _controller.play();
        _controller.setLooping(true);
        // Ensure the first frame is shown after the video is initialized
        setState(() {});
      });
    _streamSubscriptions.add(
      userAccelerometerEvents.listen(
        (UserAccelerometerEvent event) {
          setState(() {
            if (event!=null) {
              double x=double.parse((event.x).toStringAsFixed(3)),y=double.parse((event.y).toStringAsFixed(3)),z=double.parse((event.z).toStringAsFixed(3));
              double magnitude = sqrt(pow(x, 2) + pow(y, 2) + pow(z, 2));
              accMagnitudeAvg+=magnitude;
              if (startFlag) {
                  sensorMag.add(magnitude);
              }
              if (stopFlag && sensorMag.isNotEmpty) {
                steps += detectSteps();
              }
              if (kDebugMode) {
                print("\nSteps:$steps");
              }
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0x00e2e2e2).withOpacity(.4),
            centerTitle: true,
            title: Text(
              'Step Mentoring',
              style: TextStyle(
                fontSize: 32,
                color: const Color(0x00193f56).withOpacity(1),
              ),
            ),
          ),
          body: Stack(
            children: [
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size?.width ?? 0,
                    height: _controller.value.size?.height ?? 0,
                    child: VideoPlayer(_controller),
                  ),
                ),
              ),
              Container(
                color: const Color(0x00093f56).withOpacity(.5),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: CircleAvatar(
                      radius: 120,
                      backgroundColor: const Color(0x00e2e2e2).withOpacity(.3),
                      child: CircleAvatar(
                        backgroundColor: const Color(0x00e2e2e2).withOpacity(.5),
                        radius: 110,
                        child: Text(
                          '$steps',
                          style: TextStyle(
                            fontSize: 64,
                            color: const Color(0x00193f56).withOpacity(1),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FloatingActionButton.large(
                        backgroundColor: const Color(0x00e2e2e2).withOpacity(.5),
                        foregroundColor: const Color(0x00193f56).withOpacity(1),
                        onPressed: () {
                          setState(() {
                            startFlag = true;
                            stopFlag = false;
                          });
                        },
                        child: const Text(
                          'Start',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      FloatingActionButton.large(
                        backgroundColor: const Color(0x00e2e2e2).withOpacity(.5),
                        foregroundColor: const Color(0x00193f56).withOpacity(1),
                        onPressed: () {
                          setState(() {
                            stopFlag = true;
                            startFlag = false;
                          });
                        },
                        child: const Text(
                          'Stop',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      FloatingActionButton.large(
                        backgroundColor: const Color(0x00e2e2e2).withOpacity(.5),
                        foregroundColor: const Color(0x00193f56).withOpacity(1),
                        onPressed: () {
                          setState(() {
                            steps = 0;
                            startFlag = false;
                            stopFlag = false;
                            sensorMag.clear();
                          });
                        },
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              ),
              //stepCounter()
            ],
          )),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
  }

  int detectSteps()
  {
    int steps = 0,n = sensorMag.length;
    double standardDeviation=0;
    accMagnitudeAvg/=n;
    accMagnitudeAvg=double.parse((accMagnitudeAvg).toStringAsFixed(3));
    for(int i=0;i<n;i++)
    {
      standardDeviation+=pow(sensorMag[i]-accMagnitudeAvg,2);
    }
    standardDeviation=sqrt(standardDeviation/(n-1));
    standardDeviation=double.parse((standardDeviation).toStringAsFixed(3));
    if (standardDeviation != 0) {
      for (int i = 1; i <n-1; i++) {
        if (sensorMag[i - 1] <= sensorMag[i] && sensorMag[i] >= sensorMag[i + 1] && sensorMag[i] >= standardDeviation) {
          steps++;
        }
      }
    } else {
      for (int i = 0; i <n-1; i++) {
        if (sensorMag[i - 1] <= sensorMag[i] && sensorMag[i] >= sensorMag[i + 1]) {
         steps++;
        }
      }
  }
    sensorMag.clear();
    accMagnitudeAvg=0;
    if (kDebugMode) {
      print("-----------------------$steps\n");
    }
    return steps;
  }
}
