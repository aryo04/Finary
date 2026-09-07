import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cakeu/core/theme/app_colors.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final XFile? selectedImage;
  final bool isLoading;
  final VoidCallback onPickCamera;
  final VoidCallback onPickGallery;
  final VoidCallback onRemoveImage;
  final VoidCallback onSend;

  const ChatInputBar({
    super.key,
    required this.controller,
    this.focusNode,
    required this.selectedImage,
    required this.isLoading,
    required this.onPickCamera,
    required this.onPickGallery,
    required this.onRemoveImage,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (selectedImage != null) _buildImagePreviewBar(),
        Container(
          padding: EdgeInsets.fromLTRB(
            16,
            10,
            16,
            MediaQuery.of(context).padding.bottom + 10,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              // Tombol Kamera
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isLoading ? null : onPickCamera,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: isLoading ? AppColors.textTertiary : AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Tombol Galeri
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isLoading ? null : onPickGallery,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(
                      Icons.image_rounded,
                      color: isLoading ? AppColors.textTertiary : AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  minLines: 1,
                  maxLines: 6,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: selectedImage != null
                        ? 'Kirim struk / tambah catatan...'
                        : 'Ketik pesan / foto struk...',
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: isLoading ? null : onSend,
                icon: const Icon(Icons.send_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  fixedSize: const Size(44, 44),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreviewBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_rounded, color: AppColors.primaryDarker, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Foto struk terpilih: ${selectedImage!.name}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryDarker),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.cancel_rounded, size: 20, color: AppColors.expense),
            onPressed: onRemoveImage,
          ),
        ],
      ),
    );
  }
}
