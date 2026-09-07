import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cakeu/core/theme/app_colors.dart';
import 'package:cakeu/core/utils/date_formatter.dart';
import 'package:cakeu/core/services/vault_security_service.dart';
import 'package:cakeu/features/categories/presentation/providers/category_provider.dart';
import 'package:cakeu/features/chatbot/data/models/chat_message_model.dart';
import 'package:cakeu/features/chatbot/presentation/providers/chatbot_provider.dart';
import 'package:cakeu/features/chatbot/presentation/widgets/chat_input_bar.dart';
import 'package:cakeu/features/chatbot/presentation/widgets/chat_message_bubble.dart';
import 'package:cakeu/features/chatbot/presentation/widgets/chat_receipt_card.dart';
import 'package:cakeu/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:cakeu/features/wallets/presentation/providers/wallet_provider.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  XFile? _selectedImage;
  String? _base64Image;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatbotProvider>().fetchHistory();
      context.read<CategoryProvider>().fetchCategories();
      context.read<WalletProvider>().fetchWallets();
      context.read<TransactionProvider>().fetchTransactions();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      VaultSecurityService().setPickingMedia(true);
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedImage = picked;
          _base64Image = base64Encode(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil gambar: ${e.toString()}')),
        );
      }
    } finally {
      // Delay slightly before releasing flag to allow Android activity switch back to app
      Future.delayed(const Duration(milliseconds: 500), () {
        VaultSecurityService().setPickingMedia(false);
      });
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty && _base64Image == null) return;

    final categories = context.read<CategoryProvider>().categories;
    final wallets = context.read<WalletProvider>().wallets;

    context.read<ChatbotProvider>().sendMessage(
          text: text,
          categories: categories,
          wallets: wallets,
          base64Image: _base64Image,
          selectedDate: DateTime.now(),
        );

    _messageController.clear();
    setState(() {
      _selectedImage = null;
      _base64Image = null;
    });

    _focusNode.requestFocus();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutQuad,
        );
      }
    });
  }

  void _showFullImage(BuildContext context, String base64Str) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                base64Decode(base64Str),
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            ),
            IconButton.filled(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearChat(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: AppColors.expense, size: 22),
            SizedBox(width: 8),
            Text('Hapus Riwayat Chat?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Semua pesan obrolan dengan Finary AI akan dibersihkan.\n\nData transaksi yang sudah tercatat di dompet tidak akan terhapus.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ChatbotProvider>().clearChatHistory();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Asisten AI Finary'),
        content: const Text(
          '📸 **Scan Struk Belanjaan**:\n'
          'Tap tombol kamera untuk memfoto struk kasir secara langsung.\n'
          'AI otomatis merinci daftar barang, harga satuan, subtotal, diskon, PPN, dan kembalian!\n\n'
          '💬 **Bahasa Santai Sehari-hari**:\n'
          '• "Beli kopi Kenangan 20rb"\n'
          '• "Gaji kantor 6.5 juta"\n'
          '• "Bayar token listrik 100 ribu"',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Finary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 0.8,
                    ),
                  ),
                  child: const Text(
                    'AI',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            tooltip: 'Hapus Riwayat Chat',
            onPressed: () => _confirmClearChat(context),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, size: 20),
            tooltip: 'Petunjuk',
            onPressed: () => _showInfoDialog(context),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          // 1. Chat Messages List (Continuous Timeline)
          Expanded(
            child: Consumer<ChatbotProvider>(
              builder: (context, chatProvider, child) {
                final messages = chatProvider.messages;

                if (chatProvider.isLoading && messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (messages.isEmpty) {
                  return _buildEmptyChatState();
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  addAutomaticKeepAlives: true,
                  addRepaintBoundaries: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final chronoIndex = messages.length - 1 - index;
                    final message = messages[chronoIndex];

                    final showDateSeparator = chronoIndex == 0 ||
                        !AppDateFormatter.isSameDay(
                          message.createdAt,
                          messages[chronoIndex - 1].createdAt,
                        );

                    return _buildMessageItem(context, message, showDateSeparator);
                  },
                );
              },
            ),
          ),

          // 2. Loading Status Indicator saat AI memproses
          Consumer<ChatbotProvider>(
            builder: (context, chatProvider, child) {
              if (!chatProvider.isLoading) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedImage != null
                          ? 'Memindai & mengekstrak struk belanja...'
                          : 'Mengetik balasan...',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            },
          ),

          // 3. Input Bar & Image Preview (Always active)
          Consumer<ChatbotProvider>(
            builder: (context, chatProvider, child) {
              return ChatInputBar(
                controller: _messageController,
                focusNode: _focusNode,
                selectedImage: _selectedImage,
                isLoading: chatProvider.isLoading,
                onPickCamera: () => _pickImage(ImageSource.camera),
                onPickGallery: () => _pickImage(ImageSource.gallery),
                onRemoveImage: () => setState(() {
                  _selectedImage = null;
                  _base64Image = null;
                }),
                onSend: _sendMessage,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.6),
            width: 0.8,
          ),
        ),
        child: Text(
          AppDateFormatter.formatDayTitle(date),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChatState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Mulai Obrolan dengan Finary AI',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ketik pengeluaran, foto struk, atau coba tanyakan hal berikut:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('💵 Di dompet ada berapa?'),
                _buildSuggestionChip('🏦 Saldo di rekening ada berapa?'),
                _buildSuggestionChip('📊 Uang saya tersebar di mana aja?'),
                _buildSuggestionChip('📈 Pemasukan saya dari apa aja?'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      backgroundColor: Colors.white,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onPressed: () {
        _messageController.text = text.replaceFirst(RegExp(r'^[^\w\s]+\s*'), '');
        _sendMessage();
      },
    );
  }

  Widget _buildMessageItem(BuildContext context, ChatMessageModel message, bool showDateSeparator) {
    final isUser = message.isUser;
    final extracted = message.extractedData;

    final hasTicketCard = !isUser &&
        extracted != null &&
        extracted.isTransaction &&
        extracted.amount != null &&
        extracted.amount! > 0;

    // Selalu tampilkan balon teks AI (ucapan selamat / arahan konfirmasi) di atas kartu tiket
    const shouldShowTextBubble = true;

    return RepaintBoundary(
      key: ValueKey(message.id),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showDateSeparator)
            _buildDateSeparator(message.createdAt),
          if (shouldShowTextBubble)
            ChatMessageBubble(
              message: message,
              onShowFullImage: (base64) => _showFullImage(context, base64),
            ),
          if (hasTicketCard)
            ChatReceiptCard(
              message: message,
              extracted: extracted,
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
