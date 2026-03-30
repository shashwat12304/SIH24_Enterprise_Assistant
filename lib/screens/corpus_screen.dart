import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mokshayani/services/api_service.dart';

class CorpusScreen extends StatefulWidget {
  const CorpusScreen({super.key});

  @override
  State<CorpusScreen> createState() => _CorpusScreenState();
}

class _CorpusScreenState extends State<CorpusScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Corpus'),
        backgroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: 'My Corpus'),
            Tab(text: 'Org. Corpus'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CorpusList(type: 'user'),
          _CorpusList(type: 'org'),
        ],
      ),
    );
  }
}

class _CorpusList extends StatefulWidget {
  final String type;
  const _CorpusList({required this.type});

  @override
  State<_CorpusList> createState() => _CorpusListState();
}

class _CorpusListState extends State<_CorpusList> {
  List<Map<String, dynamic>> files = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFiles();
  }

  Future<void> _fetchFiles() async {
    try {
      final result = await ApiService.fetchCorpus(widget.type);
      setState(() {
        files = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        // Show default corpus files
        files = [
          {'name': 'hr.pdf', 'uploadDate': 1694870400.0},
          {'name': 'it_support.PDF', 'uploadDate': 1694946000.0},
          {'name': 'corp_events.pdf', 'uploadDate': 1695032400.0},
          {'name': 'prd.pdf', 'uploadDate': 1695118800.0},
          {'name': 'playbook.pdf', 'uploadDate': 1695205200.0},
        ];
      });
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is num) {
      final date = DateTime.fromMillisecondsSinceEpoch(
          (timestamp * 1000).toInt());
      return DateFormat('yyyy-MM-dd').format(date);
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (files.isEmpty) {
      return const Center(
        child: Text('No files uploaded yet.',
            style: TextStyle(color: Colors.white54)),
      );
    }

    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return Container(
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(color: Colors.grey.shade800, width: 0.5)),
          ),
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
            title: Text(file['name'] ?? '',
                style: const TextStyle(color: Colors.white)),
            trailing: Text(
              _formatDate(file['uploadDate']),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        );
      },
    );
  }
}
