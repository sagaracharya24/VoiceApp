import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_device_type/flutter_device_type.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:voice_recognition_app/messages.dart';
import 'package:voice_recognition_app/permission_service.dart';

void main() {
  runApp(MainPage());
}

enum TtsState { playing, stopped }

List<Language> languages = [
  const Language('System', 'default'),
  const Language('Francais', 'fr_FR'),
  const Language('English', 'en_US'),
  const Language('Pусский', 'ru_RU'),
  const Language('Italiano', 'it_IT'),
  const Language('Español', 'es_ES'),
];

class Language {
  final String name;
  final String code;

  const Language(this.name, this.code);
}

class MainPage extends StatefulWidget {
  @override
  _MainPage createState() => new _MainPage();
}

class _MainPage extends State<MainPage> {
  final List<Messages> messages = <Messages>[];
  SpeechToText _speech;
  double level = 0.0;
  bool isAvailable = false;
  bool isListening = false;
  String resultText = "";
  bool isSpeaking = false;

  bool onTap = false;
  bool isVoiceEnabled = false;
  bool isContinuousSpeaking = false;
  bool shouldEndSession = false;
  Timer onTimer;
  SharedPreferences sharedPreferences;
  FlutterTts flutterTts;
  TtsState ttsState = TtsState.stopped;

  bool isNotchDevice = false;

  Language selectedLang = languages.first;

  Future myFunction() => new Future.delayed(Duration(milliseconds: 500));

  bool _startAnimation = false;

  Widget animatedAssistantButton() {
    return new Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: new Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          new Flexible(
            child: GestureDetector(
              onTap: () {
                onTap = !onTap;
                if (ttsState == TtsState.playing) {
                  flutterTts.stop();
                  stop();
                  onTap = true;
                }
                checkForAudioPermission(context).then((isAudioPermission) async {
                  if (isAudioPermission) {
                    if (onTap) {
                      if (!isAvailable) isAvailable = true;
                      if (isAvailable && !isListening) {
                        //start();
                        setState(() {
                          isSpeaking = true;
                        });
                      }
                    } else {
                      if (isListening && !onTap) {
                        stop();
                      }

                      if (!isListening && !onTap) {
                        stop();
                      }
                    }
                  }
                });
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.0),
                child: AnimatedContainer(
                    onEnd: () {
                      setState(() {
                        if (isSpeaking == true) {
                          _startAnimation = true;
                          start();
                        }
                      });
                    },
                    duration: Duration(milliseconds: 300),
                    width: isSpeaking ? 200 : 100,
                    height: 40,
                    color: Colors.black54,
                    child: _startAnimation
                        ? Icon(
                            Icons.mic,
                            color: Colors.white,
                          )
                        : Icon(
                            Icons.speaker_phone,
                            color: Colors.white,
                          )),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void cancel() {
    _speech.cancel();
    setState(() => isListening = false);
  }

  void stop() {
    _speech.stop();
    setState(() {
      isListening = false;
      isSpeaking = false;
      _startAnimation = false;
    });
  }

  void processRequest(query) async {
    Messages message = new Messages(
      text: query,
      name: "Bot",
      type: false,
      loading: false,
    );

    setState(() {
      messages.removeAt(0);
      messages.insert(0, message);
    });

    if (isVoiceEnabled) {
      voiceResponse(query);
    }
  }

  errorMessage(dynamic query) {
    setState(() {
      messages.removeAt(0);
      messages.removeAt(0);
      Messages messagechange = new Messages(
        text: query,
        name: "User",
        type: true,
        color: Colors.grey,
      );
      messages.insert(0, messagechange);
    });
  }

  void initializeRequest(String text) {
    text = text[0].toUpperCase() + text.substring(1);
    Messages message = new Messages(
      text: text,
      name: "User",
      type: true,
    );
    Messages loadingmessage = new Messages(
      text: 'Messsage is loading',
      name: "Bot",
      type: false,
      loading: true,
    );
    setState(() {
      messages.insert(0, message);
      messages.insert(0, loadingmessage);
      isSpeaking = false;
      _startAnimation = false;
    });
    processRequest(text);
  }

  @override
  initState() {
    super.initState();

    // Provider.of<MySessionProvider>(context, listen: false).sessionId;
    _speech = SpeechToText();
    initIconStates();

    setInitialMessage();

    if (Device.get().isIphoneX) {
      isNotchDevice = true;
    }
    if (isContinuousSpeaking == null && isVoiceEnabled == null) {
      setState(() {
        isContinuousSpeaking = false;
        isVoiceEnabled = false;
      });
    }
    initSpeak();
    activateSpeechRecognizer();
  }

  initSpeak() {
    flutterTts = FlutterTts();
    flutterTts.setStartHandler(() {
      setState(() {
        ttsState = TtsState.playing;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        ttsState = TtsState.stopped;
      });

      if (ttsState == TtsState.stopped) {
        if (isContinuousSpeaking == true && shouldEndSession == false) {
          setState(() {
            onTap = true;
            isAvailable = true;
            isListening = true;
          });
          if (isAvailable && isListening) {
            start();
            setState(() {
              isSpeaking = true;
              _startAnimation = true;
            });
          }
        }
      }
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        ttsState = TtsState.stopped;
      });
    });
  }

  void soundLevelListener(double level) {
    setState(() {
      this.level = level;
    });
  }

  void errorHandler(SpeechRecognitionError error) {
    if (error.errorMsg == "error_no_match") {
      isListening = false;
      onTap = false;
    }
    if (error.errorMsg == 'error_speech_timeout') {
      isListening = false;
      onTap = false;
    }
    setState(() {
      isSpeaking = false;
      _startAnimation = false;
    });
  }

  void onSpeechAvailability(String status) {
    setState(() {
      isAvailable = _speech.isAvailable;
      isListening = _speech.isListening;
    });
  }

  Future<void> activateSpeechRecognizer() async {
    _speech = SpeechToText();
    isAvailable = await _speech.initialize(debugLogging: true, onError: errorHandler, onStatus: onSpeechAvailability);
    List<LocaleName> localeNames = await _speech.locales();
    languages.clear();
    localeNames.forEach((localeName) => languages.add(Language(localeName.name, localeName.localeId)));
    var currentLocale = await _speech.systemLocale();
    if (null != currentLocale) {
      selectedLang = languages.firstWhere((lang) => lang.code == currentLocale.localeId);
    }
    setState(() {});
  }

  void start() => _speech.listen(onResult: onRecognitionResult, localeId: selectedLang.code);

  void onRecognitionResult(SpeechRecognitionResult result) {
    if (result.finalResult) {
      resultText = result.recognizedWords;
      onRecognitionComplete(resultText);
    }
  }

  void onRecognitionComplete(String result) {
    setState(() => isListening = false);
    initializeRequest(result);
  }

  initIconStates() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    if (sharedPreferences.getBool(
              'isContinuousSpeaking',
            ) ==
            null &&
        sharedPreferences.getBool('isVoiceEnabled') == null) {
      setState(() {
        isContinuousSpeaking = false;
        isVoiceEnabled = false;
      });
    } else {
      isContinuousSpeaking = (sharedPreferences.getBool(
            'isContinuousSpeaking',
          ) ??
          false);
      isVoiceEnabled = (sharedPreferences.getBool('isVoiceEnabled') ?? false);
      setState(() {});
    }
  }

  Future voiceResponse(String voice) async {
    var languageResult = await flutterTts.setLanguage('en-US');
    var result = await flutterTts.speak(voice);
    if (result == 1 && languageResult == 1) {
      setState(() => ttsState = TtsState.playing);
    }
  }

  Future stopVoiceResponse() async {
    if (ttsState == TtsState.playing) {
      flutterTts.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: new Scaffold(
        appBar: AppBar(
          //  brightness: Brightness.light,

          title: Text(
            'Sample Voice App',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),

          backgroundColor: Colors.white,
          actions: <Widget>[
            IconButton(
              onPressed: () async {
                setState(() {
                  isVoiceEnabled = !isVoiceEnabled;
                  if (isVoiceEnabled == false) {
                    stopVoiceResponse();
                  }
                });
                SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
                sharedPreferences.setBool('isVoiceEnabled', isVoiceEnabled);
              },
              icon: isVoiceEnabled
                  ? Icon(
                      Icons.volume_up,
                      color: Colors.black,
                    )
                  : Icon(Icons.volume_off, color: Colors.black),
            ),
          ],
        ),
        body: SafeArea(
          child: Container(
            child: new Column(children: <Widget>[
              new Flexible(
                  child: new ListView.builder(
                padding: new EdgeInsets.all(8.0),
                reverse: true,
                itemBuilder: (_, int index) => messages[index],
                itemCount: messages.length,
              )),
              Padding(
                padding: isNotchDevice ?? const EdgeInsets.all(0.0) ? const EdgeInsets.only(bottom: 15) : const EdgeInsets.all(0.0),
                child: new Container(
                  child: animatedAssistantButton(),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> setInitialMessage() async {
    Messages message = new Messages(
      text: 'Hello, What you like to do?',
      name: "Bot",
      type: false,
    );
    messages.insert(0, message);
  }

  Future<bool> checkForAudioPermission(BuildContext context) async {
    bool value = await PermissionsService().hasMicrophonePermission();
    print(value);
    if (!value) {
      setState(() {
        isSpeaking = false;
        _startAnimation = false;
        onTap = false;
      });
      bool permissionvalue = await PermissionsService().requestMicrophonePermission();
      if (permissionvalue) {
        setState(() {
          isSpeaking = false;
          _startAnimation = false;
          onTap = false;
        });
        return true;
      } else {
        PermissionsService().requestMicrophonePermission();
        return false;
      }
    }

    return true;
  }

  void handleDeniedAudioPermission(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext _context) {
          return SimpleDialog(
            title: const Text("Permission Denied"),
            children: <Widget>[
              Container(
                padding: EdgeInsets.only(left: 30, right: 30, top: 15, bottom: 15),
                child: const Text(
                  "Please allow audio permission to use this application",
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                ),
              )
            ],
          );
        });
  }
}
