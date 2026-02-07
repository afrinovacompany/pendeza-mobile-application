import 'dart:io';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/features/5_admin_panel/presentation/bloc/admin_bloc.dart';
import 'package:pendeza/features/5_admin_panel/presentation/bloc/admin_event.dart';
import 'package:pendeza/features/5_admin_panel/presentation/bloc/admin_state.dart';

import 'package:pendeza/shared/widgets/primary_gradient_button.dart';
import 'package:pendeza/shared/widgets/text_form_field.dart';

import '../../../3_owner_inspiration/data/model/inspiration_article_model.dart';
import '../../../3_owner_inspiration/data/model/lookbook_image_model.dart';

class AdminManageInspirationScreen extends StatelessWidget {
  const AdminManageInspirationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Inspiration'),
          backgroundColor:
          isDark ? AppColors.darkSurfaceVariant : theme.colorScheme.surface,
          elevation: 1,
          bottom: TabBar(
            indicatorColor: theme.colorScheme.primary,
            tabs: const [
              Tab(text: 'Articles'),
              Tab(text: 'Lookbook'),
            ],
          ),
        ),
        backgroundColor: isDark
            ? AppColors.darkBackground
            : theme.scaffoldBackgroundColor.withAlpha(245),
        body: BlocBuilder<AdminBloc, AdminState>(
          builder: (context, state) {
            if (state is AdminLoading || state is AdminInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is AdminError) {
              return Center(child: Text(state.message));
            }
            if (state is AdminLoaded) {
              return TabBarView(
                children: [
                  _ArticlesTab(articles: state.articles, adminBloc: context.read<AdminBloc>()),
                  _LookbookTab(lookbookItems: state.lookbook, adminBloc: context.read<AdminBloc>()),
                ],
              );
            }
            return const Center(child: Text('Unknown state.'));
          },
        ),
      ),
    );
  }
}

// --- ARTICLES TAB ---
class _ArticlesTab extends StatelessWidget {
  final List<InspirationArticleModel> articles;
  final AdminBloc adminBloc;

  const _ArticlesTab({required this.articles, required this.adminBloc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: articles.isEmpty
          ? const Center(child: Text('No articles posted yet.'))
          : ListView.builder(
        padding: const EdgeInsets.all(AppConstants.padM),
        itemCount: articles.length,
        itemBuilder: (context, index) {
          final article = articles[index];
          return _ArticleCard(article: article, adminBloc: adminBloc);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddArticleDialog(context, adminBloc),
        icon: const Icon(Icons.post_add),
        label: const Text("New Blog Post"),
      ),
    );
  }
}

// --- LOOKBOOK TAB ---
class _LookbookTab extends StatelessWidget {
  final List<LookbookImageModel> lookbookItems;
  final AdminBloc adminBloc;

  const _LookbookTab({required this.lookbookItems, required this.adminBloc});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: lookbookItems.isEmpty
          ? const Center(child: Text('No lookbook items posted yet.'))
          : GridView.builder(
        padding: const EdgeInsets.all(AppConstants.padM),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: AppConstants.padS,
          mainAxisSpacing: AppConstants.padS,
        ),
        itemCount: lookbookItems.length,
        itemBuilder: (context, index) {
          final item = lookbookItems[index];
          return _LookbookCard(item: item, adminBloc: adminBloc);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddLookbookDialog(context, adminBloc),
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}

// --- ARTICLE CARD ---
class _ArticleCard extends StatelessWidget {
  final InspirationArticleModel article;
  final AdminBloc adminBloc;

  const _ArticleCard({required this.article, required this.adminBloc});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.padM),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (article.imageUrl != null)
            CachedNetworkImage(
              imageUrl: article.imageUrl!,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ListTile(
            title: Text(article.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(article.summary, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: IconButton(
              icon: const Icon(CupertinoIcons.trash, color: Colors.red),
              onPressed: () {
                adminBloc.add(DeleteArticle(article.id, article.imageUrl));
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- LOOKBOOK CARD ---
class _LookbookCard extends StatelessWidget {
  final LookbookImageModel item;
  final AdminBloc adminBloc;

  const _LookbookCard({required this.item, required this.adminBloc});

  @override
  Widget build(BuildContext context) {
    return GridTile(
      footer: GridTileBar(
        backgroundColor: Colors.black45,
        title: Text(item.title, style: const TextStyle(fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(CupertinoIcons.trash, color: Colors.red, size: 18),
          onPressed: () {
            adminBloc.add(DeleteLookbookItem(item.id, item.imageUrl));
          },
        ),
      ),
      child: CachedNetworkImage(
        imageUrl: item.imageUrl,
        fit: BoxFit.cover,
      ),
    );
  }
}

// --- DIALOGS ---

void _showAddArticleDialog(BuildContext context, AdminBloc adminBloc) {
  // We push a full screen route for the rich text editor
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => BlocProvider.value(
        value: adminBloc,
        child: const _AddArticleScreen(),
      ),
    ),
  );
}

void _showAddLookbookDialog(BuildContext context, AdminBloc adminBloc) {
  showDialog(
    context: context,
    builder: (_) => BlocProvider.value(
      value: adminBloc,
      child: const _AddLookbookDialog(),
    ),
  );
}

// --- ADD ARTICLE SCREEN (Full screen with editor) ---
class _AddArticleScreen extends StatefulWidget {
  const _AddArticleScreen();

  @override
  State<_AddArticleScreen> createState() => _AddArticleScreenState();
}

class _AddArticleScreenState extends State<_AddArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  late quill.QuillController _quillController;
  final FocusNode _editorFocusNode = FocusNode(); // Fix for scrolling issue
  final ScrollController _editorScrollController = ScrollController();

  XFile? _coverImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _quillController = quill.QuillController.basic();
  }

  @override
  void dispose() {
    _quillController.dispose();
    _titleController.dispose();
    _summaryController.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _coverImage = image;
      });
    }
  }

  /// Pick image and insert into the Quill editor content
  Future<void> _pickAndInsertContentImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) return;

    try {
      // Upload image to Firebase Storage
      final file = File(image.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance
          .ref('inspiration_images/article_content')
          .child(fileName);
      await ref.putFile(file);
      final imageUrl = await ref.getDownloadURL();

      // Insert image into Quill editor
      final index = _quillController.selection.baseOffset;
      final length = _quillController.selection.extentOffset - index;
      _quillController.replaceText(index, length, quill.BlockEmbed.image(imageUrl), null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to insert image: $e')),
        );
      }
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Convert Quill document to JSON
      final contentJson = jsonEncode(_quillController.document.toDelta().toJson());

      context.read<AdminBloc>().add(AddArticle(
        title: _titleController.text,
        summary: _summaryController.text,
        contentJson: contentJson,
        imagePath: _coverImage?.path,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is AdminLoaded) {
          Navigator.of(context).pop();
        }
        if (state is AdminError) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Write Article'),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('PUBLISH', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.padM),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cover Image Picker
                      GestureDetector(
                        onTap: _pickCoverImage,
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              image: _coverImage != null
                                  ? DecorationImage(image: FileImage(File(_coverImage!.path)), fit: BoxFit.cover)
                                  : null
                          ),
                          child: _coverImage == null
                              ? const Center(child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                              Text("Add Cover Image"),
                            ],
                          ))
                              : null,
                        ),
                      ),
                      const SizedBox(height: AppConstants.padL),

                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'Article Title',
                          border: InputBorder.none,
                        ),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                        validator: (val) => (val?.isEmpty ?? true) ? 'Required' : null,
                      ),
                      const Divider(),

                      // Summary
                      TextFormField(
                        controller: _summaryController,
                        decoration: const InputDecoration(
                          hintText: 'Short summary (appears in list view)...',
                          border: InputBorder.none,
                        ),
                        maxLines: 2,
                        validator: (val) => (val?.isEmpty ?? true) ? 'Required' : null,
                      ),
                      const Divider(thickness: 1),

                      const SizedBox(height: AppConstants.padM),
                      const Text("Article Content", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: AppConstants.padS),

                      // Editor Content - FIXED SCROLLING ISSUE
                      Container(
                        constraints: const BoxConstraints(minHeight: 300),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: quill.QuillEditor(
                          controller: _quillController,
                          scrollController: _editorScrollController,
                          focusNode: _editorFocusNode,
                          config: const quill.QuillEditorConfig(
                            placeholder: 'Start writing your amazing story...',
                            // Important: set this to false so the parent SingleChildScrollView handles scrolling
                            scrollable: false,
                            autoFocus: false,
                            expands: false,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Editor Toolbar (Sticky at bottom)
            SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: const Border(top: BorderSide(color: Colors.grey, width: 0.5)),
                ),
                child: quill.QuillSimpleToolbar(
                  controller: _quillController,
                  config: quill.QuillSimpleToolbarConfig(
                      showFontFamily: false,
                      showSearchButton: false,
                      showIndent: false,
                      // Override image button to use our custom picker
                      customButtons: [
                        quill.QuillToolbarCustomButtonOptions(
                          icon: const Icon(Icons.image),
                          onPressed: _pickAndInsertContentImage,
                        )
                      ]
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- ADD LOOKBOOK DIALOG (Unchanged) ---
class _AddLookbookDialog extends StatefulWidget {
  const _AddLookbookDialog();

  @override
  State<_AddLookbookDialog> createState() => _AddLookbookDialogState();
}

class _AddLookbookDialogState extends State<_AddLookbookDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _tagsController = TextEditingController();
  XFile? _pickedImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _pickedImage != null) {
      setState(() { _isLoading = true; });
      context.read<AdminBloc>().add(AddLookbookItem(
        title: _titleController.text,
        tags: _tagsController.text.split(',').map((e) => e.trim()).toList(),
        imagePath: _pickedImage!.path,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state is AdminLoaded) {
          Navigator.of(context).pop();
        }
        if (state is AdminError) {
          setState(() { _isLoading = false; });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: AlertDialog(
        title: const Text('Add Lookbook Item'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextFormField(
                  controller: _titleController,
                  labelText: 'Title',
                  validator: (val) => (val?.isEmpty ?? true) ? 'Required' : null,
                ),
                const SizedBox(height: AppConstants.padM),
                CustomTextFormField(
                  controller: _tagsController,
                  labelText: 'Tags (comma-separated)',
                ),
                const SizedBox(height: AppConstants.padM),
                _pickedImage == null
                    ? OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Select Image'),
                )
                    : Image.file(File(_pickedImage!.path), height: 100),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          PrimaryGradientButton(
            onPressed: _submit,
            text: 'Post',
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}