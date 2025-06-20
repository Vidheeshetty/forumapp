import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/forum_provider.dart';

class SearchFilterWidget extends StatefulWidget {
  @override
  _SearchFilterWidgetState createState() => _SearchFilterWidgetState();
}

class _SearchFilterWidgetState extends State<SearchFilterWidget> {
  final _searchController = TextEditingController();
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ForumProvider>(
      builder: (context, forumProvider, child) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Search bar
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search discussions...',
                        prefixIcon: Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            forumProvider.setSearchQuery('');
                          },
                        )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        forumProvider.setSearchQuery(value);
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  IconButton(
                    icon: Icon(
                      _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
                      color: _showFilters ? Colors.deepPurple : Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        _showFilters = !_showFilters;
                      });
                    },
                  ),
                ],
              ),

              // Filters section
              if (_showFilters) ...[
                SizedBox(height: 16),

                // Sort options
                Row(
                  children: [
                    Text(
                      'Sort by: ',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        children: [
                          _SortChip(
                            label: 'Recent',
                            value: 'recent',
                            isSelected: forumProvider.sortBy == 'recent',
                            onSelected: () => forumProvider.setSortBy('recent'),
                          ),
                          _SortChip(
                            label: 'Popular',
                            value: 'popular',
                            isSelected: forumProvider.sortBy == 'popular',
                            onSelected: () => forumProvider.setSortBy('popular'),
                          ),
                          _SortChip(
                            label: 'Pinned',
                            value: 'pinned',
                            isSelected: forumProvider.sortBy == 'pinned',
                            onSelected: () => forumProvider.setSortBy('pinned'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // Tag filters
                if (forumProvider.availableTags.isNotEmpty) ...[
                  Row(
                    children: [
                      Text(
                        'Tags: ',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      if (forumProvider.selectedTags.isNotEmpty)
                        TextButton(
                          onPressed: forumProvider.clearTagFilters,
                          child: Text(
                            'Clear all',
                            style: TextStyle(color: Colors.deepPurple),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: forumProvider.availableTags.map((tag) {
                      final isSelected = forumProvider.selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.deepPurple : Colors.grey[700],
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          forumProvider.toggleTagFilter(tag);
                        },
                        backgroundColor: Colors.grey[100],
                        selectedColor: Colors.deepPurple.withOpacity(0.2),
                        checkmarkColor: Colors.deepPurple,
                        side: BorderSide(
                          color: isSelected
                              ? Colors.deepPurple
                              : Colors.grey[300]!,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],

              // Active filters summary
              if (forumProvider.selectedTags.isNotEmpty ||
                  forumProvider.searchQuery.isNotEmpty) ...[
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (forumProvider.searchQuery.isNotEmpty)
                        Chip(
                          label: Text(
                            'Search: "${forumProvider.searchQuery}"',
                            style: TextStyle(fontSize: 12),
                          ),
                          onDeleted: () {
                            _searchController.clear();
                            forumProvider.setSearchQuery('');
                          },
                          deleteIcon: Icon(Icons.close, size: 16),
                          backgroundColor: Colors.white,
                        ),
                      ...forumProvider.selectedTags.map((tag) => Chip(
                        label: Text(
                          tag,
                          style: TextStyle(fontSize: 12),
                        ),
                        onDeleted: () => forumProvider.toggleTagFilter(tag),
                        deleteIcon: Icon(Icons.close, size: 16),
                        backgroundColor: Colors.white,
                      )),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onSelected;

  const _SortChip({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : Colors.grey[700],
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: Colors.deepPurple,
      backgroundColor: Colors.grey[100],
      side: BorderSide(
        color: isSelected ? Colors.deepPurple : Colors.grey[300]!,
      ),
    );
  }
}