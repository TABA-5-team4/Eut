import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:http_parser/http_parser.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'image_item.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'dart:convert';

class EditImagePage extends StatefulWidget {
  final List<ImageItem> imageItems;
  final int initialIndex;

  const EditImagePage({
    Key? key,
    required this.imageItems,
    required this.initialIndex,
  }) : super(key: key);

  @override
  _EditImagePageState createState() => _EditImagePageState();
}

class _EditImagePageState extends State<EditImagePage> {
  late String _name;
  late int _currentIndex;
  late String _imagePath;
  late PageController _pageController;
  List<String> _imagePaths = [
    'assets/botboy.png',
    'assets/image1.png',
    'assets/image2.png',
  ];
  AudioPlayer _audioPlayer = AudioPlayer();
  String? _audioFilePath;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _name = widget.imageItems[_currentIndex].name;
    _imagePath = widget.imageItems[_currentIndex].imagePath;
    _pageController = PageController(initialPage: _imagePaths.indexOf(_imagePath));
  }

  void _editName() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController nameController = TextEditingController(text: _name);
        return AlertDialog(
          title: Text('이름 수정'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(hintText: "새 이름 입력"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _name = nameController.text;
                  widget.imageItems[_currentIndex] = widget.imageItems[_currentIndex].copyWith(name: _name);
                });
                Navigator.of(context).pop();
              },
              child: Text('저장'),
            ),
          ],
        );
      },
    );
  }

  void _onImageChanged(int index) {
    setState(() {
      _imagePath = _imagePaths[index];
      widget.imageItems[_currentIndex] = widget.imageItems[_currentIndex].copyWith(imagePath: _imagePath);
    });
  }

  void _playAudio() async {
    if (_audioFilePath != null) {
      await _audioPlayer.play(_audioFilePath!, isLocal: true);
    }
  }

  void _openVoiceRecordWidget() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return VoiceRecordWidget(
          onAudioFilePathUpdated: (filePath) {
            setState(() {
              _audioFilePath = filePath;
            });
          },
        );
      },
    );
  }

  Future<void> _submitEdit() async {
    if (_name.isNotEmpty && _audioFilePath != null) {
      try {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('http://3.38.165.93:8080//characters/{characterId}'), // API URL을 여기에 추가하세요
        );

        request.headers['Content-Type'] = 'multipart/form-data';
        request.fields['characterName'] = _name;

        // Add voiceFile field if it exists
        if (_audioFilePath != null) {
          final file = File(_audioFilePath!);
          request.files.add(
            http.MultipartFile.fromBytes(
              'voiceFile',
              await file.readAsBytes(),
              filename: path.basename(file.path),
              contentType: MediaType('audio', 'mp3'),
            ),
          );
        }

        final response = await request.send();
        final responseBody = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          final data = jsonDecode(responseBody);
          final result = data['result'];
          final characterId = result['characterId']as int?;  // String으로 변환
          final memberId = result['memberId'] as int?;
          final characterName = result['characterName'] as String;
          final voiceId = result['voiceId'] as String;

          // 이미지 아이템 업데이트
          setState(() {
            widget.imageItems[_currentIndex] = widget.imageItems[_currentIndex].copyWith(
              characterId: characterId,
              memberId: memberId,
              characterName: characterName,
              voiceId: voiceId,
              imagePath: _imagePath,
            );
          });

          Navigator.pop(context);
        } else {
          _showOverlayMessage(context, '서버 오류가 발생했습니다.');
        }
      } catch (e) {
        _showOverlayMessage(context, '네트워크 오류가 발생했습니다.');
      }
    } else {
      _showOverlayMessage(context, '이름과 음성 파일을 모두 입력해주세요.');
    }
  }

  void _showOverlayMessage(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.of(context).viewInsets.bottom + 50,
        left: 0,
        right: 0,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.pink,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(140.0),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          flexibleSpace: Padding(
            padding: const EdgeInsets.only(top: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: SvgPicture.asset('assets/icon_eut.svg', height: 80),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '수정하기',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: ScreenTypeLayout(
        mobile: _buildContent(),
        tablet: _buildContent(),
        desktop: _buildContent(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _submitEdit,
        child: Icon(Icons.save),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onImageChanged,
              itemCount: _imagePaths.length,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.pink[50],
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Center(
                    child: Image.asset(
                      _imagePaths[index],
                      fit: BoxFit.cover,
                      width: 350,
                      height: 350,
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 16),
          GestureDetector(
            onTap: _editName,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit, color: Colors.black),
                SizedBox(width: 8),
                Text('이름: $_name', style: TextStyle(fontSize: 18)),
              ],
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  _audioFilePath != null ? Icons.play_arrow : Icons.play_disabled,
                  color: _audioFilePath != null ? Colors.red : Colors.grey,
                ),
                onPressed: _playAudio,
              ),
              SizedBox(width: 16),
              ElevatedButton(
                onPressed: _openVoiceRecordWidget,
                child: Text('목소리 녹음'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class VoiceRecordWidget extends StatefulWidget {
  final ValueChanged<String> onAudioFilePathUpdated;

  const VoiceRecordWidget({Key? key, required this.onAudioFilePathUpdated}) : super(key: key);

  @override
  _VoiceRecordWidgetState createState() => _VoiceRecordWidgetState();
}

class _VoiceRecordWidgetState extends State<VoiceRecordWidget> {
  bool isRecording = false;
  bool isRecorded = false;
  int recordedTime = 0;
  late Timer timer;
  late String _recordingFilePath;

  void startRecording() {
    setState(() {
      isRecording = true;
      isRecorded = false;
      recordedTime = 0;
    });
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (recordedTime >= 30) {
        stopRecording();
      } else {
        setState(() {
          recordedTime++;
        });
      }
    });
  }

  void stopRecording() {
    timer.cancel();
    setState(() {
      isRecording = false;
      isRecorded = true;
    });
    _saveRecording();
  }

  void resetRecording() {
    setState(() {
      isRecording = false;
      isRecorded = false;
      recordedTime = 0;
    });
  }

  Future<void> _saveRecording() async {
    final directory = Directory.systemTemp;
    final file = File('${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav');
    await file.writeAsBytes(List.generate(100, (index) => index));
    setState(() {
      _recordingFilePath = file.path;
    });
    widget.onAudioFilePathUpdated(file.path);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('녹음 파일이 저장되었습니다: ${file.path}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '목소리 녹음',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: isRecording || isRecorded ? Colors.red[100] : Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '00:${recordedTime.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('취소', style: TextStyle(color: Colors.red, fontSize: 18)),
              ),
              if (isRecording)
                FloatingActionButton(
                  onPressed: stopRecording,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.stop, size: 30),
                ),
              if (!isRecording && !isRecorded)
                FloatingActionButton(
                  onPressed: startRecording,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.mic, size: 30),
                ),
              if (!isRecording && isRecorded)
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.red),
                  onPressed: resetRecording,
                ),
              IconButton(
                icon: Icon(Icons.send, color: (isRecorded || isRecording) ? Colors.red : Colors.grey),
                onPressed: () {
                  // 녹음 파일 저장 기능 추가
                },
              ),
            ],
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
