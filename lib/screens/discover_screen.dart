import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:mokshayani/services/api_service.dart';

class DiscoverScreen extends StatefulWidget {
  final String? initialQuery;

  const DiscoverScreen({super.key, this.initialQuery});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  List<Map<String, String>> searchResults = [];
  File? _image;
  bool _isLoading = false;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _sendSearchQuery(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _sendSearchQuery(String query) async {
    setState(() {
      searchResults.add({'sender': 'user', 'message': query});
      _isLoading = true;
    });

    try {
      final result = await ApiService.askQuestion(query);
      setState(() {
        searchResults
            .add({'sender': 'bot', 'message': result['response'] ?? ''});
      });
    } on ApiException catch (e) {
      setState(() {
        searchResults.add({'sender': 'bot', 'message': '⚠️ ${e.message}'});
      });
    } catch (e) {
      setState(() {
        searchResults
            .add({'sender': 'bot', 'message': 'Error: Unable to send request.'});
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _pickFile() async {
    final option = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(context, 'camera'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(context, 'gallery'),
          ),
          ListTile(
            leading: const Icon(Icons.file_copy),
            title: const Text('Choose a file'),
            onTap: () => Navigator.pop(context, 'file'),
          ),
        ],
      ),
    );

    if (option == null) return;

    File? file;
    final picker = ImagePicker();

    switch (option) {
      case 'camera':
        final picked = await picker.pickImage(source: ImageSource.camera);
        if (picked != null) file = File(picked.path);
        break;
      case 'gallery':
        final picked = await picker.pickImage(source: ImageSource.gallery);
        if (picked != null) file = File(picked.path);
        break;
      case 'file':
        final picked = await FilePicker.platform.pickFiles(type: FileType.any);
        if (picked != null) file = File(picked.files.single.path!);
        break;
    }

    if (file != null) {
      setState(() {
        _image = file;
        searchResults.add({'sender': 'user', 'message': '[Image uploaded]'});
        _isLoading = true;
      });

      try {
        final analysis = await ApiService.uploadImageForOcr(file);
        setState(() {
          searchResults.add({'sender': 'bot', 'message': analysis});
        });
      } catch (e) {
        setState(() {
          searchResults.add(
              {'sender': 'bot', 'message': 'Error processing image: $e'});
        });
      }

      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> chatStrings =
        searchResults.map((chat) => jsonEncode(chat)).toList();
    await prefs.setStringList('chatHistory', chatStrings);
  }

  void _clearChat() {
    setState(() => searchResults.clear());
    _saveChatHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          IconButton(icon: const Icon(Icons.clear), onPressed: _clearChat),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: searchResults.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == searchResults.length && _isLoading) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  );
                }
                final chat = searchResults[index];
                bool isUser = chat['sender'] == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue : Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: chat['message'] == '[Image uploaded]' &&
                            _image != null
                        ? Image.file(_image!, height: 200)
                        : Text(chat['message']!,
                            style: const TextStyle(color: Colors.white)),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[900],
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image, color: Colors.white),
                  onPressed: _pickFile,
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        _sendSearchQuery(value.trim());
                        _textController.clear();
                      }
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[850],
                      hintText: 'Search...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: () {
                    final query = _textController.text.trim();
                    if (query.isNotEmpty) {
                      _sendSearchQuery(query);
                      _textController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
