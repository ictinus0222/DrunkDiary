import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/app_theme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../profile/models/user_model.dart';
import '../../profile/providers/profile_providers.dart';

class TagFriendsSelector extends ConsumerWidget {
  final List<UserModel> selectedFriends;
  final ValueChanged<List<UserModel>> onFriendsChanged;

  const TagFriendsSelector({
    super.key,
    required this.selectedFriends,
    required this.onFriendsChanged,
  });

  void _showFriendsSelectionBottomSheet(BuildContext context, WidgetRef ref) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: customColors.deepCardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Consumer(
              builder: (context, ref, _) {
                final friendsAsync = ref.watch(userFriendsProvider);

                return Column(
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: customColors.borderDark,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text(
                        'ENJOYED TOGETHER?',
                        style: AppTextStyles.section.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white10),
                    Expanded(
                      child: friendsAsync.when(
                        loading: () => const Center(
                          child: CircularProgressIndicator(color: Colors.amber),
                        ),
                        error: (err, _) => Center(
                          child: Text('Error loading friends: $err', style: const TextStyle(color: Colors.white70)),
                        ),
                        data: (friends) {
                          if (friends.isEmpty) {
                            return const Center(
                              child: Text(
                                "No friends to tag.\nAdd friends in search to share logs!",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white30, height: 1.4),
                              ),
                            );
                          }

                          return ListView.builder(
                            controller: scrollController,
                            itemCount: friends.length,
                            itemBuilder: (context, index) {
                              final friend = friends[index];
                              final isSelected = selectedFriends.any((f) => f.id == friend.id);

                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: customColors.borderDark,
                                  backgroundImage: friend.photoUrl != null
                                      ? CachedNetworkImageProvider(friend.photoUrl!)
                                      : null,
                                  child: friend.photoUrl == null
                                      ? const Icon(Icons.person, color: Colors.white24, size: 20)
                                      : null,
                                ),
                                title: Text(
                                  friend.displayName,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '@${friend.username}',
                                  style: TextStyle(color: customColors.textMuted, fontSize: 12),
                                ),
                                trailing: Checkbox(
                                  value: isSelected,
                                  activeColor: Colors.amber,
                                  checkColor: Colors.black,
                                  onChanged: (checked) {
                                    final newList = List<UserModel>.from(selectedFriends);
                                    if (checked == true) {
                                      newList.add(friend);
                                    } else {
                                      newList.removeWhere((f) => f.id == friend.id);
                                    }
                                    onFriendsChanged(newList);
                                  },
                                ),
                                onTap: () {
                                  final newList = List<UserModel>.from(selectedFriends);
                                  if (isSelected) {
                                    newList.removeWhere((f) => f.id == friend.id);
                                  } else {
                                    newList.add(friend);
                                  }
                                  onFriendsChanged(newList);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Shared With',
              style: AppTextStyles.title.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            GestureDetector(
              onTap: () => _showFriendsSelectionBottomSheet(context, ref),
              child: Row(
                children: [
                  Icon(Icons.add, color: colorScheme.primary, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Tag Friends',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (selectedFriends.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: customColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: customColors.borderDark),
            ),
            child: Text(
              'No friends tagged yet.',
              style: TextStyle(color: customColors.textMuted, fontSize: 13),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: customColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: customColors.borderDark),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: selectedFriends.map((friend) {
                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: Colors.amber,
                    backgroundImage: friend.photoUrl != null
                        ? CachedNetworkImageProvider(friend.photoUrl!)
                        : null,
                    child: friend.photoUrl == null
                        ? const Icon(Icons.person, size: 12, color: Colors.black)
                        : null,
                  ),
                  label: Text(
                    friend.displayName,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  backgroundColor: customColors.deepCardBackground,
                  deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white54),
                  onDeleted: () {
                    final newList = List<UserModel>.from(selectedFriends);
                    newList.removeWhere((f) => f.id == friend.id);
                    onFriendsChanged(newList);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: customColors.borderDark),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
