import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/firebase_api.dart';

class EmployeeChatPage extends StatefulWidget {
  @override
  _EmployeeChatPageState createState() => _EmployeeChatPageState();
}

class _EmployeeChatPageState extends State<EmployeeChatPage> {
  final ScrollController _scrollController = ScrollController();

  // Kullanıcılar için
  Map<String, String> users = {}; // Kullanıcı adı -> userId
  String? currentUserId; // Şu anki kullanıcı ID'si
  String? currentTeamId; // Şu anki takım ID'si

  final FirebaseApi _firebaseApi = FirebaseApi();

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserId();
    _fetchUsers();
    _fetchCurrentTeamId();
  }

  // Şu anki kullanıcı ID'sini al
  void _fetchCurrentUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId = prefs.getString('userId'); // Giriş sırasında kaydedilmiş userId
    });
    print('Current User ID: $currentUserId');
  }

  // Şu anki kullanıcının takım ID'sini al
  void _fetchCurrentTeamId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currentTeamId = prefs.getString('teamId'); // Giriş sırasında kaydedilmiş teamId
    });
    print('Current Team ID: $currentTeamId');
  }

  // Kullanıcıların isimlerini ve userId'lerini Firestore'dan çekiyoruz
  void _fetchUsers() async {
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .get();

    setState(() {
      users = {
        for (var doc in usersSnapshot.docs)
          doc['username']: doc.id // 'username' -> userId (doc.id)
      };
    });
  }

  Widget _buildMessageBubble(Message message) {
    bool isMe = message.teamId == currentTeamId;

    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                backgroundImage: AssetImage('assets/avatar.png'),
                radius: 16,
              ),
              SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                margin: EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                decoration: BoxDecoration(
                  color: isMe ? Colors.blue[300] : Colors.grey[300],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                    bottomLeft: isMe ? Radius.circular(15) : Radius.circular(0),
                    bottomRight: isMe ? Radius.circular(0) : Radius.circular(15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.message,
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    SizedBox(height: 5),
                    Text(
                      _formatTimestamp(message.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
            if (isMe) ...[
              SizedBox(width: 8),
              CircleAvatar(
                backgroundImage: AssetImage('assets/avatar.png'),
                radius: 16,
              ),
            ],
          ],
        ),
      ],
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Çalışan Mesajları'),
        backgroundColor: Colors.blue[700],


      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Hata oluştu: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                // Mesajları teamId'ye göre filtreleyin
                List<Message> messages = snapshot.data!.docs
                    .map((doc) => Message.fromDocument(doc))
                    .where((message) => message.teamId.isNotEmpty && message.teamId == currentTeamId)// teamId'ye göre filtre
                    .toList();

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(messages[index]);
                  },
                );
              },
            ),
          ),
          Divider(height: 1),
        ],
      ),
    );
  }
}

// Mesaj modelini güncelledik
class Message {
  final String id;
  final String message;
  final String adminId; // Mevcut alan
  final String teamId; // Takım ID'si alanı eklendi
  final Timestamp createdAt;

  Message({
    required this.id,
    required this.message,
    required this.adminId,
    required this.teamId,
    required this.createdAt,
  });

  factory Message.fromDocument(DocumentSnapshot doc) {
    return Message(
      id: doc.id,
      message: doc['message'],
      adminId: doc['adminId'],
      teamId: doc.get('teamId') ?? '', // Eğer 'teamId' yoksa boş bir değer ata
      createdAt: doc['createdAt'],
    );
  }

}
