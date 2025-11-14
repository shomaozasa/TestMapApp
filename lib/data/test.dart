import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_map_app/firebase_options.dart';
import 'forms.dart';
import 'models.dart';

// ========================================
// メイン画面 - コレクション選択
// ========================================
class FirestoreInputScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Firestore データ登録'),
        backgroundColor: Colors.blue,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildMenuCard(
            context,
            'ユーザー登録',
            Icons.person,
            Colors.blue,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => UserInputForm()),
            ),
          ),
          _buildMenuCard(
            context,
            '事業者登録',
            Icons.business,
            Colors.green,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BusinessInputForm()),
            ),
          ),
          _buildMenuCard(
            context,
            'カテゴリ登録',
            Icons.category,
            Colors.orange,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CategoryInputForm()),
            ),
          ),
          _buildMenuCard(
            context,
            'イベント登録',
            Icons.event,
            Colors.purple,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EventInputForm()),
            ),
          ),
          _buildMenuCard(
            context,
            'レビュー登録',
            Icons.rate_review,
            Colors.red,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ReviewInputForm()),
            ),
          ),
          _buildMenuCard(
            context,
            'クーポン登録',
            Icons.local_offer,
            Colors.teal,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CouponInputForm()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: color, size: 40),
        title: Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}

// ========================================
// ユーザー登録フォーム
// ========================================
class UserInputForm extends StatefulWidget {
  @override
  _UserInputFormState createState() => _UserInputFormState();
}

class _UserInputFormState extends State<UserInputForm> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _iconImageController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isEmailVerified = false;

  Future<void> _saveUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        final now = DateTime.now();
        final user = UserModel(
          userId: _userIdController.text,
          password: _passwordController.text,
          username: _usernameController.text,
          iconImage: _iconImageController.text.isEmpty
              ? null
              : _iconImageController.text,
          email: _emailController.text,
          registeredAt: now,
          updatedAt: now,
          isEmailVerified: _isEmailVerified,
        );

        await _firestore
            .collection('users')
            .doc(user.userId)
            .set(user.toFirestore());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ユーザーを登録しました！')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ユーザー登録'),
        backgroundColor: Colors.blue,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _userIdController,
              decoration: InputDecoration(
                labelText: 'ユーザーID *',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'ユーザーIDを入力してください' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'パスワード *',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'パスワードを入力してください' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'ユーザー名 *',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'ユーザー名を入力してください' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'メールアドレス *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'メールアドレスを入力してください' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _iconImageController,
              decoration: InputDecoration(
                labelText: 'アイコン画像URL',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text('メールアドレス認証済み'),
              value: _isEmailVerified,
              onChanged: (value) => setState(() => _isEmailVerified = value),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveUser,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('登録', style: TextStyle(fontSize: 18)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _iconImageController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}

// ========================================
// 事業者登録フォーム
// ========================================
class BusinessInputForm extends StatefulWidget {
  @override
  _BusinessInputFormState createState() => _BusinessInputFormState();
}

class _BusinessInputFormState extends State<BusinessInputForm> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  final _businessIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _iconImageController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _categoryController = TextEditingController();
  final _representativeNameController = TextEditingController();
  final _websiteUrlController = TextEditingController();
  final _twitterUrlController = TextEditingController();
  final _instagramUrlController = TextEditingController();
  bool _isVerified = false;

  Future<void> _saveBusiness() async {
    if (_formKey.currentState!.validate()) {
      try {
        final now = DateTime.now();
        final business = BusinessModel(
          businessId: _businessIdController.text,
          password: _passwordController.text,
          businessName: _businessNameController.text,
          iconImage: _iconImageController.text.isEmpty
              ? null
              : _iconImageController.text,
          email: _emailController.text,
          phoneNumber: _phoneNumberController.text.isEmpty
              ? null
              : _phoneNumberController.text,
          category: _categoryController.text.isEmpty
              ? null
              : _categoryController.text,
          registeredAt: now,
          updatedAt: now,
          isVerified: _isVerified,
          representativeName: _representativeNameController.text.isEmpty
              ? null
              : _representativeNameController.text,
          websiteUrl: _websiteUrlController.text.isEmpty
              ? null
              : _websiteUrlController.text,
          twitterUrl: _twitterUrlController.text.isEmpty
              ? null
              : _twitterUrlController.text,
          instagramUrl: _instagramUrlController.text.isEmpty
              ? null
              : _instagramUrlController.text,
        );

        await _firestore
            .collection('businesses')
            .doc(business.businessId)
            .set(business.toFirestore());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('事業者を登録しました！')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('事業者登録'),
        backgroundColor: Colors.green,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _businessIdController,
              decoration: InputDecoration(
                labelText: '事業者ID *',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? '事業者IDを入力してください' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'パスワード *',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'パスワードを入力してください' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _businessNameController,
              decoration: InputDecoration(
                labelText: '事業者名 *',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? '事業者名を入力してください' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'メールアドレス *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'メールアドレスを入力してください' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _phoneNumberController,
              decoration: InputDecoration(
                labelText: '電話番号',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _categoryController,
              decoration: InputDecoration(
                labelText: '事業者カテゴリ',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _representativeNameController,
              decoration: InputDecoration(
                labelText: '代表者名',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _iconImageController,
              decoration: InputDecoration(
                labelText: 'アイコン画像URL',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _websiteUrlController,
              decoration: InputDecoration(
                labelText: 'ウェブサイトURL',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _twitterUrlController,
              decoration: InputDecoration(
                labelText: 'Twitter URL',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _instagramUrlController,
              decoration: InputDecoration(
                labelText: 'Instagram URL',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text('認証済み'),
              value: _isVerified,
              onChanged: (value) => setState(() => _isVerified = value),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveBusiness,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('登録', style: TextStyle(fontSize: 18)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _businessIdController.dispose();
    _passwordController.dispose();
    _businessNameController.dispose();
    _iconImageController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _categoryController.dispose();
    _representativeNameController.dispose();
    _websiteUrlController.dispose();
    _twitterUrlController.dispose();
    _instagramUrlController.dispose();
    super.dispose();
  }
}

// ========================================
// カテゴリ登録フォーム
// ========================================
class CategoryInputForm extends StatefulWidget {
  @override
  _CategoryInputFormState createState() => _CategoryInputFormState();
}

class _CategoryInputFormState extends State<CategoryInputForm> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  final _categoryIdController = TextEditingController();
  final _categoryNameController = TextEditingController();

  Future<void> _saveCategory() async {
    if (_formKey.currentState!.validate()) {
      try {
        final now = DateTime.now();
        final category = CategoryModel(
          categoryId: _categoryIdController.text,
          categoryName: _categoryNameController.text,
          registeredAt: now,
          updatedAt: now,
        );

        await _firestore
            .collection('categories')
            .doc(category.categoryId)
            .set(category.toFirestore());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('カテゴリを登録しました！')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('カテゴリ登録'),
        backgroundColor: Colors.orange,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _categoryIdController,
              decoration: InputDecoration(
                labelText: 'カテゴリID *',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'カテゴリIDを入力してください' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _categoryNameController,
              decoration: InputDecoration(
                labelText: 'カテゴリ名 *',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'カテゴリ名を入力してください' : null,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveCategory,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('登録', style: TextStyle(fontSize: 18)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _categoryIdController.dispose();
    _categoryNameController.dispose();
    super.dispose();
  }
}

// ========================================
// イベント登録フォーム
// ========================================
class EventInputForm extends StatefulWidget {
  @override
  _EventInputFormState createState() => _EventInputFormState();
}

class _EventInputFormState extends State<EventInputForm> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  final _eventIdController = TextEditingController();
  final _businessIdController = TextEditingController();
  final _categoryIdController = TextEditingController();
  final _locationController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _eventImageController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _startTime = DateTime.now().add(Duration(days: 7));
  DateTime _endTime = DateTime.now().add(Duration(days: 7, hours: 3));

  String _businessName = '';
  String? _businessIcon;
  String _categoryName = '';

  Future<void> _fetchBusinessInfo() async {
    if (_businessIdController.text.isEmpty) return;

    try {
      final doc = await _firestore
          .collection('businesses')
          .doc(_businessIdController.text)
          .get();

      if (doc.exists) {
        final business = BusinessModel.fromFirestore(doc);
        setState(() {
          _businessName = business.businessName;
          _businessIcon = business.iconImage;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('事業者情報を取得しました')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('事業者が見つかりません')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: $e')),
      );
    }
  }

  Future<void> _fetchCategoryInfo() async {
    if (_categoryIdController.text.isEmpty) return;

    try {
      final doc = await _firestore
          .collection('categories')
          .doc(_categoryIdController.text)
          .get();

      if (doc.exists) {
        final category = CategoryModel.fromFirestore(doc);
        setState(() {
          _categoryName = category.categoryName;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('カテゴリ情報を取得しました')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('カテゴリが見つかりません')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: $e')),
      );
    }
  }

  Future<void> _saveEvent() async {
    if (_formKey.currentState!.validate()) {
      if (_businessName.isEmpty || _categoryName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('事業者情報とカテゴリ情報を取得してください')),
        );
        return;
      }

      try {
        final now = DateTime.now();
        final event = EventModel(
          eventId: _eventIdController.text,
          businessId: _businessIdController.text,
          businessName: _businessName,
          businessIcon: _businessIcon,
          categoryId: _categoryIdController.text,
          categoryName: _categoryName,
          startTime: _startTime,
          endTime: _endTime,
          eventImage: _eventImageController.text.isEmpty
              ? null
              : _eventImageController.text,
          location: _locationController.text,
          latitude: _latitudeController.text.isEmpty
              ? null
              : double.tryParse(_latitudeController.text),
          longitude: _longitudeController.text.isEmpty
              ? null
              : double.tryParse(_longitudeController.text),
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          registeredAt: now,
          updatedAt: now,
        );

        await _firestore
            .collection('events')
            .doc(event.eventId)
            .set(event.toFirestore());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('イベントを登録しました！')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('イベント登録'),
        backgroundColor: Colors.purple,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _eventIdController,
              decoration: InputDecoration(
                labelText: 'イベントID *',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'イベントIDを入力してください' : null,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _businessIdController,
                    decoration: InputDecoration(
                      labelText: '事業者ID *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? '事業者IDを入力してください' : null,
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _fetchBusinessInfo,
                  child: Text('取得'),
                ),
              ],
            ),
            if (_businessName.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('事業者名: $_businessName',
                    style: TextStyle(color: Colors.green)),
              ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _categoryIdController,
                    decoration: InputDecoration(
                      labelText: 'カテゴリID *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'カテゴリIDを入力してください' : null,
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _fetchCategoryInfo,
                  child: Text('取得'),
                ),
              ],
            ),
            if (_categoryName.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('カテゴリ名: $_categoryName',
                    style: TextStyle(color: Colors.green)),
              ),
            SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(
                labelText: '場所 *',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? '場所を入力してください' : null,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latitudeController,
                    decoration: InputDecoration(
                      labelText: '緯度',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _longitudeController,
                    decoration: InputDecoration(
                      labelText: '経度',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ListTile(
              title: Text('開始時刻'),
              subtitle: Text(_startTime.toString().substring(0, 16)),
              trailing: Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startTime,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 365)),
                );
                if (date != null) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_startTime),
                  );
                  if (time != null) {
                    setState(() {
                      _startTime = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  }
                }
              },
            ),
            ListTile(
              title: Text('終了時刻'),
              subtitle: Text(_endTime.toString().substring(0, 16)),
              trailing: Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _endTime,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 365)),
                );
                if (date != null) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_endTime),
                  );
                  if (time != null) {
                    setState(() {
                      _endTime = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  }
                }
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _eventImageController,
              decoration: InputDecoration(
                labelText: 'イベント画像URL',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: '説明',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveEvent,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('登録', style: TextStyle(fontSize: 18)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _eventIdController.dispose();
    _businessIdController.dispose();
    _categoryIdController.dispose();
    _locationController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _eventImageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

// ========================================
// レビュー登録フォーム
// ========================================
class ReviewInputForm extends StatefulWidget {
  @override
  _ReviewInputFormState createState() => _ReviewInputFormState();
}

class _ReviewInputFormState extends State<ReviewInputForm> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  final _reviewIdController = TextEditingController();
  final _eventIdController = TextEditingController();
  final _userIdController = TextEditingController();
  final _commentController = TextEditingController();
  final _reviewImage1Controller = TextEditingController();
  final _reviewImage2Controller = TextEditingController();
  final _reviewImage3Controller = TextEditingController();

  double _rating = 5.0;
  String _username = '';
  String? _userIcon;

  Future<void> _fetchUserInfo() async {
    if (_userIdController.text.isEmpty) return;

    try {
      final userDoc = await _firestore.collection('users').doc(_userIdController.text).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        setState(() {
          _username = userData['username'] ?? '';
          _userIcon = userData['iconImage'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ユーザーが見つかりません')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ユーザー情報の取得中にエラーが発生しました: $e')),
      );
    }
  }

  Future<void> _saveReview() async {
    if (_formKey.currentState!.validate()) {
      try {
        final reviewData = {
          'reviewId': _reviewIdController.text,
          'eventId': _eventIdController.text,
          'userId': _userIdController.text,
          'username': _username,
          'userIcon': _userIcon,
          'rating': _rating,
          'comment': _commentController.text,
          'reviewImages': [
            _reviewImage1Controller.text,
            _reviewImage2Controller.text,
            _reviewImage3Controller.text,
          ].where((url) => url.isNotEmpty).toList(),
          'registeredAt': DateTime.now(),
        };

        await _firestore
            .collection('events')
            .doc(_eventIdController.text)
            .collection('reviews')
            .doc(_reviewIdController.text)
            .set(reviewData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('レビューを保存しました')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('レビューの保存中にエラーが発生しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('レビュー登録フォーム'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _reviewIdController,
                decoration: InputDecoration(labelText: 'レビューID'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'レビューIDを入力してください';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _eventIdController,
                decoration: InputDecoration(labelText: 'イベントID'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'イベントIDを入力してください';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _userIdController,
                decoration: InputDecoration(labelText: 'ユーザーID'),
                onChanged: (_) => _fetchUserInfo(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'ユーザーIDを入力してください';
                  }
                  return null;
                },
              ),
              if (_username.isNotEmpty)
                ListTile(
                  leading: _userIcon != null
                      ? CircleAvatar(backgroundImage: NetworkImage(_userIcon!))
                      : CircleAvatar(child: Icon(Icons.person)),
                  title: Text(_username),
                ),
              Slider(
                value: _rating,
                onChanged: (value) {
                  setState(() {
                    _rating = value;
                  });
                },
                min: 1.0,
                max: 5.0,
                divisions: 4,
                label: '$_rating',
              ),
              TextFormField(
                controller: _commentController,
                decoration: InputDecoration(labelText: 'コメント'),
                maxLines: 3,
              ),
              TextFormField(
                controller: _reviewImage1Controller,
                decoration: InputDecoration(labelText: 'レビュー画像1のURL'),
              ),
              TextFormField(
                controller: _reviewImage2Controller,
                decoration: InputDecoration(labelText: 'レビュー画像2のURL'),
              ),
              TextFormField(
                controller: _reviewImage3Controller,
                decoration: InputDecoration(labelText: 'レビュー画像3のURL'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveReview,
                child: Text('レビューを保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reviewIdController.dispose();
    _eventIdController.dispose();
    _userIdController.dispose();
    _commentController.dispose();
    _reviewImage1Controller.dispose();
    _reviewImage2Controller.dispose();
    _reviewImage3Controller.dispose();
    super.dispose();
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firestore App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FirestoreInputScreen(),
    );
  }
}