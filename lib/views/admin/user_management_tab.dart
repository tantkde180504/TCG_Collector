import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/admin_user.dart';
import '../../services/user_service.dart';

class UserManagementTab extends StatefulWidget {
  const UserManagementTab({super.key});

  @override
  State<UserManagementTab> createState() => _UserManagementTabState();
}

class _UserManagementTabState extends State<UserManagementTab> {
  static const _pageSize = 20;

  List<AdminUser> _allUsers = [];
  Map<String, UserOrderStats> _orderStats = {};
  final Set<String> _selectedUids = {};
  bool _isLoading = true;

  String _searchQuery = '';
  UserRoleFilter _roleFilter = UserRoleFilter.all;
  UserEmailFilter _emailFilter = UserEmailFilter.all;
  UserStatusFilter _statusFilter = UserStatusFilter.all;
  UserSortOption _sortOption = UserSortOption.newest;
  int _currentPage = 0;

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final users = await UserService.instance.getAllAdminUsers();
    final stats = await UserService.instance.getAllUserOrderStats();
    if (!mounted) return;
    setState(() {
      _allUsers = users;
      _orderStats = stats;
      _isLoading = false;
      _currentPage = 0;
      _selectedUids.clear();
    });
  }

  String _removeDiacritics(String str) {
    var withDiacritics = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ';
    var withoutDiacritics = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyydAAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';
    for (int i = 0; i < withDiacritics.length; i++) {
      str = str.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }
    return str;
  }

  List<AdminUser> get _filteredUsers {
    var users = List<AdminUser>.from(_allUsers);

    final query = _removeDiacritics(_searchQuery.trim().toLowerCase());
    if (query.isNotEmpty) {
      users = users.where((u) {
        final nameUnsigned = _removeDiacritics(u.displayName.toLowerCase());
        final emailUnsigned = _removeDiacritics(u.email.toLowerCase());
        final uidUnsigned = _removeDiacritics(u.uid.toLowerCase());
        return nameUnsigned.contains(query) ||
            emailUnsigned.contains(query) ||
            uidUnsigned.contains(query);
      }).toList();
    }

    switch (_roleFilter) {
      case UserRoleFilter.admin:
        users = users.where((u) => u.isAdminRole).toList();
        break;
      case UserRoleFilter.staff:
        users = users.where((u) => u.isStaffRole).toList();
        break;
      case UserRoleFilter.customer:
        users = users.where((u) => u.isCustomerRole).toList();
        break;
      case UserRoleFilter.all:
        break;
    }

    switch (_emailFilter) {
      case UserEmailFilter.verified:
        users = users.where((u) => u.emailVerified).toList();
        break;
      case UserEmailFilter.unverified:
        users = users.where((u) => !u.emailVerified).toList();
        break;
      case UserEmailFilter.all:
        break;
    }

    switch (_statusFilter) {
      case UserStatusFilter.active:
        users = users.where((u) => !u.isDisabled).toList();
        break;
      case UserStatusFilter.disabled:
        users = users.where((u) => u.isDisabled).toList();
        break;
      case UserStatusFilter.all:
        break;
    }

    users.sort((a, b) {
      switch (_sortOption) {
        case UserSortOption.nameAsc:
          return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
        case UserSortOption.newest:
          return _dateOrMin(b.createdAt).compareTo(_dateOrMin(a.createdAt));
        case UserSortOption.oldest:
          return _dateOrMin(a.createdAt).compareTo(_dateOrMin(b.createdAt));
        case UserSortOption.lastLogin:
          return _dateOrMin(b.lastLoginAt).compareTo(_dateOrMin(a.lastLoginAt));
      }
    });

    return users;
  }

  DateTime _dateOrMin(DateTime? date) => date ?? DateTime.fromMillisecondsSinceEpoch(0);

  int get _totalPages {
    final count = _filteredUsers.length;
    if (count == 0) return 1;
    return (count / _pageSize).ceil();
  }

  List<AdminUser> get _pagedUsers {
    final filtered = _filteredUsers;
    final start = _currentPage * _pageSize;
    if (start >= filtered.length) return [];
    final end = (start + _pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  int get _newThisMonth {
    final now = DateTime.now();
    return _allUsers.where((u) {
      final created = u.createdAt;
      return created != null &&
          created.year == now.year &&
          created.month == now.month;
    }).length;
  }

  void _snack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade800 : null,
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  String _formatRelative(DateTime? date) {
    if (date == null) return '—';
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays} ngày trước';
    if (diff.inHours > 0) return '${diff.inHours} giờ trước';
    if (diff.inMinutes > 0) return '${diff.inMinutes} phút trước';
    return 'Vừa xong';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _filteredUsers;
    final paged = _pagedUsers;
    final startIndex = filtered.isEmpty ? 0 : _currentPage * _pageSize + 1;
    final endIndex = (_currentPage * _pageSize + paged.length).clamp(0, filtered.length);

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              children: [
                _buildStatsRow(),
                const SizedBox(height: 16),
                _buildSearchBar(),
                const SizedBox(height: 12),
                _buildFilterRow(),
                const SizedBox(height: 12),
                _buildSortRow(),
                if (_selectedUids.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildBulkActionBar(),
                ],
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: Text('Không tìm thấy người dùng nào.')),
                  )
                else
                  ...paged.map(_buildUserCard),
              ],
            ),
          ),
        ),
        if (filtered.isNotEmpty) _buildPagination(startIndex, endIndex, filtered.length),
      ],
    );
  }

  Widget _buildStatsRow() {
    final total = _allUsers.length;
    final admins = _allUsers.where((u) => u.isAdminRole).length;
    final customers = _allUsers.where((u) => u.isCustomerRole).length;
    final banned = _allUsers.where((u) => u.isDisabled).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Tính toán aspect ratio tự động theo chiều rộng
        final cellWidth = (constraints.maxWidth - 16 * 2 - 12 * 2) / 3;
        final cellHeight = cellWidth * 0.55;
        final aspectRatio = cellWidth / cellHeight;
        final pad = constraints.maxWidth * 0.04;

        return Container(
          padding: EdgeInsets.all(pad),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(pad),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TÓM TẮT NGƯỜI DÙNG',
                style: TextStyle(
                  fontSize: (constraints.maxWidth * 0.03).clamp(10.0, 14.0),
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: pad),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: constraints.maxWidth * 0.03,
                crossAxisSpacing: constraints.maxWidth * 0.03,
                childAspectRatio: aspectRatio,
                children: [
                  _statItem('Users', total.toString(), Colors.amber, constraints),
                  _statItem('Admins', admins.toString(), Colors.orange, constraints),
                  _statItem('Customers', customers.toString(), Colors.blueAccent, constraints),
                  _statItem('Banned', banned.toString(), Colors.redAccent, constraints),
                  _statItem('New (month)', _newThisMonth.toString(), Colors.greenAccent, constraints),
                ],
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _statItem(String label, String value, Color color, BoxConstraints constraints) {
    final dotSize = (constraints.maxWidth * 0.02).clamp(6.0, 10.0);
    final labelFontSize = (constraints.maxWidth * 0.028).clamp(9.0, 13.0);
    final valueFontSize = (constraints.maxWidth * 0.045).clamp(14.0, 22.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            SizedBox(width: dotSize),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: Colors.white54, fontSize: labelFontSize),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: constraints.maxWidth * 0.01),
        Text(
          value,
          style: TextStyle(fontSize: valueFontSize, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Tìm theo tên, email, UID...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _currentPage = 0;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (value) => setState(() {
        _searchQuery = value;
        _currentPage = 0;
      }),
    );
  }

  Widget _buildFilterRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 16) / 3;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(
              width: itemWidth,
              child: _filterDropdown<UserRoleFilter>(
                label: 'Role',
                value: _roleFilter,
                items: const {
                  UserRoleFilter.all: 'Tất cả',
                  UserRoleFilter.admin: 'Admin',
                  UserRoleFilter.staff: 'Staff',
                  UserRoleFilter.customer: 'Customer',
                },
                onChanged: (v) => setState(() {
                  _roleFilter = v;
                  _currentPage = 0;
                }),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _filterDropdown<UserEmailFilter>(
                label: 'Email',
                value: _emailFilter,
                items: const {
                  UserEmailFilter.all: 'Tất cả',
                  UserEmailFilter.verified: 'Đã xác thực',
                  UserEmailFilter.unverified: 'Chưa xác thực',
                },
                onChanged: (v) => setState(() {
                  _emailFilter = v;
                  _currentPage = 0;
                }),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _filterDropdown<UserStatusFilter>(
                label: 'Trạng thái',
                value: _statusFilter,
                items: const {
                  UserStatusFilter.all: 'Tất cả',
                  UserStatusFilter.active: 'Hoạt động',
                  UserStatusFilter.disabled: 'Bị khóa',
                },
                onChanged: (v) => setState(() {
                  _statusFilter = v;
                  _currentPage = 0;
                }),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _filterDropdown<T>({
    required String label,
    required T value,
    required Map<T, String> items,
    required ValueChanged<T> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF2A2A2A),
          style: const TextStyle(fontSize: 12, color: Colors.white),
          items: items.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  Widget _buildSortRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.sort, size: 18, color: Colors.amber),
        const SizedBox(width: 8),
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text('Sắp xếp:', style: TextStyle(color: Colors.white54)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _sortChip('Tên', UserSortOption.nameAsc),
              _sortChip('Mới nhất', UserSortOption.newest),
              _sortChip('Cũ nhất', UserSortOption.oldest),
              _sortChip('Đăng nhập gần đây', UserSortOption.lastLogin),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sortChip(String label, UserSortOption option) {
    final selected = _sortOption == option;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        selectedColor: Colors.amber.withValues(alpha: 0.25),
        checkmarkColor: Colors.amber,
        onSelected: (_) => setState(() {
          _sortOption = option;
          _currentPage = 0;
        }),
      ),
    );
  }

  Widget _buildBulkActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.check_box, size: 18, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                '${_selectedUids.length} đã chọn',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _selectedUids.clear()),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Bỏ chọn', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              _bulkButton('Delete', Icons.delete, Colors.redAccent, _bulkDelete),
              _bulkButton('Disable', Icons.block, Colors.orangeAccent, () => _bulkSetDisabled(true)),
              _bulkButton('Enable', Icons.check_circle, Colors.greenAccent, () => _bulkSetDisabled(false)),
              _bulkButton('Change Role', Icons.admin_panel_settings, Colors.blueAccent, _bulkChangeRole),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bulkButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(icon, size: 14, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 11)),
    );
  }

  Widget _buildUserCard(AdminUser user) {
    final stats = _orderStats[user.uid] ?? const UserOrderStats();
    final lastPurchase = stats.lastPurchaseAt ?? user.lastPurchaseAt;
    final isSelected = _selectedUids.contains(user.uid);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.amber.withValues(alpha: 0.5) : Colors.white10,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: isSelected,
                activeColor: Colors.amber,
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _selectedUids.add(user.uid);
                  } else {
                    _selectedUids.remove(user.uid);
                  }
                }),
              ),
              _userAvatar(user, radius: 20),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  user.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (user.isDisabled)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Banned', style: TextStyle(fontSize: 10, color: Colors.redAccent)),
                ),
              _roleBadge(user.role),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.email.isEmpty ? 'No email' : user.email),
              Text('UID: ${user.uid}', style: const TextStyle(fontSize: 10, color: Colors.white38)),
              const SizedBox(height: 4),
              Text(
                'Last login: ${_formatRelative(user.lastLoginAt)} · Orders: ${stats.orderCount}',
                style: const TextStyle(fontSize: 11, color: Colors.white54),
              ),
              if (lastPurchase != null)
                Text(
                  'Last purchase: ${_formatRelative(lastPurchase)}',
                  style: const TextStyle(fontSize: 11, color: Colors.white38),
                ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            color: const Color(0xFF2A2A2A),
            onSelected: (action) => _handleAction(action, user),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'view', child: Text('View')),
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'role', child: Text('Change Role')),
              PopupMenuItem(value: 'reset', child: Text('Reset Password')),
              PopupMenuItem(value: 'disable', child: Text('Disable')),
              PopupMenuItem(value: 'enable', child: Text('Enable')),
              PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
          onTap: () => _showUserDetail(user),
        ),
      ),
    );
  }

  Widget _userAvatar(AdminUser user, {double radius = 28}) {
    final url = user.photoUrl;
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(url),
        onBackgroundImageError: (_, __) {},
        child: url.isEmpty ? _avatarFallback(user, radius) : null,
      );
    }
    return _avatarFallback(user, radius);
  }

  Widget _avatarFallback(AdminUser user, double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.amber,
      child: Text(
        user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: radius * 0.7),
      ),
    );
  }

  Widget _roleBadge(UserRole role) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(role.label, style: const TextStyle(fontSize: 10, color: Colors.amber)),
    );
  }

  Widget _buildPagination(int start, int end, int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Text('Showing $start-$end of $total',
              style: const TextStyle(fontSize: 12, color: Colors.white54)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 0
                ? () => setState(() => _currentPage--)
                : null,
          ),
          ...List.generate(_totalPages.clamp(0, 5), (i) {
            int page;
            if (_totalPages <= 5) {
              page = i;
            } else if (_currentPage < 3) {
              page = i;
            } else if (_currentPage > _totalPages - 4) {
              page = _totalPages - 5 + i;
            } else {
              page = _currentPage - 2 + i;
            }
            final isActive = page == _currentPage;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: InkWell(
                onTap: () => setState(() => _currentPage = page),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.amber : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${page + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.black : Colors.white70,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages - 1
                ? () => setState(() => _currentPage++)
                : null,
          ),
        ],
      ),
    );
  }

  void _handleAction(String action, AdminUser user) {
    switch (action) {
      case 'view':
        _showUserDetail(user);
        break;
      case 'edit':
        _showEditDialog(user);
        break;
      case 'role':
        _showChangeRoleDialog([user]);
        break;
      case 'reset':
        _resetPassword(user);
        break;
      case 'disable':
        _setDisabled([user.uid], true);
        break;
      case 'enable':
        _setDisabled([user.uid], false);
        break;
      case 'delete':
        _confirmDelete([user]);
        break;
    }
  }

  void _showUserDetail(AdminUser user) {
    final stats = _orderStats[user.uid] ?? const UserOrderStats();
    final lastPurchase = stats.lastPurchaseAt ?? user.lastPurchaseAt;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(child: _userAvatar(user, radius: 40)),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  user.displayName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              Center(
                child: Text(user.email, style: const TextStyle(color: Colors.white54)),
              ),
              const SizedBox(height: 8),
              Center(child: _roleBadge(user.role)),
              const SizedBox(height: 24),
              _detailRow('UID', user.uid),
              _detailRow('Ngày tạo', _formatDate(user.createdAt)),
              _detailRow('Lần đăng nhập gần nhất', _formatDate(user.lastLoginAt)),
              _detailRow('Email xác thực', user.emailVerified ? 'Đã xác thực' : 'Chưa xác thực'),
              _detailRow('Trạng thái', user.isDisabled ? 'Bị khóa' : 'Đang hoạt động'),
              _detailRow('Số điện thoại', user.phone ?? '—'),
              _detailRow('Địa chỉ', user.address ?? '—'),
              _detailRow('Số đơn hàng', stats.orderCount.toString()),
              _detailRow('Tổng chi tiêu', '${stats.totalSpent.toStringAsFixed(0)} PG'),
              const Divider(height: 32),
              const Text('Nhật ký hoạt động',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
              const SizedBox(height: 12),
              _activityTile(Icons.login, 'Last Login', _formatDate(user.lastLoginAt)),
              _activityTile(Icons.person_add, 'Created', _formatDate(user.createdAt)),
              _activityTile(Icons.shopping_bag, 'Last Purchase', _formatRelative(lastPurchase)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditDialog(user);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Chỉnh sửa'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showChangeRoleDialog([user]);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                      icon: const Icon(Icons.admin_panel_settings, color: Colors.black),
                      label: const Text('Change Role', style: TextStyle(color: Colors.black)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(color: Colors.white54)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _activityTile(IconData icon, String label, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.amber, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 13)),
      subtitle: Text(value, style: const TextStyle(fontSize: 12, color: Colors.white54)),
    );
  }

  void _showEditDialog(AdminUser user) {
    final nameCtrl = TextEditingController(text: user.displayName);
    final emailCtrl = TextEditingController(text: user.email);
    final avatarCtrl = TextEditingController(text: user.photoUrl ?? '');
    final phoneCtrl = TextEditingController(text: user.phone ?? '');
    final addressCtrl = TextEditingController(text: user.address ?? '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Chỉnh sửa thông tin'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Họ tên')),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: avatarCtrl, decoration: const InputDecoration(labelText: 'Avatar URL')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Số điện thoại')),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Địa chỉ'), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final ok = await UserService.instance.adminUpdateUser(user.uid, {
                'display_name': nameCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'photo_url': avatarCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
                'address': addressCtrl.text.trim(),
              });
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              if (ok) {
                _snack('Cập nhật thành công!');
                await _loadData();
              } else {
                _snack('Cập nhật thất bại.', isError: true);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangeRoleDialog(List<AdminUser> users) async {
    UserRole selectedRole = users.length == 1 ? users.first.role : UserRole.customer;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(users.length == 1 ? 'Change Role' : 'Change Role (${users.length} users)'),
          content: DropdownButtonFormField<UserRole>(
            initialValue: selectedRole,
            dropdownColor: const Color(0xFF2A2A2A),
            decoration: const InputDecoration(labelText: 'Role'),
            items: UserRole.values
                .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                .toList(),
            onChanged: (v) {
              if (v != null) setDialogState(() => selectedRole = v);
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              child: const Text('Xác nhận', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    final uids = users.map((u) => u.uid).toList();
    final ok = await UserService.instance.adminBulkUpdate(uids, {
      'role': selectedRole.firestoreValue,
    });
    if (ok) {
      _snack('Đã cập nhật role.');
      await _loadData();
    } else {
      _snack('Cập nhật role thất bại.', isError: true);
    }
  }

  Future<void> _resetPassword(AdminUser user) async {
    if (user.email.isEmpty) {
      _snack('User không có email.', isError: true);
      return;
    }
    final ok = await UserService.instance.adminSendPasswordReset(user.email);
    _snack(ok ? 'Đã gửi email reset mật khẩu.' : 'Gửi email thất bại.', isError: !ok);
  }

  Future<void> _setDisabled(List<String> uids, bool disabled) async {
    final ok = await UserService.instance.adminBulkUpdate(uids, {'is_disabled': disabled});
    if (ok) {
      _snack(disabled ? 'Đã khóa tài khoản.' : 'Đã mở khóa tài khoản.');
      await _loadData();
    } else {
      _snack('Thao tác thất bại.', isError: true);
    }
  }

  Future<void> _confirmDelete(List<AdminUser> users) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete User?'),
        content: Text(
          users.length == 1
              ? 'Bạn có chắc muốn xóa "${users.first.displayName}"? Thao tác này không thể hoàn tác.'
              : 'Bạn có chắc muốn xóa ${users.length} tài khoản? Thao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    var success = 0;
    for (final user in users) {
      if (await UserService.instance.adminDeleteUser(user.uid)) success++;
    }
    _snack('Đã xóa $success/${users.length} tài khoản.');
    await _loadData();
  }

  Future<void> _bulkDelete() async {
    final users = _allUsers.where((u) => _selectedUids.contains(u.uid)).toList();
    await _confirmDelete(users);
  }

  Future<void> _bulkSetDisabled(bool disabled) async {
    await _setDisabled(_selectedUids.toList(), disabled);
    setState(() => _selectedUids.clear());
  }

  Future<void> _bulkChangeRole() async {
    final users = _allUsers.where((u) => _selectedUids.contains(u.uid)).toList();
    await _showChangeRoleDialog(users);
    setState(() => _selectedUids.clear());
  }
}
