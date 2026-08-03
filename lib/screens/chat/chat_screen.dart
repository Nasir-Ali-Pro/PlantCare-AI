import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/chat_provider.dart';
import '../../providers/garden_provider.dart';
import '../../providers/shop_provider.dart';
import '../../models/shop_product.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  // Track gesture recognizers so they can be disposed to prevent memory leaks
  final List<TapGestureRecognizer> _tapRecognizers = [];

  final List<String> _quickPrompts = [
    "Why are my plant leaves turning yellow?",
    "How often should I water my succulents?",
    "What are signs of root rot in houseplants?",
    "Best organic fertilizer for tomato plants?",
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    for (final r in _tapRecognizers) {
      r.dispose();
    }
    _tapRecognizers.clear();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text, ChatProvider chatProvider, GardenProvider gardenProvider) {
    if (text.trim().isEmpty) return;
    
    String gardenContext = '';
    if (gardenProvider.plants.isNotEmpty) {
      final plantListStr = gardenProvider.plants
          .map((p) => "${p.nickname} (Species: ${p.species}, Health: ${p.healthScore}%)")
          .join(", ");
      gardenContext = "User has these plants: $plantListStr.";
    }

    chatProvider.sendMessage(text.trim(), gardenContext: gardenContext);
    _messageController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final gardenProvider = Provider.of<GardenProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.15),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.eco_rounded, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Care Assistant',
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Plants & Gardening Expert',
                  style: TextStyle(
                    color: AppColors.onSurfaceMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Clear chat',
            onPressed: () {
              Provider.of<ChatProvider>(context, listen: false).clearChat();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Conversation cleared!'),
                  backgroundColor: AppColors.surfaceElevated,
                ),
              );
            },
            icon: const Icon(Icons.cleaning_services_rounded, color: AppColors.onSurfaceMuted),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<ChatProvider>(
          builder: (context, chatProvider, child) {
            _scrollToBottom();

            return Column(
              children: [
                // Active consultation context banner
                if (chatProvider.activeConsultationReport != null) ...[
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.medical_services_outlined, color: AppColors.primary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "AI Doctor Consultation",
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              Text(
                                "${chatProvider.activeConsultationReport!.plantName} • ${chatProvider.activeConsultationReport!.diseaseName}",
                                style: const TextStyle(
                                  color: AppColors.onSurface,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.close_rounded, color: AppColors.onSurfaceMuted, size: 18),
                          onPressed: () => chatProvider.clearConsultation(),
                        ),
                      ],
                    ),
                  ),
                ],

                // Messages List
                Expanded(
                  child: chatProvider.messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.eco_rounded, size: 56, color: AppColors.primary.withValues(alpha: 0.3)),
                              const SizedBox(height: 16),
                              Text(
                                'Start a conversation',
                                style: TextStyle(
                                  color: AppColors.onSurfaceMuted,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ask me anything about plant care, diseases,\nwatering schedules, or soil health.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.onSurfaceFaint,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          itemCount: chatProvider.messages.length,
                          itemBuilder: (context, index) {
                            final message = chatProvider.messages[index];
                            return _buildChatBubble(message)
                                .animate()
                                .fade(duration: 250.ms)
                                .slideY(begin: 0.05);
                          },
                        ),
                ),

                // Typing indicator
                if (chatProvider.isTyping) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.12),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(Icons.eco_rounded, color: AppColors.primary, size: 14),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(18),
                              topRight: Radius.circular(18),
                              bottomRight: Radius.circular(18),
                            ),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildTypingDot(0),
                              const SizedBox(width: 4),
                              _buildTypingDot(150),
                              const SizedBox(width: 4),
                              _buildTypingDot(300),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Quick Prompt Chips
                if (chatProvider.messages.length <= 1 && !chatProvider.isTyping) ...[
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _quickPrompts.length,
                      itemBuilder: (context, index) {
                        final prompt = _quickPrompts[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ActionChip(
                            label: Text(
                              prompt,
                              style: const TextStyle(color: AppColors.onSurface, fontSize: 11.5),
                            ),
                            backgroundColor: AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            onPressed: () => _sendMessage(prompt, chatProvider, gardenProvider),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Message Input Box
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: Border(
                      top: BorderSide(color: AppColors.border.withValues(alpha: 0.5), width: 0.5),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: const TextStyle(color: AppColors.onSurface, fontSize: 14),
                          maxLines: 4,
                          minLines: 1,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            hintText: 'Ask about plant care, diseases, soil...',
                            hintStyle: const TextStyle(color: AppColors.onSurfaceFaint, fontSize: 13),
                            filled: true,
                            fillColor: AppColors.surface,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: const BorderSide(color: AppColors.border, width: 1.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: const BorderSide(color: AppColors.border, width: 1.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          onPressed: () {
                            _sendMessage(_messageController.text, chatProvider, gardenProvider);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTypingDot(int delayMs) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: AppColors.onSurfaceMuted,
        borderRadius: BorderRadius.circular(4),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(0.5, 0.5),
          duration: 600.ms,
          delay: Duration(milliseconds: delayMs),
          curve: Curves.easeInOut,
        )
        .then()
        .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1, 1),
          duration: 600.ms,
        );
  }

  Widget _buildChatBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isUser) ...[
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 2),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.eco_rounded, color: AppColors.primary, size: 14),
            ),
          ),
        ],
        Flexible(
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 18),
              ),
              border: Border.all(
                color: isUser
                    ? AppColors.primary.withValues(alpha: 0.35)
                    : AppColors.border,
                width: 1,
              ),
            ),
            child: _buildMessageContent(message.text),
          ),
        ),
        if (isUser) ...[
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 2),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
              child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 14),
            ),
          ),
        ],
      ],
    );
  }

  /// Builds message content, detecting embedded Amazon product links
  /// and rendering them as rich product cards instead of raw URLs.
  Widget _buildMessageContent(String text) {
    // Check if there are any Amazon links in the text
    final amazonRegex = RegExp(r'https://www\.amazon\.com/dp/([A-Z0-9]{10})\?tag=\S+');
    final hasAmazonLink = amazonRegex.hasMatch(text);

    if (!hasAmazonLink) {
      return _buildMarkdownText(
        text,
        const TextStyle(color: AppColors.onSurface, fontSize: 13.5, height: 1.5),
      );
    }

    // Split text around Amazon links and render product cards
    final List<Widget> widgets = [];
    final parts = text.split(amazonRegex);
    final matches = amazonRegex.allMatches(text).toList();

    // Find the matching ShopProduct for a given URL
    ShopProduct? findProduct(String asin) {
      try {
        return ShopProduct.defaultProducts.firstWhere((p) => p.asin == asin);
      } catch (_) {
        return null;
      }
    }

    for (int i = 0; i < parts.length; i++) {
      // Add text before/between links
      final trimmedPart = parts[i].trim();
      if (trimmedPart.isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildMarkdownText(
              trimmedPart,
              const TextStyle(color: AppColors.onSurface, fontSize: 13.5, height: 1.5),
            ),
          ),
        );
      }

      // Add product card for each matched link
      if (i < matches.length) {
        final fullUrl = matches[i].group(0)!;
        final asin = matches[i].group(1)!;
        final product = findProduct(asin);

        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: product != null
                ? _buildProductCard(product)
                : _buildRawLink(fullUrl),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }

  /// Renders a rich product card for matched Amazon products inside AI Chat
  Widget _buildProductCard(ShopProduct product) {
    final assetPath = 'assets/images/shop/${product.id}.jpg';

    return Consumer<ShopProvider>(
      builder: (context, shopProvider, _) {
        final isFav = shopProvider.isFavorite(product.id);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image header with 3-tier fallback & badge overlays
              SizedBox(
                height: 130,
                width: double.infinity,
                child: Stack(
                  children: [
                    // 3-Tier Image Loader
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                        child: Image.asset(
                          assetPath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, err, stack) {
                            if (product.imageUrl.isNotEmpty && product.imageUrl.startsWith('http')) {
                              return CachedNetworkImage(
                                imageUrl: product.imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: AppColors.backgroundLight),
                                errorWidget: (context, url, error) => Container(
                                  color: AppColors.surface,
                                  child: const Center(
                                    child: Icon(
                                      Icons.local_florist_rounded,
                                      color: AppColors.primary,
                                      size: 44,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return Container(
                              color: AppColors.surface,
                              child: const Center(
                                child: Icon(
                                  Icons.local_florist_rounded,
                                  color: AppColors.primary,
                                  size: 44,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Top gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.5),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.4),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Category Badge (Top Left)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.category.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                    // Wishlist Heart Button (Top Right)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () {
                          shopProvider.toggleFavorite(product.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isFav
                                    ? 'Removed ${product.title} from wishlist'
                                    : 'Added ${product.title} to wishlist',
                              ),
                              backgroundColor: AppColors.primary,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isFav ? AppTheme.dangerRed : Colors.white24,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFav ? AppTheme.dangerRed : Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Product Info Body
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.accent, size: 15),
                        const SizedBox(width: 3),
                        Text(
                          '${product.rating}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${product.reviewCount} reviews)',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            product.price,
                            style: const TextStyle(
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                    const SizedBox(height: 8),

                    // Action Buttons Row
                    Row(
                      children: [
                        // Share Button
                        InkWell(
                          onTap: () {
                            final text =
                                "Check out this recommendation from PlantCare AI:\n\n"
                                "${product.title}\n"
                                "Price: ${product.price}\n"
                                "Rating: ⭐ ${product.rating}\n\n"
                                "Link: ${product.affiliateUrl}";
                            Share.share(text, subject: product.title);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.share_rounded,
                              color: Colors.white70,
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Wishlist Quick Toggle
                        InkWell(
                          onTap: () => shopProvider.toggleFavorite(product.id),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isFav
                                  ? AppTheme.dangerRed.withValues(alpha: 0.15)
                                  : Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isFav
                                    ? AppTheme.dangerRed.withValues(alpha: 0.4)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  color: isFav ? AppTheme.dangerRed : Colors.white70,
                                  size: 15,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isFav ? 'Saved' : 'Save',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isFav ? AppTheme.dangerRed : Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Primary Buy CTA Button
                        ElevatedButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse(product.affiliateUrl);
                            try {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } catch (_) {}
                          },
                          icon: const Icon(Icons.shopping_cart_rounded, size: 14),
                          label: const Text(
                            'View on Amazon',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Fallback for Amazon links not in the local catalog
  Widget _buildRawLink(String url) {
    return GestureDetector(
      onTap: () async {
        try {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        } catch (_) {}
      },
      child: Text(
        url,
        style: const TextStyle(
          color: AppColors.accentLight,
          fontSize: 13,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _buildMarkdownText(String text, TextStyle baseStyle) {
    final List<Widget> children = [];
    final List<String> lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.isEmpty) {
        children.add(const SizedBox(height: 6));
        continue;
      }

      if (line.startsWith('#')) {
        final cleanHeader = line.replaceAll(RegExp(r'^#+\s*'), '');
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 10.0, bottom: 4.0),
            child: Text(
              cleanHeader,
              style: baseStyle.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: baseStyle.fontSize! + 1.5,
                color: AppColors.onSurface,
              ),
            ),
          ),
        );
        continue;
      }

      if (line.startsWith('*') || line.startsWith('-')) {
        final cleanBullet = line.replaceFirst(RegExp(r'^[\*\-]\s*'), '');
        children.add(
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 5.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: baseStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Expanded(
                  child: _buildLineWithRichFormatting(context, cleanBullet, baseStyle),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: _buildLineWithRichFormatting(context, line, baseStyle),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _buildLineWithRichFormatting(BuildContext context, String text, TextStyle baseStyle) {
    final List<InlineSpan> spans = [];
    // Regex for non-Amazon URLs and bold text; Amazon links are handled separately
    final RegExp regex = RegExp(r'(https?://(?!www\.amazon\.com)[^\s]+)|(\*\*(.*?)\*\*)');

    int lastIndex = 0;
    for (final Match match in regex.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }

      final urlMatch = match.group(1);
      final boldMatch = match.group(3);

      if (urlMatch != null) {
        String cleanUrl = urlMatch;
        String trailing = "";
        while (cleanUrl.isNotEmpty &&
            (cleanUrl.endsWith('.') || cleanUrl.endsWith(')') || cleanUrl.endsWith(','))) {
          trailing = cleanUrl[cleanUrl.length - 1] + trailing;
          cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
        }

        // Track the recognizer so it can be disposed
        final recognizer = TapGestureRecognizer()
          ..onTap = () async {
            try {
              await launchUrl(Uri.parse(cleanUrl), mode: LaunchMode.externalApplication);
            } catch (_) {}
          };
        _tapRecognizers.add(recognizer);

        spans.add(TextSpan(
          text: cleanUrl,
          style: baseStyle.copyWith(
            color: AppColors.accentLight,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.bold,
          ),
          recognizer: recognizer,
        ));

        if (trailing.isNotEmpty) {
          spans.add(TextSpan(text: trailing, style: baseStyle));
        }
      } else if (boldMatch != null) {
        spans.add(TextSpan(
          text: boldMatch,
          style: baseStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ));
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex), style: baseStyle));
    }

    return RichText(text: TextSpan(children: spans));
  }
}
