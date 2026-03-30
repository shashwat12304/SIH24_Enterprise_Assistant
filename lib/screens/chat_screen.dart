import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mokshayani/screens/discover_screen.dart';
import 'package:mokshayani/screens/corpus_screen.dart';
import 'package:mokshayani/services/api_service.dart';

class ChatbotUI extends StatefulWidget {
  const ChatbotUI({super.key});

  @override
  State<ChatbotUI> createState() => _ChatbotUIState();
}

class _ChatbotUIState extends State<ChatbotUI> {
  List<Map<String, String>> chatMessages = [];
  String sessionId = '';
  bool _isLoading = false;
  TextEditingController searchController = TextEditingController();
  User? currentUser;
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _startNewChatSession();
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/auth');
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _sendChatQuery(String query) async {
    if (query.isEmpty) return;

    setState(() {
      chatMessages.add({'sender': 'user', 'message': query});
      _isLoading = true;
    });

    try {
      final result = await ApiService.askQuestion(query);
      setState(() {
        chatMessages
            .add({'sender': 'bot', 'message': result['response'] ?? ''});
      });
    } on ApiException catch (e) {
      setState(() {
        chatMessages.add({'sender': 'bot', 'message': '⚠️ ${e.message}'});
      });
    } catch (e) {
      setState(() {
        chatMessages.add(
            {'sender': 'bot', 'message': 'Error: Failed to connect to server.'});
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      final file = result.files.single;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Uploading: ${file.name}')),
      );
      try {
        final msg = await ApiService.uploadPdf(file.path!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  void _startNewChatSession() {
    setState(() {
      chatMessages.clear();
      sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    });
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) return;
    setState(() => _currentNavIndex = index);
    switch (index) {
      case 0:
        break; // Already on home
      case 1:
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const DiscoverScreen()));
        break;
      case 2:
        Navigator.pushNamed(context, '/library');
        break;
      case 3:
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const CorpusScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black,
        title: const Text('Mokshayani', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Upload PDF',
            onPressed: _pickFile,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Chat',
            onPressed: _startNewChatSession,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.of(context).pushReplacementNamed('/auth');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Welcome header
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blueGrey[800],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.smart_toy, color: Colors.white, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Welcome${currentUser?.email != null ? ", ${currentUser!.email!.split("@")[0]}" : ""}! How can I assist you today?',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),

          // Chat messages
          Expanded(
            child: chatMessages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 48, color: Colors.white30),
                        const SizedBox(height: 12),
                        Text('Ask me about HR policies, IT support,\ncompany events, and more!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: chatMessages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chatMessages.length && _isLoading) {
                        return const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      final chat = chatMessages[index];
                      bool isUser = chat['sender'] == 'user';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.blue : Colors.grey[850],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            chat['message']!,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[900],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onSubmitted: (value) {
                      _sendChatQuery(value);
                      searchController.clear();
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[850],
                      hintText: 'Ask anything...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: () {
                      _sendChatQuery(searchController.text);
                      searchController.clear();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Discover'),
          BottomNavigationBarItem(
              icon: Icon(Icons.library_books), label: 'Library'),
          BottomNavigationBarItem(
              icon: Icon(Icons.folder), label: 'Corpus'),
        ],
        onTap: _onNavTap,
      ),
    );
  }
}
