import 'package:flutter/material.dart';
import 'package:frontend/providers/makeTeam_provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:frontend/models/makeTeam_modal.dart';

class MakeTeamPage extends StatefulWidget {
  const MakeTeamPage({super.key});

  @override
  State<MakeTeamPage> createState() => _MakeTeamPageState();
}

class _MakeTeamPageState extends State<MakeTeamPage> {
  int selectedPeopleCount = -1; // 선택된 인원 수를 저장하는 변수
  List<String> selectedFields = []; // 선택된 희망 분야를 저장하는 리스트
  DateTime? selectedEndDate; // 선택된 모집 종료 기간을 저장하는 변수

  final TextEditingController _titleController =
      TextEditingController(); // 제목 텍스트 제어하는 컨트롤러
  final TextEditingController _contentController =
      TextEditingController(); // 내용 텍스트 제어하는 컨트롤러
  final TextEditingController _chatUrlController =
      TextEditingController(); // 오픈채팅 URL 텍스트 제어하는 컨트롤러
  final FocusNode _titleFocusNode = FocusNode(); // 포커스 노드

  ValueNotifier<bool> isButtonEnabled =
      ValueNotifier(false); // 버튼 활성화 상태를 관리하는 변수
  ValueNotifier<bool> isChatUrlValid =
      ValueNotifier(false); // 오픈채팅 URL 유효성 상태를 관리하는 변수

  // 글 제목에서 대괄호([]) 안의 경진대회 이름을 추출하는 함수
  String _parseCompetitionName(String title) {
    // 대괄호 안의 내용을 추출하는 정규 표현식을 정의
    final RegExp regExp = RegExp(
      r'\[(.*?)\]',
      caseSensitive: false, // 대소문자 구분 없이 매칭
    );

    // 정규 표현식과 일치하는 첫 번째 부분을 찾음
    final match = regExp.firstMatch(title);

    // 일치하는 부분이 있으면 대괄호 안의 텍스트를 반환, 없으면 빈 문자열 반환
    if (match != null) {
      return match.group(1)?.trim() ?? ''; // 대괄호 안의 문자열을 반환하며, 공백 제거
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    _titleController
        .addListener(_validateInputs); // 제목 텍스트 변경 시 _validateInputs 호출
    _contentController
        .addListener(_validateInputs); // 내용 텍스트 변경 시 _validateInputs 호출
    _chatUrlController
        .addListener(_validateInputs); // 오픈채팅 URL 텍스트 변경 시 _validateInputs 호출
    _titleFocusNode
        .addListener(_handleTitleFocus); // 포커스 노드 변경 시 _handleTitleFocus 호출
  }

  @override
  void dispose() {
    _titleController.removeListener(_validateInputs);
    _contentController.removeListener(_validateInputs);
    _chatUrlController.removeListener(_validateInputs);
    _titleFocusNode.removeListener(_handleTitleFocus);
    _titleController.dispose();
    _contentController.dispose();
    _chatUrlController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  void _validateInputs() {
    // 제목, 내용, 오픈채팅 URL이 비어있지 않은지 확인하여 버튼 활성화 상태 업데이트
    isButtonEnabled.value = _titleController.text.isNotEmpty &&
        _contentController.text.isNotEmpty &&
        _chatUrlController.text.isNotEmpty;

    // 오픈채팅 URL이 유효한지 확인하여 상태 업데이트
    isChatUrlValid.value = _chatUrlController.text.isNotEmpty;
  }

  // 제목 입력 필드가 포커스를 받을 때 대괄호([])를 자동으로 추가하는 함수
  void _handleTitleFocus() {
    // 제목 입력 필드가 포커스를 가지고 있고, 텍스트가 비어 있는지 확인
    if (_titleFocusNode.hasFocus && _titleController.text.isEmpty) {
      setState(() {
        // 텍스트 필드에 대괄호([])를 추가
        _titleController.text = '[]';
        // 커서를 대괄호 안으로 이동
        _titleController.selection = TextSelection.fromPosition(
          const TextPosition(offset: 1),
        );
      });
    }
  }

  // 날짜 선택기 함수
  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2010),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedEndDate) {
      setState(() {
        selectedEndDate = picked;
      });
    }
  }

  // 오픈채팅 URL을 자동으로 생성하는 함수
  void _generateChatUrl() {
    const baseUrl = 'https://open.kakao.com/o/';
    final chatUrl = '$baseUrl${_chatUrlController.text}';

    setState(() {
      _chatUrlController.text = chatUrl;
    });

    _validateInputs();
  }

  // 오픈채팅방 링크 열기 함수
  void _launchChatUrl() async {
    final chatUrl = _chatUrlController.text;
    final url = Uri.parse(chatUrl);

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $chatUrl';
    }
  }

  // 인원 수 버튼을 생성하는 위젯
  Widget _buildPeopleCountButton(int count) {
    bool isSelected = selectedPeopleCount == count;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPeopleCount = count;
        });
      },
      child: Container(
        height: 20,
        width: 70,
        decoration: BoxDecoration(
          color: const Color(0xFFDBE7FB),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            '$count명',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.black : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  // 희망 분야 버튼을 생성하는 위젯
  Widget _buildFieldButton(String field) {
    bool isSelected = selectedFields.contains(field);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedFields.remove(field);
          } else {
            selectedFields.add(field);
          }
        });
      },
      child: Container(
        height: 20,
        width: 90,
        decoration: BoxDecoration(
          color: const Color(0xFFDBE7FB),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            field,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.black : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MakeTeamProvider(),
      child: Scaffold(
        appBar: AppBar(
          scrolledUnderElevation: 0,
          toolbarHeight: 70,
          leading: Padding(
            padding: const EdgeInsets.only(right: 40.0),
            child: IconButton(
              icon: const Icon(
                Icons.close,
                size: 30,
                color: Colors.black,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          leadingWidth: 120,
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: Icon(
                Icons.add_alert,
                size: 30,
                color: Colors.black,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: Icon(
                Icons.account_circle,
                size: 30,
                color: Colors.black,
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '경진대회 팀원 모집',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '필요한 조건을 선택해 주세요',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            height: 20,
                            width: 60,
                            margin: const EdgeInsets.only(left: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A72E7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Center(
                              child: Text(
                                '수정',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            height: 20,
                            width: 60,
                            margin: const EdgeInsets.only(left: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEA4E44),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Center(
                              child: Text(
                                '삭제',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  '인원 수',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildPeopleCountButton(1),
                    const SizedBox(width: 6),
                    _buildPeopleCountButton(2),
                    const SizedBox(width: 6),
                    _buildPeopleCountButton(3),
                    const SizedBox(width: 6),
                    _buildPeopleCountButton(4),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text(
                      '희망 분야 ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // 검색 아이콘을 클릭했을 때 실행할 코드
                      },
                      child: const Row(
                        children: [
                          Icon(
                            Icons.search,
                            size: 15,
                            color: Colors.black54,
                          ),
                          SizedBox(width: 2),
                          Text(
                            '검색 ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFieldButton('백엔드'),
                      const SizedBox(width: 6),
                      _buildFieldButton('프론트'),
                      const SizedBox(width: 6),
                      _buildFieldButton('DevOps'),
                      const SizedBox(width: 6),
                      _buildFieldButton('데이터 엔지니어'),
                      const SizedBox(width: 6),
                      _buildFieldButton('AI'),
                      const SizedBox(width: 6),
                      _buildFieldButton('SRE'),
                      const SizedBox(width: 6),
                      _buildFieldButton('QA'),
                      const SizedBox(width: 6),
                      _buildFieldButton('Security'),
                      const SizedBox(width: 6),
                      _buildFieldButton('IoT'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '모집 종료 기간',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const Text(
                  '모집 기간 설정해주세요',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _selectEndDate(context),
                      child: Container(
                        height: 20,
                        width: 90,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDBE7FB),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '종료 기간 선택',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: selectedEndDate != null
                                  ? Colors.black
                                  : Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      selectedEndDate != null
                          ? '${selectedEndDate!.year}.${selectedEndDate!.month}.${selectedEndDate!.day}'
                          : '날짜를 선택해주세요',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  '카카오톡 오픈채팅방 링크',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const Text(
                  '오픈채팅방 링크 설정해주세요',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatUrlController,
                        maxLines: 1,
                        decoration: const InputDecoration(
                          hintText: '생성할 오픈채팅방 이름 입력해주세요',
                          hintStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFC5C5C7),
                          ),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.link),
                      onPressed: _generateChatUrl,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _launchChatUrl,
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBE7FB),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: ValueListenableBuilder<bool>(
                        valueListenable: isChatUrlValid,
                        builder: (context, isValid, child) {
                          return Text(
                            '생성된 오픈채팅 링크 열어보기',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isValid ? Colors.black : Colors.black54,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  '글 쓰기',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const Text(
                  '자유롭게 작성해주세요',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _titleController,
                  focusNode: _titleFocusNode,
                  maxLines: 1,
                  decoration: const InputDecoration(
                    hintText: '[] 제목을 작성해주세요',
                    hintStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC5C5C7),
                    ),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _contentController,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: '내용을 작성해주세요',
                    hintStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC5C5C7),
                    ),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        bottomNavigationBar: ValueListenableBuilder<bool>(
          valueListenable: isButtonEnabled,
          builder: (context, isEnabled, child) {
            return GestureDetector(
              onTap: isEnabled
                  ? () async {
                      String competitionName =
                          _parseCompetitionName(_titleController.text);
                      if (competitionName.isNotEmpty) {
                        print('경진대회 이름: $competitionName');
                      }

                      MakeTeam makeTeam = MakeTeam(
                        recruitmentCategory: competitionName,
                        recruitmentTitle: _titleController.text,
                        recruitmentContent: _contentController.text,
                        studentCount: selectedPeopleCount,
                        hopeField: selectedFields.join(', '),
                        kakaoUrl: _chatUrlController.text,
                        recruitmentStatus: true,
                        endTime: selectedEndDate != null
                            ? DateFormat("yyyy-MM-dd'T'HH:mm:ss")
                                .format(selectedEndDate!)
                            : '',
                        announcementId: 1, // 공지글 작성 API 완료 후 공지글 ID 추출 후 집어넣기
                      );

                      await context
                          .read<MakeTeamProvider>()
                          .createMakeTeam(makeTeam);

                      // Navigator.pop(context);
                    }
                  : null,
              child: Container(
                color: isEnabled ? const Color(0xFFACC7F1) : Colors.grey,
                height: 76,
                alignment: Alignment.center,
                child: const Text(
                  '작성 완료',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
