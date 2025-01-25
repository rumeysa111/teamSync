import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AssistantTeamsPage extends StatefulWidget {
  const AssistantTeamsPage ({super.key});

  @override
  State<AssistantTeamsPage > createState() => _AssistantTeamsPageState();
}

class _AssistantTeamsPageState extends State<AssistantTeamsPage> {
  final TextEditingController _isimSoyisimController = TextEditingController();
  final TextEditingController _kullaniciAdiController = TextEditingController();
  final TextEditingController _sifreController = TextEditingController();
  String? adminId;

  String? secilenEkip;
  String? secilenPozisyon;
  @override
  void initState() {
    super.initState();
    _getAdminId().then((_) {
      if (adminId != null) {
        _varsayilanEkipleriOlustur(adminId!);
      } else {
        print('Admin ID bulunamadı.');
      }
    });
    //_varsayilanEkipleriOlustur(adminId ?? ''); // Varsayılan ekipleri oluştur

  }

  Future<void> _adminEkle(String username, String password, String tc) async {
    try {
      // Admin'i Firestore'a ekliyoruz ve döküman referansını alıyoruz
      DocumentReference adminRef = await _firestore.collection('admins').add({
        'username': username,
        'password': password,
        'tc': tc, // Şifreyi hashlemeyi unutmayın
      });

      // Yeni admin'in ID'sini alıyoruz
      String adminId = adminRef.id;

      // Admin ID'sini SharedPreferences'ta sakla
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('adminId', adminId);

      // Admin ID'sini varsayılan ekiplere ekle
      await _varsayilanEkipleriOlustur(adminId);

      // Başarılı bir şekilde admin eklendi mesajı
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Admin başarıyla eklendi.")));
    } catch (e) {
      // Hata durumunda mesaj göster
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Admin eklenirken bir hata oluştu: $e")));
    }
  }



  Future<void> _varsayilanEkipleriOlustur(String adminId) async {
    final varsayilanEkipler = [
      {"ad": "Yönetim Kurulu", "aciklama": "Yönetim ekibi", "role": "Yonetici"},
      {"ad": "Asistan", "aciklama": "Asistanlar", "role": "Asistan"},
      {"ad": "Proje Yöneticisi", "aciklama": "Proje yöneticileri", "role": "Proje Yonetici"}
    ];

    for (var ekip in varsayilanEkipler) {
      final QuerySnapshot ekipQuery = await _firestore
          .collection('ekipler')
          .where('ad', isEqualTo: ekip['ad'])
          .where('adminId', isEqualTo: adminId) // Sadece bu adminine ait ekipleri kontrol ediyoruz
          .limit(1)
          .get();

      if (ekipQuery.docs.isEmpty) {
        // Eğer ekip yoksa, yeni ekibi oluşturuyoruz ve adminId ile ilişkilendiriyoruz
        DocumentReference docRef = _firestore.collection('ekipler').doc();
        String teamId = docRef.id;

        await docRef.set({
          'ad': ekip['ad'],
          'aciklama': ekip['aciklama'],
          'role': ekip['role'],
          'teamId': teamId,
          'adminId': adminId, // Admin ID'sini ekliyoruz
          'kullanicilar': [], // Kullanıcılar boş başlıyor
        });
        print('Yeni ekip oluşturuldu: ${docRef.id}');

      } else {
        print('Mevcut ekip bulundu ve yeni bir ekip oluşturulmadı: ${ekipQuery.docs.first.id}');
      }
    }
  }






  final List<String> pozisyonlar = [ "Ekip Lideri", "Çalışan"];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _ekipOlustur(String ekipAdi, String aciklama) async {
    try {
      // Admin ID'sini SharedPreferences'tan al
      final prefs = await SharedPreferences.getInstance();
      String? adminId = prefs.getString('adminId'); // Admin ID'sini al

      if (adminId == null) {
        throw 'Admin ID bulunamadı.'; // Admin ID yoksa hata döndür
      }

      // Yeni ekip oluşturuyoruz, mevcut ekipleri kontrol etmiyoruz
      DocumentReference docRef = _firestore.collection('ekipler').doc();
      String teamId = docRef.id;

      await docRef.set({
        'ad': ekipAdi,
        'aciklama': aciklama,
        'teamId': teamId, // Otomatik oluşturulan teamId
        'kullanicilar': [], // Kullanıcılar boş başlatılıyor
        'adminId': adminId, // Admin ID'yi ekibe kaydediyoruz

      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Ekip oluşturuldu.")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Ekip oluşturulamadı: $e")));
    }
  }


  Future<void> _kullaniciEkle(String isim, String pozisyon, String kullaniciAdi, String sifre, String ekipId) async {
    try {
      // 1. Kullanıcıyı ilgili ekibe ekle
      await _firestore.collection('ekipler').doc(ekipId).update({
        'kullanicilar': FieldValue.arrayUnion([
          {
            'isim': isim,
            'kullaniciAdi': kullaniciAdi,
            'pozisyon': pozisyon,
            'teamId':ekipId,
          }
        ])
      });

      // 2. Ekip adını ve admin ID'sini al
      DocumentSnapshot ekipDoc = await _firestore.collection('ekipler').doc(ekipId).get();
      String ekipAdi = ekipDoc['ad']; // Ekip adını buradan alın
      String? adminId = ekipDoc['adminId']; // Admin ID'sini buradan alın
      String role = pozisyon; // Kullanıcı eklerken seçilen pozisyonu kullan
      // 4. Kullanıcıyı users koleksiyonuna ekle
      await _firestore.collection('users').add({
        'username': kullaniciAdi,
        'password': sifre, // Hashlenmiş şifre
        'team': ekipAdi, // Kullanıcının hangi ekipten geldiğini belirten alan
        'pozisyon': pozisyon,
        'teamId': ekipId, // Kullanıcının ait olduğu ekibin ID'si
        'adminId': adminId, // Admin ID'sini ekle
        'role':pozisyon,
        'isim': isim

      });

      // Başarılı bir şekilde kullanıcı eklendi mesajı
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Kullanıcı eklendi.")));

      // Formu temizle
      _isimSoyisimController.clear();
      _kullaniciAdiController.clear();
      _sifreController.clear();
      setState(() {});

    } catch (e) {
      // Hata durumunda daha fazla ayrıntı içeren mesaj
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Kullanıcı eklenemedi. Hata: $e")));
    }
  }



  void _showEkipOlusturDialog() {
    final TextEditingController _ekipAdiController = TextEditingController();
    final TextEditingController _aciklamaController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Ekip Oluştur"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _ekipAdiController,
                decoration: InputDecoration(labelText: "Ekip Adı"),
              ),
              TextField(
                controller: _aciklamaController,
                decoration: InputDecoration(labelText: "Açıklama"),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text("İptal"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Ekip Oluştur"),
              onPressed: () {
                if (_ekipAdiController.text.isNotEmpty) {
                  _ekipOlustur(
                    _ekipAdiController.text,
                    _aciklamaController.text,
                  );
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Lütfen ekip adı girin.")),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showKullaniciEkleDialog(String ekipId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Kullanıcı Ekle"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _isimSoyisimController,
                  decoration: InputDecoration(labelText: "İsim Soyisim"),
                ),

                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: secilenPozisyon,
                  hint: Text("Pozisyon Seç"),
                  onChanged: (value) {
                    setState(() {
                      secilenPozisyon = value;
                    });
                  },
                  items: pozisyonlar.map((pozisyon) {
                    return DropdownMenuItem<String>(
                      value: pozisyon,
                      child: Text(pozisyon),
                    );
                  }).toList(),
                ),
                TextField(
                  controller: _kullaniciAdiController,
                  decoration: InputDecoration(labelText: "Kullanıcı Adı"),
                ),
                TextField(
                  controller: _sifreController,
                  decoration: InputDecoration(labelText: "Şifre"),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text("İptal"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Kullanıcı Ekle"),
              onPressed: () {
                if (secilenPozisyon != null) {
                  _kullaniciEkle(
                      _isimSoyisimController.text,
                      secilenPozisyon!,
                      _kullaniciAdiController.text,
                      _sifreController.text,
                      ekipId

                  );
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Lütfen ekip ve pozisyon seçin.")),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _getAdminId() async {
    final prefs = await SharedPreferences.getInstance();
    adminId = prefs.getString('adminId'); // Admin ID'sini al
  }

  Stream<QuerySnapshot>? _getEkiplerStream() {
    if (adminId == null) {
      return null; // Admin ID henüz yüklenmediyse stream dönmüyoruz
    }

    return _firestore
        .collection('ekipler')
        .where('adminId', isEqualTo: adminId) // Sadece adminin ekiplerini al
        .snapshots();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/appbar4.png'), // Arka plan resmi
              fit: BoxFit.fill, // Resmin kaplamasını ayarlamak için
            ),
          ),
        ),
        toolbarHeight: 120.0, // AppBar yüksekliği
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 10.0, right: 30, left: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 280, // Buton genişliğinin ekran genişliğini kapsamasını sağlar
              height: 60.0, // Buton yüksekliği
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 215, 215, 215), // Buton arka plan rengi
                borderRadius: BorderRadius.circular(12.0), // Yuvarlatılmış köşeler
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3), // Gölge rengi ve opaklık
                    spreadRadius: 2, // Gölgenin yayılma mesafesi
                    blurRadius: 5, // Gölgenin bulanıklık mesafesi
                    offset: Offset(0, 4), // Gölgenin yerleşim yeri (x, y)
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _showEkipOlusturDialog,
                icon: Icon(Icons.group_add, color: Colors.black),
                label: Text(" Ekip Oluştur", style: TextStyle(color: Colors.black)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent, // Butonun arka plan rengini saydam yap
                  shadowColor: Colors.transparent, // Butonun kendi gölgesini kaldır
                ),
              ),
            ),

            SizedBox(height: 40),
            Text("Ekipler ve Kullanıcılar", style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _getEkiplerStream(),
                  builder: (context, snapshot) {
                    if (adminId == null) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text("Bir hata oluştu"));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final ekipler = snapshot.data!.docs;

                    return ListView(
                      children: ekipler.map((DocumentSnapshot document) {
                        final ekipAdi = document['ad'] as String;
                        final aciklama = document['aciklama'] as String;
                        final kullanicilar = document['kullanicilar'] as List<dynamic>? ?? [];
                        print(document['kullanicilar']);


                        return Container(
                          margin: EdgeInsets.only(bottom: 16.0), // Ekipler arasına boşluk ekle
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.black), // Çerçeve rengi
                            borderRadius: BorderRadius.circular(12.0), // Yuvarlatılmış köşeler
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2), // Gölgelik rengi
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: Offset(0, 8), // Gölgelik ofseti
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              ExpansionTile(
                                title: Text(ekipAdi),
                                subtitle: Text(aciklama),
                                children: [
                                  if (kullanicilar.isNotEmpty)
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: kullanicilar.length,
                                      itemBuilder: (context, index) {
                                        final kullanici = kullanicilar[index];
                                        final pozisyon = kullanici['pozisyon'] != null ? kullanici['pozisyon'] as String : '';

                                        return ListTile(
                                          title: Text(kullanici['isim']),
                                          subtitle: Text(pozisyon),
                                        );
                                      },
                                    ),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  if (ekipAdi == "Proje Yöneticisi" ||
                                      ekipAdi == "Yönetim Kurulu" ||
                                      ekipAdi == "Asistan") {
                                    _showNewKullaniciEkleDialog(document.id);
                                  } else {
                                    _showKullaniciEkleDialog(document.id);
                                  }
                                },
                                icon: Icon(Icons.person_add),
                                label: Text("Kullanıcı Ekle"),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                )

            ),
          ],
        ),
      ),
    );
  }
  void _showNewKullaniciEkleDialog(String ekipId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Kullanıcı Ekle"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _isimSoyisimController,
                  decoration: InputDecoration(labelText: "İsim Soyisim"),
                ),
                TextField(
                  controller: _kullaniciAdiController,
                  decoration: InputDecoration(labelText: "Kullanıcı Adı"),
                ),
                TextField(
                  controller: _sifreController,
                  decoration: InputDecoration(labelText: "Şifre"),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text("İptal"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Kullanıcı Ekle"),
              onPressed: () {
                _NewkullaniciEkle(
                  _isimSoyisimController.text,
                  _kullaniciAdiController.text,
                  _sifreController.text,
                  ekipId,



                );
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }



  Future<void> _NewkullaniciEkle(String isim, String kullaniciAdi, String sifre, String ekipId) async {
    try {

      // 1. Kullanıcıyı ilgili ekibe ekle
      await _firestore.collection('ekipler').doc(ekipId).update({
        'kullanicilar': FieldValue.arrayUnion([
          {
            'isim': isim,
            'kullaniciAdi': kullaniciAdi,
            'teamId':ekipId,

          }
        ])
      });

      // 2. Ekip adını al
      DocumentSnapshot ekipDoc = await _firestore.collection('ekipler').doc(ekipId).get();
      String ekipAdi = ekipDoc['ad']; // Ekip adını buradan alın
      String? adminId = ekipDoc['adminId']; // Admin ID'sini buradan alın
      String? role = ekipDoc['role']; // Rol bilgisini buradan alın



      // 4. Kullanıcıyı users koleksiyonuna ekle
      await _firestore.collection('users').add({
        'username': kullaniciAdi,
        'password': sifre, // Hashlenmiş şifre
        'team': ekipAdi, // Kullanıcının hangi ekipten geldiğini belirten alan
        'teamId': ekipId, // Kullanıcının ait olduğu ekibin ID'si
        'adminId': adminId ,// Admin ID'sini ekle
        'role': role, // Rol bilgisini ekle
        'isim':isim

      });

      // Başarılı bir şekilde kullanıcı eklendi mesajı
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Kullanıcı eklendi.")));

      // Formu temizle
      _isimSoyisimController.clear();
      _kullaniciAdiController.clear();
      _sifreController.clear();
      setState(() {});

    } catch (e) {
      // Hata durumunda daha fazla ayrıntı içeren mesaj
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Kullanıcı eklenemedi. Hata: $e")));
    }
  }

}