import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      final doc = await _firestore
          .collection('users')
          .doc(_userIdController.text)
          .get();

      if (doc.exists) {
        final user = UserModel.fromFirestore(doc);
        setState(() {
          _username = user.username;
          _userIcon = user.iconImage;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ユーザー情報を取得しました')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ユーザーが見つかりません')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: $e')),
      );
    }
  }

  Future<void> _saveReview() async {
    if (_formKey.currentState!.validate()) {
      if (_username.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ユーザー情報を取得してください')),
        );
        return;
      }

      try {
        final now = DateTime.now();
        final reviewImages = <String>[];
        if (_reviewImage1Controller.text.isNotEmpty)
          reviewImages.add(_reviewImage1Controller.text);
        if (_reviewImage2Controller.text.isNotEmpty)
          reviewImages.add(_reviewImage2Controller.text);
        if (_reviewImage3Controller.text.isNotEmpty)
          reviewImages.add(_reviewImage3Controller.text);

        final review = ReviewModel(
          reviewId: _reviewIdController.text,
          userId: _userIdController.text,
          username: _username,
          userIcon: _userIcon,
          rating: _rating,
          comment: _commentController.text,
          reviewImages: reviewImages,
          registeredAt: now,
          updatedAt: now,
        );

        await _firestore
            .collection('events')
            .doc(_eventIdController.text)
            .collection('reviews')
            .doc(review.reviewId)
            .set(review.toFirestore());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('レビューを登録しました！')),
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
        title: Text('レビュー登録'),
        backgroundColor: Colors.red,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _reviewIdController,
              decoration: InputDecoration(
                labelText: 'レビューID *',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'レビューIDを入力してください' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _eventIdController,
              decoration: InputDecoration(
                labelText: 'イベントID *',
                border: OutlineInputBorder(),
                helperText: 'レビュー対象のイベントID',
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'イベントIDを入力してください' : null,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _userIdController,
                    decoration: InputDecoration(
                      labelText: 'ユーザーID *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'ユーザーIDを入力してください' : null,
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _fetchUserInfo,
                  child: Text('取得'),
                ),
              ],
            ),
            if (_username.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('ユーザー名: $_username',
                    style: TextStyle(color: Colors.green)),
              ),
            SizedBox(height: 16),
            Text('評価', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Slider(
              value: _rating,
              min: 0,
              max: 5,
              divisions: 10,
              label: _rating.toString(),
              onChanged: (value) => setState(() => _rating = value),
            ),
            Text('${_rating.toStringAsFixed(1)} / 5.0',
                style: TextStyle(fontSize: 18, color: Colors.orange)),
            SizedBox(height: 16),
            TextFormField(
              controller: _commentController,
              decoration: InputDecoration(
                labelText: 'コメント *',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'コメントを入力してください' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _reviewImage1Controller,
              decoration: InputDecoration(
                labelText: 'レビュー画像URL 1',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _reviewImage2Controller,
              decoration: InputDecoration(
                labelText: 'レビュー画像URL 2',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _reviewImage3Controller,
              decoration: InputDecoration(
                labelText: 'レビュー画像URL 3',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveReview,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('登録', style: TextStyle(fontSize: 18)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
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

// ========================================
// クーポン登録フォーム
// ========================================
class CouponInputForm extends StatefulWidget {
  @override
  _CouponInputFormState createState() => _CouponInputFormState();
}

class _CouponInputFormState extends State<CouponInputForm> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  final _couponIdController = TextEditingController();
  final _couponNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _userIdController = TextEditingController();
  final _businessIdController = TextEditingController();
  final _issueValueController = TextEditingController();

  DateTime _validFrom = DateTime.now();
  DateTime _validUntil = DateTime.now().add(Duration(days: 90));
  bool _isUsed = false;

  Future<void> _saveCoupon() async {
    if (_formKey.currentState!.validate()) {
      try {
        final coupon = CouponModel(
          couponId: _couponIdController.text,
          couponName: _couponNameController.text,
          description: _descriptionController.text,
          validFrom: _validFrom,
          validUntil: _validUntil,
          userId: _userIdController.text,
          businessId: _businessIdController.text,
          issueValue: int.parse(_issueValueController.text),
          isUsed: _isUsed,
          usedAt: _isUsed ? DateTime.now() : null,
        );

        await _firestore
            .collection('coupons')
            .doc(coupon.couponId)
            .set(coupon.toFirestore());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('クーポンを登録しました！')),
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
        title: Text('クーポン登録'),
        backgroundColor: Colors.teal,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _couponIdController,
              decoration: InputDecoration(
                labelText: 'クーポンID *',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'クーポンIDを入力してください' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _couponNameController,
              decoration: InputDecoration(
                labelText: 'クーポン名 *',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'クーポン名を入力してください' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'クーポン説明 *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'クーポン説明を入力してください' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _userIdController,
              decoration: InputDecoration(
                labelText: 'ユーザーID *',
                border: OutlineInputBorder(),
                helperText: 'クーポンを所有するユーザー',
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'ユーザーIDを入力してください' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _businessIdController,
              decoration: InputDecoration(
                labelText: '事業者ID *',
                border: OutlineInputBorder(),
                helperText: 'クーポンを発行する事業者',
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? '事業者IDを入力してください' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _issueValueController,
              decoration: InputDecoration(
                labelText: 'クーポン発行値 *',
                border: OutlineInputBorder(),
                helperText: '割引額（円）',
              ),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'クーポン発行値を入力してください' : null,
            ),
            SizedBox(height: 16),
            ListTile(
              title: Text('有効開始日'),
              subtitle: Text(_validFrom.toString().substring(0, 10)),
              trailing: Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _validFrom,
                  firstDate: DateTime.now().subtract(Duration(days: 365)),
                  lastDate: DateTime.now().add(Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _validFrom = date);
                }
              },
            ),
            ListTile(
              title: Text('有効期限'),
              subtitle: Text(_validUntil.toString().substring(0, 10)),
              trailing: Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _validUntil,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _validUntil = date);
                }
              },
            ),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text('使用済み'),
              value: _isUsed,
              onChanged: (value) => setState(() => _isUsed = value),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveCoupon,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('登録', style: TextStyle(fontSize: 18)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _couponIdController.dispose();
    _couponNameController.dispose();
    _descriptionController.dispose();
    _userIdController.dispose();
    _businessIdController.dispose();
    _issueValueController.dispose();
    super.dispose();
  }
}