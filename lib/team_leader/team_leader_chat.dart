import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/firebase_api.dart';

class TeamLeaderChat extends StatefulWidget {
  @override
  _TeamLeaderChatState createState() => _TeamLeaderChatState();
}

class _TeamLeaderChatState extends State<TeamLeaderChat> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Ekipler için
  Map<String, String> teams = {}; // Ekip adı -> teamId
  List<String> _selectedTeams = [];

  // Kullanıcılar için
  Map<String, String> users = {}; // Kullanıcı adı -> userId
  List<String> _selectedUsers = [];

  final FirebaseApi _firebaseApi = FirebaseApi();

  String? teamId;
  String? adminId;


  bool _isSendingToTeams = true; // Varsayılan olarak ekiplere gönderim
  bool _isSendingToUsers = false;

  @override
  void initState() {
    super.initState();
    _fetchTeamId();
    // _fetchTeams ve _fetchUsers çağrılarını _fetchTeamId sonrası yapacağız
  }

  // SharedPreferences'dan teamId'yi alıyoruz
  void _fetchTeamId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      teamId = prefs.getString('teamId'); // Giriş sırasında kaydedilmiş teamId
    });
    print('Team ID: $teamId');

    if (teamId != null && teamId!.isNotEmpty) {
      _fetchTeams();
      _fetchUsers();
    } else {
      print('Team ID bulunamadı');
    }
  }

  // Ekiplerin isimlerini ve teamId'lerini Firestore'dan çekiyoruz
  void _fetchTeams() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    adminId = prefs.getString('teamId');
    print('Team ID: $teamId');

    if (teamId != null) {
      final teamsSnapshot = await FirebaseFirestore.instance
          .collection('ekipler')
          .where('teamId', isEqualTo: teamId)
          .get();

      setState(() {
        teams = {
          for (var doc in teamsSnapshot.docs)
            doc['ad']: doc.id // 'ad' -> teamId (doc.id)
        };
      });
    } else {
      print('team ID bulunamadı');
    }
  }

  // Kullanıcıların isimlerini ve userId'lerini Firestore'dan çekiyoruz
  void _fetchUsers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    adminId = prefs.getString('teamId');
    print('teamId: $adminId');

    if (adminId != null) {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('teamId', isEqualTo: teamId)
          .get();

      setState(() {
        users = {
          for (var doc in usersSnapshot.docs)
            doc['username']: doc.id // 'username' -> userId (doc.id)
        };
      });
    } else {
      print('team ID bulunamadı');
    }
  }
/*

  // Cihaz tokenlarını ekiplere göre çekme fonksiyonu
  Future<List<String>> _fetchDeviceTokensForTeams(List<String> teamNames) async {
    List<String> deviceTokens = [];

    try {
      // 'whereIn' sorgusu ile tüm takımlardan kullanıcıları çekiyoruz
      final teamsIds = teamNames.map((teamName) => teams[teamName]!).toList();
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('teamId', whereIn: teamsIds)
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
*/
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
      'teamId':teamId,
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
  Widget _buildMessageBubble(Message message) {
    // Eğer mesajı siz gönderdiyseniz sağa, diğerlerinden geldiyse sola yerleşsin
    bool isMe = message.teamId == teamId;

    String target = '';
    if (message.selectedTeams != null && message.selectedTeams!.isNotEmpty) {
      // Ekip isimlerini teamIds'den geri almak için
      List<String> teamNames = message.selectedTeams!
          .map((teamId) {
        final entry = teams.entries.firstWhere(
              (entry) => entry.value == teamId,
          orElse: () => MapEntry('Bilinmeyen Ekip', ''),
        );
        return entry.key;
      })
          .toList();
      target = 'Ekipler: ${teamNames.join(', ')}';
    } else if (message.selectedUsers != null && message.selectedUsers!.isNotEmpty) {
      // Kullanıcı isimlerini userIds'den geri almak için
      List<String> userNames = message.selectedUsers!
          .map((userId) {
        final entry = users.entries.firstWhere(
              (entry) => entry.value == userId,
          orElse: () => MapEntry('Bilinmeyen Kullanıcı', ''),
        );
        return entry.key;
      })
          .toList();
      target = 'Kullanıcılar: ${userNames.join(', ')}';
    } else {
      target = 'Genel';
    }

    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
          isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            // Eğer mesajı başkası gönderdiyse sol tarafta avatar gösterilecek
            if (!isMe)
              CircleAvatar(
                backgroundImage: AssetImage('assets/avatar.png'),
                radius: 16,
              ),
            if (!isMe) SizedBox(width: 8),

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
                  crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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

            // Eğer mesajı siz gönderdiyseniz sağda avatar gösterilecek
            if (isMe) SizedBox(width: 8),
            if (isMe)
              CircleAvatar(
                backgroundImage: AssetImage('assets/avatar.png'),
                radius: 16,
              ),
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

        backgroundColor: Colors.blue[700],
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
                    backgroundColor: _isSendingToTeams ? Colors.blue : Colors.grey,
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
                    backgroundColor: _isSendingToUsers ? Colors.blue : Colors.grey,
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
                        backgroundColor: Colors.blue[200],
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
                        backgroundColor: Colors.purple[200],
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
                    .where((message) {
                  // Mesajları filtreleme
                  // Asistanın kendi takımına gönderilen mesajlar veya genel mesajlar
                  bool isDirectedToTeam = false;

                  if (message.selectedTeams != null && message.selectedTeams!.isNotEmpty) {
                    isDirectedToTeam = message.selectedTeams!.contains(teamId);
                  }

                  // Eğer mesaj genel ise (seçili kullanıcı veya ekip yoksa)
                  bool isGeneral = (message.selectedUsers == null || message.selectedUsers!.isEmpty) &&
                      (message.selectedTeams == null || message.selectedTeams!.isEmpty);

                  return isDirectedToTeam || isGeneral;
                }).toList();

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

  // Mesajı herkese göndermek için yeni bir fonksiyon ekleyin
  Future<void> _sendToEveryone() async {
    String message = _messageController.text.trim();

    if (message.isEmpty || teamId == null || teamId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mesaj ve teamId zorunludur')),
      );
      return;
    }

    Map<String, dynamic> messageData = {
      'message': message,
      'createdAt': Timestamp.now(),
      'teamId':teamId,
      'adminId': teamId, // Burada adminId yerine teamId kullanılmış olabilir
    };

    try {
      List<String> deviceTokens = [];
      String title = 'Yeni Mesaj';
      String description = message;

      // Herkese genel gönderim
      // Cihaz tokenlarını tüm kullanıcılardan alıyoruz
      final allUsersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();
      for (var doc in allUsersSnapshot.docs) {
        if (doc['token'] != null) {
          deviceTokens.add(doc['token']);
        }
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

  // Input alanını güncelleme
  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Attachment button

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
                icon: Icon(Icons.send, color: Colors.blue[700]),
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
  final String adminId; // Mevcut alan
  final List<String>? selectedTeams;
  final List<String>? selectedUsers;
  final Timestamp createdAt;
  final String teamId;

  Message({
    required this.id,
    required this.message,
    required this.adminId,
    this.selectedTeams,
    this.selectedUsers,
    required this.createdAt,
    required this.teamId,
  });

  factory Message.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    print('Document data: $data'); // Debugging için
    return Message(
      id: doc.id,
      message: data['message'] ?? '',
      adminId: data['adminId'] ?? '',
      teamId: data['teamId']  ?? '',
      selectedTeams: data['selectedTeams'] != null ? List<String>.from(data['selectedTeams']) : null,
      selectedUsers: data['selectedUsers'] != null ? List<String>.from(data['selectedUsers']) : null,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}
