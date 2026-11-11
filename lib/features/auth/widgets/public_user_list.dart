import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:melody/domain/models/server.dart';

/// Horizontal strip of the users a server shows on its sign-in page.
class PublicUserList extends StatelessWidget {
  /// Creates the strip.
  const PublicUserList({
    required this.users,
    required this.onSelected,
    super.key,
  });

  /// Users to show.
  final List<PublicUser> users;

  /// Called with the tapped user.
  final ValueChanged<PublicUser> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = 72 + MediaQuery.textScalerOf(context).scale(14) * 1.6 + 12;
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: users.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final user = users[index];
          final avatar = user.avatar;
          return Semantics(
            button: true,
            label: user.name,
            excludeSemantics: true,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onSelected(user),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: SizedBox(
                  width: 72,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        foregroundImage: avatar == null
                            ? null
                            : CachedNetworkImageProvider(
                                avatar.toString(),
                                maxWidth: 160,
                              ),
                        onForegroundImageError: avatar == null
                            ? null
                            : (_, _) {},
                        child: Text(
                          user.name.characters.firstOrNull?.toUpperCase() ?? '',
                          style: TextStyle(
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
