import 'dart:math';

// import 'dart:io' show Platform;
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:move_to_background/move_to_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.black, // navigation bar color
    statusBarColor: Colors.black, // status bar color
  ));
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MusicApp(),
    );
  }
}

class MusicApp extends StatefulWidget {
  @override
  _MusicAppState createState() => _MusicAppState();
}

class _MusicAppState extends State<MusicApp> {
  bool playing = false;
  IconData playBtn = Icons.play_arrow;
  IconData modeBtn = Icons.sync_alt;
  String playingTitle = '';
  int playingNum = 1;
  final _player = AssetsAudioPlayer();
  Duration position = new Duration();
  Duration musicLength = new Duration();
  bool isInit = true;
  Widget slider() {
    return Expanded(
      child: Slider.adaptive(
          activeColor: Colors.black,
          inactiveColor: Colors.grey[350],
          value: position.inSeconds.toDouble(),
          max: musicLength.inSeconds.toDouble(),
          onChanged: (value) {
            seekToSec(value.toInt());
          }),
    );
  }

  //let's create the seek function that will allow us to go to a certain position of the music
  void seekToSec(int sec) {
    Duration newPos = Duration(seconds: sec);
    _player.seek(newPos);
  }

  void playSound(int soundNumber, {Duration seek}) async {
    SharedPreferences soundInf = await SharedPreferences.getInstance();
    _player
        .open(
      Audio("assets/audios/_ ($soundNumber).wav"),
      showNotification: true,
      notificationSettings: NotificationSettings(
        // prevEnabled: false, //disable the previous button
        customPrevAction: (player) {
          if (playingNum != null) playSound(playingNum - 1);
        },
        customNextAction: (player) {
          if (playingNum != null) playSound(playingNum + 1);
        },
        customStopAction: (player) {
          _player.stop();
          setState(() {
            playBtn = Icons.play_arrow;
            playing = false;
          });
        },
      ),
      seek: seek ?? seek,
    )
        .then((value) {
      setState(() {
        playBtn = Icons.pause;
        playing = true;
        playingTitle = title[soundNumber - 1];
        playingNum = soundNumber;
      });
      _player.updateCurrentAudioNotification(
        metas: Metas(
          artist: 'الشيخ أحمد جمال',
          title: playingTitle,
          // image: MetasImage.asset('assets/audios/Mishary.jpg',
        ),
      );
      // setState(() {
      //   musicLength = _player.current.value.audio.duration;
      // });
      soundInf.setString('playingTitle', playingTitle);
      soundInf.setInt('playingNum', playingNum);
    });

    _player.current.listen((playingAudio) {
      try {
        setState(() {
          musicLength = _player.current.value.audio.duration;
        });
        soundInf.setInt('musicLength', musicLength.inSeconds);
      } catch (e) {
        // TODO
      }
    });
    _player.currentPosition.listen((p) {
      setState(() {
        position = p;
      });
      soundInf.setInt('position', position.inSeconds);
    });
  }

  getInf() async {
    SharedPreferences soundInf = await SharedPreferences.getInstance();
    setState(() {
      position = Duration(seconds: soundInf.getInt("position") ?? 0);
      musicLength = Duration(seconds: soundInf.getInt("musicLength") ?? 0);
      playingNum = soundInf.getInt("playingNum") ?? 0;
      playingTitle = soundInf.getString("playingTitle") ?? '';
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getInf();
    _player.playlistFinished.listen((isFinished) {
      if (isFinished && playingNum != title.length && playing != false) {
        if (modeBtn == Icons.sync_alt) {
          playSound(playingNum + 1);
        } else if (modeBtn == Icons.shuffle) {
          playSound(Random().nextInt(title.length));
        } else if (modeBtn == Icons.repeat_one) {
          playSound(playingNum);
        }
      } else if (isFinished && playingNum == title.length && playing != false) {
        playSound(1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return WillPopScope(
      onWillPop: () async {
        MoveToBackground.moveTaskToBack();
        return false;
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.brown[800],
                  Colors.blue[200],
                ]),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              top: 48.0,
            ),
            child: Container(
              child: Column(
                // mainAxisAlignment: MainAxisAlignment.start,
                // crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //Let's add some text title
                  Container(
                    height: size.height * .16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundImage: AssetImage(
                            'assets/audios/Mishary.jpg',
                          ),
                        ),
                        SizedBox(width: 15),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "القارئ الشيخ",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 24.0,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Text(
                              "أحمد جمال",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 38.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 15.0),
                  // Let's add the music cover
                  Center(
                    child: Container(
                      // width: 280.0,
                      // height: 370.0,
                      height: size.height * .45,
                      // decoration: BoxDecoration(
                      //   borderRadius: BorderRadius.circular(30.0),
                      // ),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: ListView.builder(
                          itemCount: title.length,
                          itemBuilder: (_, i) {
                            return ListTile(
                              leading: Text('${i + 1} - '),
                              title: Text(
                                title[i],
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 25),
                              ),
                              onTap: () {
                                playSound(i + 1);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  // SizedBox(height: 18.0),
                  Expanded(
                    child: Container(
                      height: size.height * .3,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30.0),
                          topRight: Radius.circular(30.0),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            height: 45,
                            width: double.infinity,
                            child: Center(
                              child: Text(
                                playingTitle,
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 32.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          slider(),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.only(right: 8, left: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  "${position.inMinutes}:${position.inSeconds.remainder(60)}",
                                  style: TextStyle(
                                    fontSize: 18.0,
                                  ),
                                ),
                                Text(
                                  "${musicLength.inMinutes}:${musicLength.inSeconds.remainder(60)}",
                                  style: TextStyle(
                                    fontSize: 18.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              IconButton(
                                iconSize: 45.0,
                                color: Colors.black,
                                onPressed: () {
                                  if (modeBtn == Icons.sync_alt) {
                                    setState(() {
                                      modeBtn = Icons.shuffle;
                                    });
                                  } else if (modeBtn == Icons.shuffle) {
                                    setState(() {
                                      modeBtn = Icons.repeat_one;
                                    });
                                  } else if (modeBtn == Icons.repeat_one) {
                                    setState(() {
                                      modeBtn = Icons.sync_alt;
                                    });
                                  }
                                },
                                icon: Icon(modeBtn),
                              ),
                              IconButton(
                                iconSize: 45.0,
                                color: Colors.black,
                                onPressed: () {
                                  if (playingNum != null)
                                    playSound(playingNum - 1);
                                },
                                icon: Icon(
                                  Icons.skip_previous,
                                ),
                              ),
                              IconButton(
                                iconSize: 62.0,
                                color: Colors.black,
                                onPressed: () {
                                  //here we will add the functionality of the play button
                                  if (!playing) {
                                    if (playingTitle == '') {
                                      playSound(1);
                                    } else {
                                      if (isInit) {
                                        playSound(playingNum, seek: position);
                                        setState(() {
                                          isInit = false;
                                        });
                                      } else {
                                        _player.play();
                                      }
                                    }
                                    setState(() {
                                      playBtn = Icons.pause;
                                      playing = true;
                                    });
                                  } else {
                                    _player.pause();
                                    setState(() {
                                      playBtn = Icons.play_arrow;
                                      playing = false;
                                    });
                                  }
                                },
                                icon: Icon(
                                  playBtn,
                                ),
                              ),
                              IconButton(
                                iconSize: 45.0,
                                color: Colors.black,
                                onPressed: () {
                                  if (playingNum != null &&
                                      modeBtn == Icons.shuffle) {
                                    playSound(Random().nextInt(title.length));
                                  } else if (playingNum != null &&
                                      playingNum != title.length)
                                    playSound(playingNum + 1);
                                },
                                icon: Icon(
                                  Icons.skip_next,
                                ),
                              ),
                              IconButton(
                                iconSize: 45.0,
                                color: Colors.black,
                                onPressed: () async {
                                  _player.stop();
                                  setState(() {
                                    playBtn = Icons.play_arrow;
                                    playing = false;
                                  });
                                },
                                icon: Icon(
                                  Icons.stop,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<String> title = [
    'الفَاتِحَة',
    'البَقَرَة',
    'آل عِمرَان',
    'النِّسَاء',
    'المَائدة',
    'الأنعَام',
    'الأعرَاف',
    'الأنفَال',
    'التوبَة',
    'يُونس',
    'هُود',
    'يُوسُف',
    'الرَّعْد',
    'إبراهِيم',
    'الحِجْر',
    'النَّحْل',
    'الإسْرَاء',
    'الكهْف',
    'مَريَم',
    'طه',
    'الأنبيَاء',
    'الحَج',
    'المُؤمنون',
    'النُّور',
    'الفُرْقان',
    'الشُّعَرَاء',
    'النَّمْل',
    'القَصَص',
    'العَنكبوت',
    'الرُّوم',
    'لقمَان',
    'السَّجدَة',
    'الأحزَاب',
    'سَبَأ',
    'فَاطِر',
    'يس',
    'الصَّافات',
    'ص',
    'الزُّمَر',
    'غَافِر',
    'فُصِّلَتْ',
    'الشُّورَى',
    'الزُّخْرُف',
    'الدُّخان',
    'الجاثِية',
    'الأحقاف',
    'مُحَمّد',
    'الفَتْح',
    'الحُجُرات',
    'ق',
    'الذَّاريَات',
    'الطُّور',
    'النَّجْم',
    'القَمَر',
    'الرَّحمن',
    'الواقِعَة',
    'الحَديد',
    'المُجادَلة',
    'الحَشْر',
    'المُمتَحَنة',
    'الصَّف',
    'الجُّمُعة',
    'المُنافِقُون',
    'التَّغابُن',
    'الطَّلاق',
    'التَّحْريم',
    'المُلْك',
    'القَلـََم',
    'الحَاقّـَة',
    'المَعارِج',
    'نُوح',
    'الجِنّ',
    'المُزَّمّـِل',
    'المُدَّثــِّر',
    'القِيامَة',
    'الإنسان',
    'المُرسَلات',
    'النـَّبأ',
    'النـّازِعات',
    'عَبَس',
    'التـَّكْوير',
    'الإنفِطار',
    'المُطـَفِّفين',
    'الإنشِقاق',
    'البُروج',
    'الطّارق',
    'الأعلی',
    'الغاشِيَة',
    'الفَجْر',
    'البَـلـَد',
    'الشــَّمْس',
    'اللـَّيل',
    'الضُّحی',
    'الشَّرْح',
    'التـِّين',
    'العَلـَق',
    'القـَدر',
    'البَيِّنَة',
    'الزلزَلة',
    'العَادِيات',
    'القارِعَة',
    'التَكاثـُر',
    'العَصْر',
    'الهُمَزَة',
    'الفِيل',
    'قـُرَيْش',
    'المَاعُون',
    'الكَوْثَر',
    'الكَافِرُون',
    'النـَّصر',
    'المَسَد',
    'الإخْلَاص',
    'الفَلَق',
    'النَّاس',
    'دعاء ختم القرآن'
  ];
}
