import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'models/user.dart';
import 'models/profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firestore ODM Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const UserListScreen(),
    );
  }
}

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firestore ODM Example')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: _ageController,
                  decoration: const InputDecoration(labelText: 'Age'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _addUser,
                  child: const Text('Add User'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<User>>(
              stream: _getUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!;
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      title: Text(user.name),
                      subtitle: Text('${user.email} - Age: ${user.age}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteUser(user.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addUser() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _ageController.text.isEmpty) {
      return;
    }

    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      email: _emailController.text,
      age: int.parse(_ageController.text),
      profile: Profile(
        bio: 'New user',
        avatar: 'default.jpg',
        socialLinks: {},
        interests: [],
      ),
      createdAt: DateTime.now(),
    );

    // TODO: Add user to Firestore
    print('Created user: ${user.name}');

    // This would use the generated ODM code
    // await FirestoreODM.instance.users.doc(user.id).set(user);

    _nameController.clear();
    _emailController.clear();
    _ageController.clear();
  }

  Future<void> _deleteUser(String userId) async {
    // This would use the generated ODM code
    // await FirestoreODM.instance.users.doc(userId).delete();
  }

  Stream<List<User>> _getUsersStream() {
    // This would use the generated ODM code
    // return FirestoreODM.instance.users.orderByCreatedAt().snapshots();

    // For now, return an empty stream
    return Stream.value(<User>[]);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    super.dispose();
  }
}
