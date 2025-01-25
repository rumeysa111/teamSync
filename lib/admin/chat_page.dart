import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/firebase_api.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Ekipler için
  Map<String, String> teams = {}; // Ekip adı -> teamId
  List<String> _selectedTeams = [];

  // Kullanıcılar için
  Map<String, String> users = {}; // Kullanıcı adı -> userId
  List<String> _selectedUsers = [];

  final FirebaseApi _firebaseApi = FirebaseApi();

  String? adminId;
  String? teamId;


  bool _isSendingToTeams = true; // Varsayılan olarak ekiplere gönderim
  bool _isSendingToUsers = false;

  @override
  void initState() {
    super.initState();
    _fetchTeams();
    _fetchUsers();
  }

  // Ekiplerin isimlerini ve teamId'lerini Firestore'dan çekiyoruz
  void _fetchTeams() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    adminId = prefs.getString('adminId');
    print('Admin ID: $adminId');

    if (adminId != null) {
      final teamsSnapshot = await FirebaseFirestore.instance
          .collection('ekipler')
          .where('adminId', isEqualTo: adminId)
          .get();

      setState(() {
        teams = {
          for (var doc in teamsSnapshot.docs)
            doc['ad']: doc.id // 'ad' -> teamId (doc.id)
        };
      });
    } else {
      print('Admin ID bulunamadı');
    }
  }

  // Kullanıcıların isimlerini ve userId'lerini Firestore'dan çekiyoruz
  void _fetchUsers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    adminId = prefs.getString('adminId');
    print('Admin ID: $adminId');

    if (adminId != null) {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('adminId', isEqualTo: adminId)
          .get();

      setState(() {
        users = {
          for (var doc in usersSnapshot.docs)
            doc['username']: doc.id // 'username' -> userId (doc.id)
        };
      });
    } else {
      print('Admin ID bulunamadı');
    }
  }

  // Cihaz tokenlarını ekiplere göre çekme fonksiyonu
  Future<List<String>> _fetchDeviceTokensForTeams(List<String> teams) async {
    List<String> deviceTokens = [];

    try {
      // 'whereIn' sorgusu ile tüm takımlardan kullanıcıları çekiyoruz
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('team', whereIn: teams)
          .get();

      for (var doc in usersSnapshot.docs) {
        if (doc['token'] != null) {
          deviceTokens.add(doc['token']);
        }
      }
    } catch (e) {
      print('Cihaz tokenları alınırken bir hata oluştu: $e');
      // Kullanıcıya hata hakkında bilgi vermek için bir mekanizma ekleyebilirsiniz
    }

    return deviceTokens;
  }

  // Cihaz tokenlarını kullanıcılara göre çekme fonksiyonu
  Future<List<String>> _fetchDeviceTokensForUsers(List<String> userIds) async {
    List<String> deviceTokens = [];

    try {
      // 'whereIn' sorgusu ile seçilen kullanıcıların cihaz token'larını çekiyoruz
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: userIds)
          .get();

      for (var doc in usersSnapshot.docs) {
        if (doc['token'] != null) {
          deviceTokens.add(doc['token']);
        }
      }
    } catch (e) {
      print('Cihaz tokenları alınırken bir hata oluştu: $e');
      // Kullanıcıya hata hakkında bilgi vermek için bir mekanizma ekleyebilirsiniz
    }

    return deviceTokens;
  }

  // Mesajı Firestore'a kaydetme ve bildirim gönderme fonksiyonu
  Future<void> _addMessage() async {
    String message = _messageController.text.trim();

    if (message.isEmpty || adminId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mesaj ve adminId zorunludur')),
      );
      return;
    }

    Map<String, dynamic> messageData = {
      'message': message,
      'createdAt': Timestamp.now(),
      'adminId': adminId,
      'teamId': teamId,
    };

    try {
      List<String> deviceTokens = [];
      String title = 'Yeni Mesaj';
      String description = message;

      if (_isSendingToTeams && _selectedTeams.isNotEmpty) {
        // Seçilen takımların ID'lerini alıyoruz
        List<String> selectedTeamIds =
        _selectedTeams.map((teamName) => teams[teamName]!).toList();
        messageData['selectedTeams'] = selectedTeamIds;

        // Takımlara ait cihaz tokenlarını çekiyoruz
        deviceTokens = await _fetchDeviceTokensForTeams(_selectedTeams);
      } else if (_isSendingToUsers && _selectedUsers.isNotEmpty) {
        // Seçilen kullanıcıların ID'lerini alıyoruz
        List<String> selectedUserIds =
        _selectedUsers.map((username) => users[username]!).toList();
        messageData['selectedUsers'] = selectedUserIds;

        // Kullanıcılara ait cihaz tokenlarını çekiyoruz
        deviceTokens = await _fetchDeviceTokensForUsers(selectedUserIds);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Seçim yapmanız gerekiyor')),
        );
        return;
      }

      // Bildirim gönder
      if (deviceTokens.isNotEmpty) {
        await _firebaseApi.sendNotification(deviceTokens, title, description);
      } else {
        print('Bildirim göndermek için hiç cihaz tokenı bulunamadı.');
      }

      // Mesajı Firestore'a ekle
      await FirebaseFirestore.instance.collection('messages').add(messageData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mesaj başarıyla gönderildi')),
      );

      _messageController.clear();
      setState(() {
        _selectedTeams.clear();
        _selectedUsers.clear();
      });

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 60,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );

    } catch (e) {
      print('Mesaj eklenirken bir hata oluştu: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mesaj gönderilirken bir hata oluştu')),
      );
      // Kullanıcıya hata hakkında bilgi vermek için bir mekanizma ekleyebilirsiniz
    }
  }

  // Widget to build each message bubble
  // Widget to build each message bubble
// Widget to build each message bubble
// Widget to build each message bubble
  Widget _buildMessageBubble(Message message) {
    bool isAdminMessage = message.adminId == adminId; // Mesajın adminden gelip gelmediğini kontrol et

    // Eğer mesaj adminden değilse, hiçbir şey göstermeyin
    if (!isAdminMessage) {
      return SizedBox.shrink(); // Boş widget
    }

    String target = '';
    if (message.selectedTeams != null && message.selectedTeams!.isNotEmpty) {
      // Ekip isimlerini teamIds'den geri almak için
      List<String> teamNames = message.selectedTeams!.map((teamId) {
        final entry = teams.entries.firstWhere(
              (entry) => entry.value == teamId,
          orElse: () => MapEntry('Bilinmeyen Ekip', ''),
        );
        return entry.key;
      }).toList();
      target = 'Ekipler: ${teamNames.join(', ')}';
    } else if (message.selectedUsers != null && message.selectedUsers!.isNotEmpty) {
      // Kullanıcı isimlerini userIds'den geri almak için
      List<String> userNames = message.selectedUsers!.map((userId) {
        final entry = users.entries.firstWhere(
              (entry) => entry.value == userId,
          orElse: () => MapEntry('Bilinmeyen Kullanıcı', ''),
        );
        return entry.key;
      }).toList();
      target = 'Kullanıcılar: ${userNames.join(', ')}';
    } else {
      target = 'Genel';
    }

    return Align(
      alignment: Alignment.centerRight, // Mesajları sağa hizala
      child: Row(
        mainAxisSize: MainAxisSize.min, // Sadece gerekli kadar alan kapla
        children: [
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              margin: EdgeInsets.symmetric(vertical: 5, horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.green[300], // Admin mesaj rengi
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end, // Metinleri sağa hizala
                children: [
                  Text(
                    message.message,
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  SizedBox(height: 5),
                  Text(
                    target,
                    style: TextStyle(fontSize: 12, color: Colors.black54),
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
          SizedBox(width: 8),
          CircleAvatar(
            backgroundImage: AssetImage('assets/avatar.png'), // Admin avatarı
            radius: 16,
          ),
        ],
      ),
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
        title: Text('Chat Page'),
        backgroundColor: Colors.green[700],
      ),
      body: Column(
        children: [
          // Butonlar için yeni bir satır ekleyelim
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isSendingToTeams = true;
                      _isSendingToUsers = false;
                      _selectedUsers.clear();
                    });
                    _selectTeams();
                  },
                  child: Text('Ekiplere Gönder'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSendingToTeams ? Colors.green : Colors.grey,
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isSendingToUsers = true;
                      _isSendingToTeams = false;
                      _selectedTeams.clear();
                    });
                    _selectUsers();
                  },
                  child: Text('Kullanıcılara Gönder'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSendingToUsers ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          // Seçilen Ekip ve Kullanıcıları Gösterme
          if (_selectedTeams.isNotEmpty || _selectedUsers.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Seçilen Ekipler
                  ..._selectedTeams.map((team) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Chip(
                        label: Text(team),
                        deleteIcon: Icon(Icons.close),
                        onDeleted: () {
                          setState(() {
                            _selectedTeams.remove(team);
                          });
                        },
                        backgroundColor: Colors.green[200],
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  // Seçilen Kullanıcılar
                  ..._selectedUsers.map((user) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Chip(
                        label: Text(user),
                        deleteIcon: Icon(Icons.close),
                        onDeleted: () {
                          setState(() {
                            _selectedUsers.remove(user);
                          });
                        },
                        backgroundColor: Colors.blue[200],
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
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

                List<Message> messages = snapshot.data!.docs
                    .map((doc) => Message.fromDocument(doc))
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
          _buildInputArea(),
        ],
      ),
    );
  }

  // Input area resembling WhatsApp's input bar
  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ekip veya kullanıcı seçimleri
          Row(
            children: [

              // Expanded message input field
              Expanded(
                child: TextField(
                  controller: _messageController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Mesajınızı yazın...',
                    border: InputBorder.none,
                  ),
                ),
              ),
              // Send button
              IconButton(
                icon: Icon(Icons.send, color: Colors.green[700]),
                onPressed: _addMessage,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Ekip seçimi için bir dialog
  Future<void> _selectTeams() async {
    final selected = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        List<String> tempSelected = List.from(_selectedTeams);
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Ekip Seçin'),
              content: Container(
                width: double.maxFinite,
                child: teams.isNotEmpty
                    ? ListView(
                  children: teams.keys.map((teamName) {
                    return CheckboxListTile(
                      title: Text(teamName),
                      value: tempSelected.contains(teamName),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            tempSelected.add(teamName);
                          } else {
                            tempSelected.remove(teamName);
                          }
                        });
                      },
                    );
                  }).toList(),
                )
                    : Text('Hiç ekip bulunamadı.'),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, tempSelected);
                  },
                  child: Text('Seç'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedTeams = selected;
      });
    }
  }

  // Kullanıcı seçimi için bir dialog
  Future<void> _selectUsers() async {
    final selected = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        List<String> tempSelected = List.from(_selectedUsers);
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Kullanıcı Seçin'),
              content: Container(
                width: double.maxFinite,
                child: users.isNotEmpty
                    ? ListView(
                  children: users.keys.map((username) {
                    return CheckboxListTile(
                      title: Text(username),
                      value: tempSelected.contains(username),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            tempSelected.add(username);
                          } else {
                            tempSelected.remove(username);
                          }
                        });
                      },
                    );
                  }).toList(),
                )
                    : Text('Hiç kullanıcı bulunamadı.'),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, tempSelected);
                  },
                  child: Text('Seç'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedUsers = selected;
      });
    }
  }
}

// Mesaj modelini güncelledik
class Message {
  final String id;
  final String message;
  final String adminId;
  final List<String>? selectedTeams;
  final List<String>? selectedUsers;
  final Timestamp createdAt;
  final  String? teamId;


  Message({
    required this.id,
    required this.message,
    required this.adminId,
    this.selectedTeams,
    this.selectedUsers,
    required this.createdAt,
    this.teamId,


  });


  factory Message.fromDocument(DocumentSnapshot doc) {
    return Message(
      id: doc.id,
      message: doc['message'],
      adminId: doc['adminId'],
      teamId: doc['teamId'] ?? '',

      selectedTeams: doc.data().toString().contains('selectedTeams')
          ? List<String>.from(doc['selectedTeams'])
          : null,
      selectedUsers: doc.data().toString().contains('selectedUsers')
          ? List<String>.from(doc['selectedUsers'])
          : null,
      createdAt: doc['createdAt'],
    );
  }
}
