import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/chat_provider.dart';
import '../../providers/garden_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _quickPrompts = [
    "Why are my plant leaves turning yellow?",
    "How often should I water my indoor plants?",
    "Is a Tomato plant safe for cats and dogs?",
    "What organic fertilizer is best for early blight?"
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
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
        title: const Text('AI Care Assistant', style: TextStyle(color: AppColors.onSurface, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () {
              Provider.of<ChatProvider>(context, listen: false).clearChat();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Conversation cleared!'), backgroundColor: AppColors.surfaceElevated),
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
                if (chatProvider.activeConsultationReport != null) ...[
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.medical_services_outlined, color: AppColors.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "AI Doctor Consultation",
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${chatProvider.activeConsultationReport!.plantName} • ${chatProvider.activeConsultationReport!.diseaseName}",
                                style: const TextStyle(
                                  color: AppColors.onSurface,
                                  fontSize: 13,
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
                          onPressed: () {
                            chatProvider.clearConsultation();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                // Messages List
                Expanded(
                  child: chatProvider.messages.isEmpty
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(24),
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
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Row(
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "AI Care Assistant is typing...",
                                style: TextStyle(color: AppColors.onSurfaceMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Quick Action Suggestion Prompts
                if (chatProvider.messages.length <= 1 && !chatProvider.isTyping) ...[
                  SizedBox(
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _quickPrompts.length,
                      itemBuilder: (context, index) {
                        final prompt = _quickPrompts[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ActionChip(
                            label: Text(
                              prompt,
                              style: const TextStyle(color: AppColors.onSurface, fontSize: 12),
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
                  const SizedBox(height: 12),
                ],

                // Message Box Input
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: const TextStyle(color: AppColors.onSurface, fontSize: 14),
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: 'Ask about yellow leaves, companion planting...',
                            hintStyle: const TextStyle(color: AppColors.onSurfaceFaint, fontSize: 13),
                            filled: true,
                            fillColor: AppColors.surface,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: AppColors.border, width: 1.0),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: AppColors.border, width: 1.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded, color: Colors.white),
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

  Widget _buildChatBubble(ChatMessage message) {
    final isUser = message.isUser;
    
    return Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser) ...[
          Container(
            margin: const EdgeInsets.only(right: 10, top: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.eco_rounded, color: AppColors.primary, size: 16),
          ),
        ],
        Flexible(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: isUser 
                  ? AppColors.primary.withValues(alpha: 0.15) 
                  : AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 0),
                bottomRight: Radius.circular(isUser ? 0 : 20),
              ),
              border: Border.all(
                color: isUser 
                    ? AppColors.primary.withValues(alpha: 0.4) 
                    : AppColors.border,
                width: 1,
              ),
            ),
            child: _buildMarkdownText(
              message.text,
              const TextStyle(
                color: AppColors.onSurface,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMarkdownText(String text, TextStyle baseStyle) {
    final List<Widget> children = [];
    final List<String> lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      if (line.isEmpty) {
        children.add(const SizedBox(height: 8));
        continue;
      }

      if (line.startsWith('#')) {
        final cleanHeader = line.replaceAll(RegExp(r'^#+\s*'), '');
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
            child: Text(
              cleanHeader,
              style: baseStyle.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: baseStyle.fontSize! + 2.0,
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
            padding: const EdgeInsets.only(left: 8.0, bottom: 6.0),
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
          padding: const EdgeInsets.only(bottom: 6.0),
          child: _buildLineWithRichFormatting(context, line, baseStyle),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _buildLineWithRichFormatting(BuildContext context, String text, TextStyle baseStyle) {
    final List<InlineSpan> spans = [];
    final RegExp regex = RegExp(r'(https?://[^\s]+)|(\*\*(.*?)\*\*)');
    
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
        String trailingPunctuation = "";
        while (cleanUrl.isNotEmpty && (cleanUrl.endsWith('.') || cleanUrl.endsWith(')') || cleanUrl.endsWith(','))) {
          trailingPunctuation = cleanUrl.substring(cleanUrl.length - 1) + trailingPunctuation;
          cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
        }

        spans.add(TextSpan(
          text: cleanUrl,
          style: baseStyle.copyWith(
            color: AppColors.accentLight,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.bold,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              final Uri url = Uri.parse(cleanUrl);
              try {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } catch (e) {
                debugPrint("Error launching url: $e");
              }
            },
        ));

        if (trailingPunctuation.isNotEmpty) {
          spans.add(TextSpan(
            text: trailingPunctuation,
            style: baseStyle,
          ));
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
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: baseStyle,
      ));
    }
    
    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
