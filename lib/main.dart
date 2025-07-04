
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  await FirebaseAuth.instance.signOut();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '귀여운 다이어리',
      theme: ThemeData(
        fontFamily: 'NanumGothic',
        scaffoldBackgroundColor: Color(0xFFF0F8FF),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF64B5F6),
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Color(0xFFBBDEFB)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber[200],
            foregroundColor: Colors.black87,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ),
      home: StartScreen(),
    );
  }
}

class StartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF64B5F6), Color(0xFFE3F2FD)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '너와 나의 다이어리',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: Text('시작하기'),
            ),
          ],
        ),
      ),
    );
  }
}


class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LoginPage();
  }
}

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLogin = true;

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email, password: password);
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email, password: password);
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("오류: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? '로그인' : '회원가입')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: '이메일'),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: '비밀번호'),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _handleAuth,
              child: Text(_isLogin ? "로그인" : "회원가입"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _isLogin = !_isLogin;
                });
              },
              child: Text(_isLogin
                  ? "계정이 없으신가요? 회원가입"
                  : "이미 계정이 있으신가요? 로그인"),
            )
          ],
        ),
      ),
    );
  }
}


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    SchedulePage(),
    SecureDiaryPage(),
    GroupDiaryPage(),
    GroupSchedulePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue[400],
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: '일정'),
          BottomNavigationBarItem(icon: Icon(Icons.lock), label: '개인 다이어리'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: '단체 다이어리'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: '단체 일정'),
        ],
      ),
    );
  }
}

// 📅 SchedulePage - 개인 일정 탭
class SchedulePage extends StatefulWidget {
  @override
  _SchedulePageState createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final _firestore = FirebaseFirestore.instance;
  final _controller = TextEditingController();
  final _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  DateTime _selectedDay = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  List<Map<String, dynamic>> _todos = [];

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  void _loadTodos() async {
    final snapshot = await _firestore
        .collection('todos')
        .where('userId', isEqualTo: _userId)
        .get();
    setState(() {
      _todos = snapshot.docs.map((doc) => {
        'text': doc['text'],
        'datetime': (doc['datetime'] as Timestamp).toDate(),
        'id': doc.id,
      }).toList();
    });
  }

  void _addTodo() async {
    if (_controller.text.isEmpty) return;

    final dateTime = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final doc = await _firestore.collection('todos').add({
      'text': _controller.text,
      'datetime': dateTime,
      'userId': _userId,
    });

    setState(() {
      _todos.add({'text': _controller.text, 'datetime': dateTime, 'id': doc.id});
      _controller.clear();
    });
  }

  void _deleteTodo(String id) async {
    await _firestore.collection('todos').doc(id).delete();
    setState(() {
      _todos.removeWhere((todo) => todo['id'] == id);
    });
  }

  void _editTodo(Map<String, dynamic> todo) {
    final editController = TextEditingController(text: todo['text']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("일정 수정"),
        content: TextField(
          controller: editController,
          decoration: InputDecoration(labelText: "수정할 내용"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("취소")),
          TextButton(
            onPressed: () async {
              final newText = editController.text.trim();
              if (newText.isNotEmpty) {
                await _firestore.collection('todos').doc(todo['id']).update({
                  'text': newText,
                });
                setState(() {
                  todo['text'] = newText;
                });
              }
              Navigator.pop(context);
            },
            child: Text("수정"),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getTodosForSelectedDate() {
    return _todos.where((todo) {
      final d = todo['datetime'];
      return d.year == _selectedDay.year &&
          d.month == _selectedDay.month &&
          d.day == _selectedDay.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("📅 내 일정")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _selectedDay,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              onDaySelected: (selected, focused) => setState(() => _selectedDay = selected),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(labelText: "일정 내용"),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.access_time),
                  onPressed: () async {
                    final time = await showTimePicker(context: context, initialTime: _selectedTime);
                    if (time != null) setState(() => _selectedTime = time);
                  },
                ),
              ],
            ),
            ElevatedButton(onPressed: _addTodo, child: Text("추가")),
            Expanded(
              child: ListView(
                children: _getTodosForSelectedDate().map((todo) {
                  return ListTile(
                    title: Text(todo['text']),
                    subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(todo['datetime'])),
                    onTap: () => _editTodo(todo),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_forever, color: Colors.red),
                      onPressed: () => _deleteTodo(todo['id']),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🔐 SecureDiaryPage - 개인 다이어리
class SecureDiaryPage extends StatefulWidget {
  @override
  _SecureDiaryPageState createState() => _SecureDiaryPageState();
}

class _SecureDiaryPageState extends State<SecureDiaryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _entryController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();
  final TextEditingController _newPwController = TextEditingController();
  DateTime? _selectedDate;

  List<Map<String, dynamic>> _entries = [];
  bool _unlocked = false;

  String _savedPassword = '';
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _loadPassword();
  }

  Future<void> _loadPassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _userId = user.uid;

    final doc = await _firestore.collection('diary_passwords').doc(_userId).get();
    setState(() {
      _savedPassword = doc.exists ? doc['password'] ?? '' : '';
    });
  }

  Future<void> _loadEntries() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _userId = user.uid;

    Query query = _firestore
        .collection('secure_diary')
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true);

    if (_selectedDate != null) {
      final start = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
      final end = start.add(Duration(days: 1));
      query = query
          .where('createdAt', isGreaterThanOrEqualTo: start)
          .where('createdAt', isLessThan: end);
    }

    final snapshot = await query.get();
    print("불러온 항목 개수: \${snapshot.docs.length}");
    for (var doc in snapshot.docs) {
      print("문서 내용: \${doc.data()}");
    }
    print("------ Loaded Entries ------");
    print(snapshot.docs.length);
    for (var doc in snapshot.docs) {
      print(doc.data());
    }
    setState(() {
      _entries = snapshot.docs.map((doc) => {
        'text': doc['text'],
        'createdAt': (doc['createdAt'] as Timestamp).toDate(),
        'id': doc.id,
      }).toList();
    });
  }

  void _addEntry() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _userId = user.uid;

    if (_entryController.text.trim().isEmpty) return;

    await _firestore.collection('secure_diary').add({
      'text': _entryController.text,
      'createdAt': DateTime.now(),
      'userId': _userId,
    });

    _entryController.clear();
    _loadEntries();
  }

  void _editEntry(String id, String newText) async {
    await _firestore.collection('secure_diary').doc(id).update({'text': newText});
    _loadEntries();
  }

  void _deleteEntry(String id) async {
    await _firestore.collection('secure_diary').doc(id).delete();
    _loadEntries();
  }

  void _changePassword() async {
    if (_newPwController.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _userId = user.uid;

    await _firestore.collection('diary_passwords').doc(_userId).set({
      'password': _newPwController.text.trim(),
    });

    setState(() {
      _savedPassword = _newPwController.text.trim();
      _newPwController.clear();
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('비밀번호가 변경되었습니다.')));
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('비밀번호 변경'),
        content: TextField(
          controller: _newPwController,
          obscureText: true,
          decoration: InputDecoration(labelText: '새 비밀번호 입력'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _changePassword();
            },
            child: Text('변경'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🔒 개인 다이어리'),
      ),
      body: _unlocked
          ? Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _entryController,
                    decoration: InputDecoration(labelText: '오늘의 일기'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _addEntry,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                TextButton(
                  child: Text('📅 날짜 선택'),
                  onPressed: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                      _loadEntries();
                    }
                  },
                ),
                if (_selectedDate != null)
                  Text('${_selectedDate!.toLocal()}'.split(' ')[0]),
                Spacer(),
                if (_selectedDate != null)
                  IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      setState(() => _selectedDate = null);
                      _loadEntries();
                    },
                  )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton.icon(
              onPressed: _showChangePasswordDialog,
              icon: Icon(Icons.lock_reset),
              label: Text('비밀번호 변경'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final entry = _entries[index];
                return ListTile(
                  title: Text(entry['text']),
                  subtitle: Text(
                    '작성 시간: ${DateFormat('yyyy-MM-dd HH:mm').format(entry['createdAt'].toLocal())}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          TextEditingController editController =
                          TextEditingController(text: entry['text']);
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text('일기 수정'),
                              content: TextField(
                                controller: editController,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _editEntry(entry['id'], editController.text);
                                  },
                                  child: Text('수정'),
                                )
                              ],
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _deleteEntry(entry['id']),
                      )
                    ],
                  ),
                );
              },
            ),
          )
        ],
      )
          : Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('비밀번호를 입력하세요'),
              TextField(
                controller: _pwController,
                obscureText: true,
                decoration: InputDecoration(labelText: '비밀번호'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_pwController.text == _savedPassword) {
                    setState(() => _unlocked = true);
                    _loadEntries();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('비밀번호가 틀렸습니다')));
                  }
                },
                child: Text('열기'),
              )
            ],
          ),
        ),
      ),
    );
  }
}




// 👥 GroupDiaryPage - 이름 입력 및 참여 목록 추가 완료
class GroupDiaryPage extends StatefulWidget {
  @override
  _GroupDiaryPageState createState() => _GroupDiaryPageState();
}

class _GroupDiaryPageState extends State<GroupDiaryPage> {
  final _firestore = FirebaseFirestore.instance;
  final _entryController = TextEditingController();
  final _joinCodeController = TextEditingController();
  final _groupNameController = TextEditingController();
  final _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  String? _groupCode;
  String? _groupName;
  List<Map<String, dynamic>> _entries = [];
  List<Map<String, String>> _myGroupDiaries = [];

  @override
  void initState() {
    super.initState();
    _loadMyGroupDiaries();
  }
  Future<void> _leaveGroupDiary(String groupCode) async {
    await _firestore.collection('group_diaries').doc(groupCode).update({
      'members': FieldValue.arrayRemove([_userId])
    });

    if (_groupCode == groupCode) {
      setState(() => _groupCode = null); // 현재 들어가 있던 다이어리면 나감 처리
    }

    await _loadMyGroupDiaries(); // 참여 목록 갱신
  }


  Future<void> _loadMyGroupDiaries() async {
    final snapshot = await _firestore
        .collection('group_diaries')
        .where('members', arrayContains: _userId)
        .get();

    setState(() {
      _myGroupDiaries = snapshot.docs.map((doc) => {
        'name': doc['name'] as String,
        'code': doc.id as String,
      }).toList();
    });
  }

  Future<void> _generateGroupCode() async {
    final code = _generateRandomCode();
    final name = _groupNameController.text.trim();
    if (name.isEmpty) return;

    await _firestore.collection('group_diaries').doc(code).set({
      'createdBy': _userId,
      'members': [_userId],
      'name': name,
    });

    setState(() {
      _groupCode = code;
      _groupName = name;
    });
    _loadEntries();
    _loadMyGroupDiaries();
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(6, (index) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> _joinGroupDiary(String code) async {
    final doc = await _firestore.collection('group_diaries').doc(code).get();
    if (doc.exists) {
      await _firestore.collection('group_diaries').doc(code).update({
        'members': FieldValue.arrayUnion([_userId])
      });

      setState(() {
        _groupCode = code;
        _groupName = doc['name'];
      });

      _loadEntries();
      _loadMyGroupDiaries(); // 중요: 참여 목록 갱신
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("존재하지 않는 코드입니다")));
    }
  }

  Future<void> _loadEntries() async {
    if (_groupCode == null) return;
    final snapshot = await _firestore
        .collection('group_diaries')
        .doc(_groupCode!)
        .collection('entries')
        .orderBy('createdAt', descending: true)
        .get();
    setState(() {
      _entries = snapshot.docs.map((doc) => {
        'text': doc['text'],
        'authorId': doc['authorId'],
        'createdAt': (doc['createdAt'] as Timestamp).toDate(),
        'id': doc.id,
      }).toList();
    });
  }

  Future<void> _addEntry() async {
    if (_entryController.text.isEmpty || _groupCode == null) return;
    await _firestore.collection('group_diaries').doc(_groupCode).collection('entries').add({
      'text': _entryController.text,
      'authorId': _userId,
      'createdAt': DateTime.now(),
    });
    _entryController.clear();
    _loadEntries();
  }

  Future<void> _editEntry(Map<String, dynamic> entry) async {
    final controller = TextEditingController(text: entry['text']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("수정"),
        content: TextField(controller: controller, maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("취소")),
          TextButton(
            onPressed: () async {
              final newText = controller.text.trim();
              if (newText.isNotEmpty) {
                await _firestore.collection('group_diaries')
                    .doc(_groupCode)
                    .collection('entries')
                    .doc(entry['id'])
                    .update({'text': newText});
                setState(() => entry['text'] = newText);
              }
              Navigator.pop(context);
            },
            child: Text("저장"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEntry(String id) async {
    await _firestore.collection('group_diaries').doc(_groupCode).collection('entries').doc(id).delete();
    await _loadEntries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("👥 단체 다이어리")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _groupCode == null
            ? SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: _groupNameController, decoration: InputDecoration(labelText: "새 다이어리 이름(필수)")),
              ElevatedButton(onPressed: _generateGroupCode, child: Text("새 단체 다이어리 생성")),
              SizedBox(height: 20),
              TextField(controller: _joinCodeController, decoration: InputDecoration(labelText: "참여할 코드 입력")),
              ElevatedButton(onPressed: () => _joinGroupDiary(_joinCodeController.text.trim()), child: Text("참여하기")),
              SizedBox(height: 30),
              if (_myGroupDiaries.isNotEmpty) ...[
                Text("참여 중인 단체 다이어리", style: TextStyle(fontWeight: FontWeight.bold)),
                ..._myGroupDiaries.map((diary) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("- ${diary['name']} (코드: ${diary['code']})"),
                    TextButton(
                      onPressed: () => _leaveGroupDiary(diary['code']!),
                      child: Text("나가기", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ))
              ],
            ],
          ),
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("다이어리 이름: $_groupName"),
            Text("다이어리 코드: $_groupCode"),
            TextField(controller: _entryController, decoration: InputDecoration(labelText: "다이어리 내용")),
            ElevatedButton(onPressed: _addEntry, child: Text("작성")),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _entries.length,
                itemBuilder: (context, index) {
                  final e = _entries[index];
                  return ListTile(
                    title: Text(e['text']),
                    subtitle: Text("작성자: ${e['authorId']} | ${DateFormat('yyyy-MM-dd HH:mm').format(e['createdAt'])}"),
                    trailing: e['authorId'] == _userId
                        ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: Icon(Icons.edit, color: Colors.grey), onPressed: () => _editEntry(e)),
                        IconButton(icon: Icon(Icons.delete_forever, color: Colors.red), onPressed: () => _deleteEntry(e['id'])),
                      ],
                    )
                        : null,
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}



// 📅 GroupSchedulePage - 단체 일정
class GroupSchedulePage extends StatefulWidget {
  @override
  _GroupSchedulePageState createState() => _GroupSchedulePageState();
}

class _GroupSchedulePageState extends State<GroupSchedulePage> {
  final _firestore = FirebaseFirestore.instance;
  final _scheduleController = TextEditingController();
  final _joinCodeController = TextEditingController();
  final _groupNameController = TextEditingController();
  late String _userId;

  String? _groupCode;
  DateTime _selectedDay = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  List<Map<String, dynamic>> _schedules = [];
  List<Map<String, String>> _myGroupSchedules = [];

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (_groupCode != null) _loadSchedules();
    _loadMyGroupSchedules();
  }

  Future<void> _leaveGroupSchedule(String groupCode) async {
    await _firestore.collection('group_schedules').doc(groupCode).update({
      'members': FieldValue.arrayRemove([_userId])
    });

    if (_groupCode == groupCode) {
      setState(() => _groupCode = null); // 보고 있던 일정이면 초기화
    }

    await _loadMyGroupSchedules(); // 참여 목록 다시 불러오기
  }

  Future<void> _loadMyGroupSchedules() async {
    final snapshot = await _firestore
        .collection('group_schedules')
        .where('members', arrayContains: _userId)
        .get();

    setState(() {
      _myGroupSchedules = snapshot.docs
          .where((doc) => doc.data().containsKey('name')) // name 있는 문서만
          .map((doc) => {
        'name': doc['name'] as String,
        'code': doc.id,
      })
          .toList();
    });
  }
  void _generateGroupCode() async {
    final code = _generateRandomCode();
    final name = _groupNameController.text.trim();
    if (name.isEmpty) return;
    await _firestore.collection('group_schedules').doc(code).set({
      'createdBy': _userId,
      'members': [_userId],
      'name': name,
    });
    setState(() => _groupCode = code);
    _loadSchedules();
    _loadMyGroupSchedules();
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(6, (index) =>
    chars[rand.nextInt(chars.length)]).join();
  }

  void _joinGroupSchedule(String code) async {
    final doc = await _firestore.collection('group_schedules').doc(code).get();
    if (doc.exists) {
      await _firestore.collection('group_schedules').doc(code).update({
        'members': FieldValue.arrayUnion([_userId])
      });
      setState(() => _groupCode = code);
      _loadSchedules();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("존재하지 않는 코드입니다")));
    }
  }

  void _loadSchedules() async {
    if (_groupCode == null) return;
    final snapshot = await _firestore
        .collection('group_schedules')
        .doc(_groupCode)
        .collection('items')
        .orderBy('datetime', descending: true)
        .get();
    setState(() {
      _schedules = snapshot.docs.map((doc) => {
        'text': doc['text'],
        'datetime': (doc['datetime'] as Timestamp).toDate(),
        'authorId': doc['authorId'],
        'id': doc.id,
      }).toList();
    });
  }

  void _addSchedule() async {
    if (_scheduleController.text.isEmpty || _groupCode == null) return;
    final fullDateTime = DateTime(
        _selectedDay.year, _selectedDay.month, _selectedDay.day,
        _selectedTime.hour, _selectedTime.minute
    );
    await _firestore.collection('group_schedules').doc(_groupCode).collection('items').add({
      'text': _scheduleController.text,
      'datetime': fullDateTime,
      'authorId': _userId,
    });
    _scheduleController.clear();
    _loadSchedules();
  }

  void _editSchedule(Map<String, dynamic> schedule) async {
    final controller = TextEditingController(text: schedule['text']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("일정 수정"),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("취소")),
          TextButton(
            onPressed: () async {
              final newText = controller.text.trim();
              if (newText.isNotEmpty) {
                await _firestore.collection('group_schedules')
                    .doc(_groupCode)
                    .collection('items')
                    .doc(schedule['id'])
                    .update({'text': newText});
                setState(() => schedule['text'] = newText);
              }
              Navigator.pop(context);
            },
            child: Text("저장"),
          ),
        ],
      ),
    );
  }

  void _deleteSchedule(String id) async {
    await _firestore.collection('group_schedules').doc(_groupCode).collection('items').doc(id).delete();
    setState(() {
      _schedules.removeWhere((e) => e['id'] == id);
    });
  }

  List<Map<String, dynamic>> _getSchedulesForSelectedDate() {
    return _schedules.where((e) =>
    e['datetime'].year == _selectedDay.year &&
        e['datetime'].month == _selectedDay.month &&
        e['datetime'].day == _selectedDay.day
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("📅 단체 일정")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _groupCode == null
            ? Column(
          children: [
            TextField(
              controller: _groupNameController,
              decoration: InputDecoration(labelText: "새 일정 이름(필수)"),
            ),
            ElevatedButton(
              onPressed: _generateGroupCode,
              child: Text("새 단체 일정 생성"),
            ),
            SizedBox(height: 10),
            TextField(controller: _joinCodeController, decoration: InputDecoration(labelText: "참여할 코드 입력")),
            ElevatedButton(
              onPressed: () => _joinGroupSchedule(_joinCodeController.text.trim()),
              child: Text("참여하기"),
            ),
            if (_myGroupSchedules.isNotEmpty) ...[
              SizedBox(height: 30),
              Text("참여 중인 단체 일정", style: TextStyle(fontWeight: FontWeight.bold)),
              ..._myGroupSchedules.map((schedule) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("- ${schedule['name']} (코드: ${schedule['code']})"),
                  TextButton(
                    onPressed: () => _leaveGroupSchedule(schedule['code']!),
                    child: Text("나가기", style: TextStyle(color: Colors.red)),
                  ),
                ],
              )),

            ],

          ],
        )
            : Column(
          children: [
            Text("참여 코드: $_groupCode"),
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _selectedDay,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              onDaySelected: (selected, focused) => setState(() => _selectedDay = selected),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _scheduleController,
                    decoration: InputDecoration(labelText: "일정 내용"),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.access_time),
                  onPressed: () async {
                    final time = await showTimePicker(context: context, initialTime: _selectedTime);
                    if (time != null) setState(() => _selectedTime = time);
                  },
                ),
              ],
            ),
            ElevatedButton(onPressed: _addSchedule, child: Text("추가")),
            Expanded(
              child: ListView.builder(
                itemCount: _getSchedulesForSelectedDate().length,
                itemBuilder: (context, index) {
                  final e = _getSchedulesForSelectedDate()[index];
                  return ListTile(
                    title: Text(e['text']),
                    subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(e['datetime'])),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: Icon(Icons.edit), onPressed: () => _editSchedule(e)),
                        IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteSchedule(e['id'])),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
