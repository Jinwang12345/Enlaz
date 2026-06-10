import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chat_service.dart';
import '../providers/user_provider.dart';

class AddFriendScreen extends ConsumerStatefulWidget {
  const AddFriendScreen({super.key});

  @override
  ConsumerState<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends ConsumerState<AddFriendScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  final Map<String, bool> _addingStatus = {}; // userId -> isAdding

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final currentUser = ref.read(userProvider);
    final currentUserId = currentUser?.id ?? '';
    final chatService = ref.read(chatServiceProvider);

    try {
      final results = await chatService.searchUsers(query, currentUserId);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error performing search: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _addContact(Map<String, dynamic> targetUser) async {
    final targetUserId = targetUser['id'] as String;
    final targetUserEmail = targetUser['email'] as String;
    
    setState(() {
      _addingStatus[targetUserId] = true;
    });

    final currentUser = ref.read(userProvider);
    final currentUserId = currentUser?.id ?? '';
    final chatService = ref.read(chatServiceProvider);

    try {
      final response = await chatService.addContact(currentUserId, targetUserEmail);
      setState(() {
        _addingStatus[targetUserId] = false;
      });

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${targetUser['name']} agregado con éxito!'),
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Error al agregar contacto'),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _addingStatus[targetUserId] = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF111827), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Add Friend',
          style: TextStyle(color: Color(0xFF111827), fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Input Container
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.search, color: Color(0xFF94A3B8)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _performSearch,
                      style: const TextStyle(fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'Search by name or email...',
                        hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Color(0xFF94A3B8), size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch('');
                      },
                    ),
                ],
              ),
            ),
          ),
          
          // Results
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEC5B13)),
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFFDC2626), fontSize: 15),
                        ),
                      )
                    : _searchController.text.trim().isEmpty
                        ? _buildEmptyState()
                        : _searchResults.isEmpty
                            ? _buildNoResultsState(_searchController.text)
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _searchResults.length,
                                itemBuilder: (context, index) {
                                  final user = _searchResults[index];
                                  return _buildUserTile(user);
                                },
                              ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final currentUser = ref.watch(userProvider);
    final String userText = currentUser != null 
        ? 'Sesión iniciada como:\n${currentUser.name} (${currentUser.email})' 
        : 'Sesión no iniciada';

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 100,
              width: 100,
              decoration: const BoxDecoration(
                color: Color(0xFFFFECE5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_add_alt_1,
                size: 50,
                color: Color(0xFFEC5B13),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Encuentra amigos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 10),
            const Text(
              'Introduce el nombre o correo electrónico de un usuario registrado en Enlaz.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                userText,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(String query) {
    final currentUser = ref.watch(userProvider);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 100,
              width: 100,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_search_outlined,
                size: 50,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sin resultados',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 10),
            Text(
              'No se encontró ningún usuario con el nombre o correo "$query".',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
            ),
            if (currentUser != null && (query.toLowerCase() == currentUser.email.toLowerCase() || query.toLowerCase() == currentUser.name.toLowerCase()))
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Nota: Estás buscando tu propio usuario (${currentUser.email}), el cual se excluye de la búsqueda.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Color(0xFFEA580C), fontWeight: FontWeight.w500),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final userId = user['id'] as String;
    final name = user['name'] as String? ?? 'No name';
    final email = user['email'] as String? ?? '';
    final isAdding = _addingStatus[userId] ?? false;

    // Use nice gradient for user avatar placeholder
    final colorIndex = name.hashCode % 5;
    final gradients = [
      [const Color(0xFFEC5B13), const Color(0xFFFF8C39)],
      [const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
      [const Color(0xFF10B981), const Color(0xFF34D399)],
      [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)],
      [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
    ];
    final selectedGradient = gradients[colorIndex];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: selectedGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            isAdding
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEC5B13)),
                    ),
                  )
                : TextButton(
                    onPressed: () => _addContact(user),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFFFECE5),
                      foregroundColor: const Color(0xFFEC5B13),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Add',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
