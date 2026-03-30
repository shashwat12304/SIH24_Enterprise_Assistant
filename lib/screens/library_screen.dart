import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<Map<String, String>> chatHistory = [];

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? chatStrings = prefs.getStringList('chatHistory');
    if (chatStrings != null) {
      setState(() {
        chatHistory = chatStrings
            .map((s) => Map<String, String>.from(jsonDecode(s)))
            .toList();
      });
    }
  }

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'chatHistory', chatHistory.map((c) => jsonEncode(c)).toList());
  }

  Future<void> _deleteChat(int index) async {
    setState(() => chatHistory.removeAt(index));
    await _saveChatHistory();
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All History'),
        content: const Text('Are you sure you want to clear all chat history?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear')),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => chatHistory.clear());
      await _saveChatHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _clearAll,
          ),
        ],
      ),
      body: chatHistory.isEmpty
          ? const Center(
              child:
                  Text('No chat history yet.', style: TextStyle(color: Colors.white54)))
          : ListView.builder(
              itemCount: chatHistory.length,
              itemBuilder: (context, index) {
                final chat = chatHistory[index];
                return ListTile(
                  leading: Icon(
                    chat['sender'] == 'user' ? Icons.person : Icons.smart_toy,
                    color: chat['sender'] == 'user' ? Colors.blue : Colors.grey,
                  ),
                  title: Text(chat['sender'] == 'user' ? 'You' : 'Assistant',
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    chat['message'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteChat(index),
                  ),
                );
              },
            ),
    );
  }
}
