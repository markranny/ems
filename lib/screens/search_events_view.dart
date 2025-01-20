// search_events_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../models/events.dart';
import 'dart:async';

class SearchEventsView extends StatefulWidget {
  const SearchEventsView({Key? key}) : super(key: key);

  @override
  _SearchEventsViewState createState() => _SearchEventsViewState();
}

class _SearchEventsViewState extends State<SearchEventsView> {
  final TextEditingController _searchController = TextEditingController();
  List<Events> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final results = await authProvider.searchEvents(query);

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error searching events: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Widget _buildSearchResult(Events event) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: event.hasImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  event.imageUrl!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[200],
                      child: Icon(Icons.event, color: Colors.grey[400]),
                    );
                  },
                ),
              )
            : Container(
                width: 50,
                height: 50,
                color: Colors.grey[200],
                child: Icon(Icons.event, color: Colors.grey[400]),
              ),
        title: Text(
          event.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.readableDate),
            Text(event.location),
          ],
        ),
        onTap: () {
          // Add navigation to event details
          Navigator.pop(context, event);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search events...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey[400]),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchResults = [];
                      });
                    },
                  )
                : null,
          ),
          style: const TextStyle(fontSize: 16),
          onChanged: _onSearchChanged,
        ),
      ),
      body: Column(
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!_isLoading &&
              _searchResults.isEmpty &&
              _searchController.text.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No events found'),
            ),
          if (_searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) =>
                    _buildSearchResult(_searchResults[index]),
              ),
            ),
        ],
      ),
    );
  }
}
