import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/post.dart';
import '../controllers/community_controller.dart';
import 'post_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Post> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final communityController = Get.find<CommunityController>();
    final allPosts = communityController.posts;

    // 클라이언트 측 검색
    final results = allPosts.where((post) {
      final contentMatch = post.content.toLowerCase().contains(query.toLowerCase());
      final hashtagMatch = post.hashtags.any(
        (tag) => tag.toLowerCase().contains(query.toLowerCase()),
      );
      final userMatch = post.userName.toLowerCase().contains(query.toLowerCase());
      
      return contentMatch || hashtagMatch || userMatch;
    }).toList();

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '게시물 검색...',
            hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
            border: InputBorder.none,
          ),
          style: GoogleFonts.poppins(fontSize: 18),
          onChanged: _performSearch,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _performSearch('');
              },
            ),
        ],
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : _searchController.text.isEmpty
              ? _buildSearchSuggestions()
              : _searchResults.isEmpty
                  ? _buildNoResults()
                  : _buildSearchResults(),
    );
  }

  Widget _buildSearchSuggestions() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '게시물을 검색해보세요',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '내용, 해시태그, 사용자 이름으로 검색 가능합니다',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '검색 결과가 없습니다',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => const Divider(height: 32),
      itemBuilder: (context, index) {
        final post = _searchResults[index];
        return _buildPostItem(post);
      },
    );
  }

  Widget _buildPostItem(Post post) {
    return GestureDetector(
      onTap: () {
        Get.to(
          () => PostDetailScreen(post: post),
          transition: Transition.rightToLeft,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(post.userProfileImage),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  post.userName,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.content,
            style: GoogleFonts.poppins(fontSize: 14),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: post.hashtags.map((tag) {
              return Text(
                tag,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF2D7A4F),
                  fontWeight: FontWeight.w500,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.favorite, size: 16, color: Colors.red),
              const SizedBox(width: 4),
              Text('${post.likes}', style: GoogleFonts.poppins(fontSize: 13)),
              const SizedBox(width: 16),
              const Icon(Icons.chat_bubble_outline, size: 16),
              const SizedBox(width: 4),
              Text('${post.comments}', style: GoogleFonts.poppins(fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

