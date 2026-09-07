import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cakeu/core/theme/app_colors.dart';
import 'package:cakeu/features/chatbot/data/models/chat_message_model.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessageModel message;
  final Function(String base64Str) onShowFullImage;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.onShowFullImage,
  });

  void _copyToClipboard(BuildContext context, String text) {
    final cleanText = text.replaceAll('**', '');
    Clipboard.setData(ClipboardData(text: cleanText));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Pesan disalin ke clipboard', style: TextStyle(fontSize: 12.5)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: AppColors.primaryDarker,
        margin: const EdgeInsets.only(bottom: 80, left: 24, right: 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final timeStr =
        '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _copyToClipboard(context, message.content),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82,
          ),
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: isUser ? AppColors.primaryGradient : null,
            color: isUser ? null : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
              bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
            ),
            border: isUser ? null : Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isUser ? 0.08 : 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (message.imageBase64 != null) ...[
                GestureDetector(
                  onTap: () => onShowFullImage(message.imageBase64!),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 180),
                          width: double.infinity,
                          color: Colors.black12,
                          child: message.imageBytes != null
                              ? Image.memory(
                                  message.imageBytes!,
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                  cacheWidth: 800,
                                )
                              : const SizedBox(),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fullscreen_rounded, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Lihat Foto',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SelectionArea(
                child: _buildFormattedMessageText(message.content, isUser),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 10,
                      color: isUser ? Colors.white70 : AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Tooltip(
                    message: 'Salin pesan',
                    child: InkWell(
                      onTap: () => _copyToClipboard(context, message.content),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                        child: Icon(
                          Icons.copy_rounded,
                          size: 11,
                          color: isUser ? Colors.white60 : AppColors.textTertiary,
                        ),
                      ),
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

  Widget _buildFormattedMessageText(String text, bool isUser) {
    final baseStyle = TextStyle(
      color: isUser ? Colors.white : AppColors.textPrimary,
      fontSize: 13.5,
      height: 1.4,
      fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
    );

    if (!text.contains('**')) {
      return Text(text, style: baseStyle);
    }

    final spans = <TextSpan>[];
    final parts = text.split('**');
    for (int i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      final isBold = i % 2 == 1;
      spans.add(
        TextSpan(
          text: parts[i],
          style: isBold
              ? baseStyle.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isUser ? Colors.white : AppColors.primaryDark,
                )
              : baseStyle,
        ),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
