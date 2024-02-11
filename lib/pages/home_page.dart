import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SpeechToText _speechToText = SpeechToText();
  final List<String> _speechResultsList = [];
  bool _speechEnabled = false;
  String _wordsSpoken = "";
  double _confidenceLevel = 0;
  bool _gameEnabled = true;

  int _player1Score = 0;
  int _player2Score = 0;
  int _playerTurn = 0;

  @override
  void initState() {
    super.initState();
    initSpeech();
  }

  void initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {
      //_wordsSpoken = ""; // 추가
    });
  }

  void _startListening() async {
    _clearWordsSpoken(); // _wordsSpoken 초기화
    await _speechToText.listen(onResult: _onSpeechResult);
    _startCoutDonwn(); // 초시계 작동
    setState(() {
      _confidenceLevel = 0;
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      if (_wordsSpoken == "") {
        // 시간안에 단어를 말하지 못할 떄 -> 게임 종료
        _gameEnabled = false;
      } else if (_speechResultsList.contains(_wordsSpoken)) {
        // 리스트 안에 있는 단어를 말할 떄 -> 게임 종료
        // _wordsSpoken = "Wrong! '$_wordsSpoken' is already in the list.";
        _gameEnabled = false;
      } else {
        _autoPressButton(); // 자동 누르기 호출, 다른 플레이어로 넘어감
        _speechResultsList.add(_wordsSpoken);
        setState(() {
          if (_playerTurn % 2 == 0) {
            _player1Score++;
          } else {
            _player2Score++;
          }
          _playerTurn++;
        });
      }
    });
  }

  void _clearWordsSpoken() {
    setState(() {
      _wordsSpoken = "";
    });
  }

  void _onSpeechResult(result) {
    setState(() {
      _wordsSpoken = "${result.recognizedWords}";
      _confidenceLevel = result.confidence;
    });
  }

  // << Timer implementaion >>
  static const maxSeconds = 5;
  int timeLeft = maxSeconds;

  void _startCoutDonwn() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        setState(() {
          timeLeft--;
        });
      } else {
        resetTimer();
        timer.cancel();
      }
    });
  }

  void resetTimer() {
    setState(() {
      _stopListening();
      timeLeft = maxSeconds;
    });
  }

  void _autoPressButton() {
    //  1초 후에 자동으로 Button을 누르도록 설정
    Future.delayed(const Duration(seconds: 1), () {
      if (_gameEnabled) {
        _startListening();
      }
    });
  }

  void _restartGame() {
    setState(() {
      _gameEnabled = true;
      _player1Score = 0;
      _player2Score = 0;
      _playerTurn = 0;
      _confidenceLevel = 0;
      _speechResultsList.clear();
      _clearWordsSpoken();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text(
          'Speech Demo',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                _speechToText.isListening
                    ? "듣는 중"
                    : _speechEnabled
                        ? "듣고 있지 않음xx. start 버튼 누르세요 "
                        : "Speech not available",
                style: const TextStyle(fontSize: 20.0),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      //timeLeft.toString(),
                      timeLeft == 0 ? 'DONE' : timeLeft.toString(),
                      style: const TextStyle(fontSize: 50),
                    ),
                    Text(
                      ' $_player1Score : $_player2Score',
                      style: const TextStyle(fontSize: 20),
                    ),
                    Text(
                      '게임 진행 여부 : ${_gameEnabled ? '진행 중' : '종료'}',
                      style: const TextStyle(fontSize: 10),
                    ),
                    // MaterialButton(
                    //   onPressed: _startCoutDonwn,
                    //   color: Colors.deepPurple,
                    //   child: const Text(
                    //     'S T A R T',
                    //     style: TextStyle(
                    //       color: Colors.white,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _gameEnabled ? _wordsSpoken : '게임종료',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
            if (_speechToText.isNotListening && _confidenceLevel >= 0)
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 100,
                ),
                child: Text(
                  "Confidence: ${(_confidenceLevel * 100).toStringAsFixed(1)}%",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w200,
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: _speechResultsList.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_speechResultsList[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed:
                _speechToText.isListening ? _stopListening : _startListening,
            tooltip: 'Listen',
            backgroundColor: Colors.red,
            child: Icon(
              _speechToText.isNotListening ? Icons.mic_off : Icons.mic,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _restartGame, // 게임 재시작 버튼
            tooltip: 'Restart Game',
            backgroundColor: Colors.blue,
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}
