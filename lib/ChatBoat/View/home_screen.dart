import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:animated_text_kit/animated_text_kit.dart'; // Import this
import '../Bloc/Cubit/cubit_state.dart';
import '../Bloc/Cubit/search_cubit.dart';

class ChatBoatHomeScreen extends StatefulWidget {
  const ChatBoatHomeScreen({super.key});

  @override
  State<ChatBoatHomeScreen> createState() => _ChatBoatHomeScreenState();
}

class _ChatBoatHomeScreenState extends State<ChatBoatHomeScreen> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Helper to auto-scroll to bottom when new messages arrive
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title:  Text("Siya AI", style:  GoogleFonts.lato(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          // IconButton(
          //   onPressed: () => context.read<SearchCubit>().clearChat(),
          //   icon: const Icon(Icons.delete_sweep),
          // )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<SearchCubit, SearchState>(
              listener: (context, state) {
                if (state is SearchLoaded || state is SearchLoading) {
                  _scrollToBottom();
                }
                if (state is SearchError) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage), backgroundColor: Colors.red));
                }
              },
              builder: (context, state) {
                // We use the static list from Cubit to show all messages
                var history = SearchCubit.chatList;

                if (history.isEmpty && state is! SearchLoading) {
                  return const Center(child: Text("Start a conversation!"));
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  // The +1 is for the loading indicator
                  itemCount: history.length + (state is SearchLoading ? 1 : 0),
                  itemBuilder: (context, index) {

                    // CRITICAL FIX: Check for loading index FIRST
                    if (index == history.length) {
                      return const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CupertinoActivityIndicator()
                        ),
                      );
                    }

                    // Now it is safe to access the list because index < history.length
                    final chat = history[index];
                    final bool isUser = chat['role'] == 'user';

                    // Check if 'parts' exists and has elements to avoid another RangeError
                    final String message = (chat['parts'] != null && chat['parts'].isNotEmpty)
                        ? chat['parts'][0]['text']
                        : "";

                    final bool shouldAnimate = !isUser &&
                        index == history.length - 1 &&
                        state is SearchLoaded;

                    return _buildChatBubble(
                      message,
                      isUser: isUser,
                      animate: shouldAnimate,
                      index: index,
                    );
                  },
                );
              },
            ),
          ),
          _buildInputArea(context),
        ],
      ),
    );
  }

  // ... inside your _ChatBoatHomeScreenState class

  Widget _buildChatBubble(String text, {required bool isUser, bool animate = false, required int index}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      key: ValueKey("chat_bubble_$index"),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
            decoration: BoxDecoration(
              color: isUser ? Colors.blueAccent : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 0),
                bottomRight: Radius.circular(isUser ? 0 : 16),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isUser)
                // User messages: Plain text
                  Text(
                      text,
                      style:  GoogleFonts.lato(color: Colors.white, fontSize: 15)
                  )
                else
                // Model messages: Markdown + Animation + Copy
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (animate)
                      // While loading/typing: use AnimatedTextKit
                        AnimatedTextKit(
                          totalRepeatCount: 1,
                          displayFullTextOnTap: true,
                          animatedTexts: [
                            TypewriterAnimatedText(
                              text,
                              textStyle:  GoogleFonts.lato(fontSize: 15, color: Colors.black87),
                              speed: const Duration(milliseconds: 20),
                            ),
                          ],
                        )
                      else
                      // Once finished: use GptMarkdown for formatting
                        GptMarkdown(
                          text,
                          style:  GoogleFonts.lato(fontSize: 15, color: Colors.black87),
                        ),

                      const SizedBox(height: 8),
                      const Divider(height: 1, color: Colors.black12),

                      // Copy Button aligned to the right
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Copied"), duration: Duration(seconds: 1)),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Text("Copy", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                // SizedBox(width: 4),
                                Icon(Icons.copy, size: 14, color: Colors.grey),
                              ],
                            ),
                          ),
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
  }


  Widget _buildInputArea(BuildContext context) {
    // Keep your existing _buildInputArea code here...
    // Make sure to call context.read<SearchCubit>().getAIResponse(query: searchController.text);
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Ask anything...",
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blueAccent),
              onPressed: () {
                if (searchController.text.trim().isNotEmpty) {
                  context.read<SearchCubit>().getAIResponse(query: searchController.text.trim());
                  searchController.clear();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
