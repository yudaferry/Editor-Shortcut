import 'package:flutter/material.dart';
import '../models/editor.dart';
import '../services/database_service.dart';
import '../services/launcher_service.dart';

class EditorManagementScreen extends StatefulWidget {
  const EditorManagementScreen({super.key});

  @override
  State<EditorManagementScreen> createState() => _EditorManagementScreenState();
}

class _EditorManagementScreenState extends State<EditorManagementScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final LauncherService _launcherService = LauncherService();
  
  List<Editor> _editors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEditors();
  }

  Future<void> _loadEditors() async {
    setState(() => _isLoading = true);
    
    try {
      final editors = await _databaseService.getEditors();
      setState(() {
        _editors = editors;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading editors: $e')),
        );
      }
    }
  }

  Future<void> _addEditor() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const AddEditEditorScreen(),
      ),
    );
    
    if (result == true) {
      _loadEditors();
    }
  }

  Future<void> _editEditor(Editor editor) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddEditEditorScreen(editor: editor),
      ),
    );
    
    if (result == true) {
      _loadEditors();
    }
  }

  Future<void> _deleteEditor(Editor editor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Editor'),
        content: Text('Are you sure you want to delete "${editor.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _databaseService.deleteEditor(editor.id!);
      _loadEditors();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${editor.name} deleted')),
        );
      }
    }
  }

  Future<void> _setDefaultEditor(Editor editor) async {
    await _databaseService.setDefaultEditor(editor.id!);
    _loadEditors();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${editor.name} set as default')),
      );
    }
  }

  Future<void> _testEditor(Editor editor) async {
    final isAvailable = await _launcherService.testEditorCommand(editor.command);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAvailable 
                ? '${editor.name} is available ✓' 
                : '${editor.name} command not found ✗'
          ),
          backgroundColor: isAvailable ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _addSuggestedEditors() async {
    final suggested = _launcherService.getSuggestedEditors();
    final existing = _editors.map((e) => e.command).toSet();
    
    // Filter out editors that already exist
    final newEditors = suggested.where((e) => !existing.contains(e.command)).toList();
    
    if (newEditors.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All suggested editors are already added')),
        );
      }
      return;
    }

    final selectedEditors = await showDialog<List<Editor>>(
      context: context,
      builder: (context) => SuggestedEditorsDialog(editors: newEditors),
    );
    
    if (selectedEditors != null && selectedEditors.isNotEmpty) {
      for (final editor in selectedEditors) {
        await _databaseService.insertEditor(editor);
      }
      _loadEditors();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${selectedEditors.length} editors')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor Management'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'add_suggested') {
                _addSuggestedEditors();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add_suggested',
                child: Text('Add Suggested Editors'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _editors.isEmpty
              ? const Center(
                  child: Text(
                    'No editors configured.\nTap + to add your first editor.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _editors.length,
                  itemBuilder: (context, index) {
                    final editor = _editors[index];
                    return EditorCard(
                      editor: editor,
                      onEdit: () => _editEditor(editor),
                      onDelete: () => _deleteEditor(editor),
                      onSetDefault: () => _setDefaultEditor(editor),
                      onTest: () => _testEditor(editor),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEditor,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class EditorCard extends StatelessWidget {
  final Editor editor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;
  final VoidCallback onTest;

  const EditorCard({
    super.key,
    required this.editor,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
    required this.onTest,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.code,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    editor.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (editor.isDefault)
                  const Icon(Icons.star, color: Colors.amber),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                      case 'set_default':
                        onSetDefault();
                        break;
                      case 'test':
                        onTest();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'test',
                      child: Text('Test Command'),
                    ),
                    if (!editor.isDefault)
                      const PopupMenuItem(
                        value: 'set_default',
                        child: Text('Set as Default'),
                      ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Command: ${editor.command}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            if (editor.arguments != null && editor.arguments!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Arguments: ${editor.arguments}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
            if (editor.description != null && editor.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                editor.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AddEditEditorScreen extends StatefulWidget {
  final Editor? editor;

  const AddEditEditorScreen({super.key, this.editor});

  @override
  State<AddEditEditorScreen> createState() => _AddEditEditorScreenState();
}

class _AddEditEditorScreenState extends State<AddEditEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();
  final LauncherService _launcherService = LauncherService();
  
  late final TextEditingController _nameController;
  late final TextEditingController _commandController;
  late final TextEditingController _argumentsController;
  late final TextEditingController _descriptionController;
  
  bool _isLoading = false;
  bool _commandValid = false;

  @override
  void initState() {
    super.initState();
    
    _nameController = TextEditingController(text: widget.editor?.name ?? '');
    _commandController = TextEditingController(text: widget.editor?.command ?? '');
    _argumentsController = TextEditingController(text: widget.editor?.arguments ?? '');
    _descriptionController = TextEditingController(text: widget.editor?.description ?? '');
    
    if (_commandController.text.isNotEmpty) {
      _testCommand(_commandController.text);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commandController.dispose();
    _argumentsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _testCommand(String command) async {
    if (command.isEmpty) {
      setState(() => _commandValid = false);
      return;
    }

    final isValid = await _launcherService.testEditorCommand(command);
    setState(() => _commandValid = isValid);
  }

  Future<void> _saveEditor() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final now = DateTime.now();
      
      final editor = Editor(
        id: widget.editor?.id,
        name: _nameController.text.trim(),
        command: _commandController.text.trim(),
        arguments: _argumentsController.text.trim().isEmpty 
            ? null 
            : _argumentsController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        isDefault: widget.editor?.isDefault ?? false,
        createdAt: widget.editor?.createdAt ?? now,
        updatedAt: now,
      );
      
      if (widget.editor == null) {
        await _databaseService.insertEditor(editor);
      } else {
        await _databaseService.updateEditor(editor);
      }
      
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving editor: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editor != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Editor' : 'Add Editor'),
        actions: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            TextButton(
              onPressed: _saveEditor,
              child: Text(isEditing ? 'Update' : 'Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Editor Name *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Editor name is required';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _commandController,
              decoration: InputDecoration(
                labelText: 'Command *',
                hintText: 'e.g., code, cursor, vim',
                border: const OutlineInputBorder(),
                helperText: _commandValid 
                    ? 'Command available ✓' 
                    : _commandController.text.isNotEmpty 
                        ? 'Command not found' 
                        : 'Enter the command to launch this editor',
                helperStyle: TextStyle(
                  color: _commandValid ? Colors.green : Colors.red,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Command is required';
                }
                return null;
              },
              onChanged: _testCommand,
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _argumentsController,
              decoration: const InputDecoration(
                labelText: 'Arguments (optional)',
                hintText: 'e.g., --new-window',
                border: OutlineInputBorder(),
                helperText: 'Additional command line arguments',
              ),
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class SuggestedEditorsDialog extends StatefulWidget {
  final List<Editor> editors;

  const SuggestedEditorsDialog({super.key, required this.editors});

  @override
  State<SuggestedEditorsDialog> createState() => _SuggestedEditorsDialogState();
}

class _SuggestedEditorsDialogState extends State<SuggestedEditorsDialog> {
  final Set<Editor> _selectedEditors = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Suggested Editors'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.editors.length,
          itemBuilder: (context, index) {
            final editor = widget.editors[index];
            final isSelected = _selectedEditors.contains(editor);
            
            return CheckboxListTile(
              title: Text(editor.name),
              subtitle: Text(editor.command),
              value: isSelected,
              onChanged: (selected) {
                setState(() {
                  if (selected == true) {
                    _selectedEditors.add(editor);
                  } else {
                    _selectedEditors.remove(editor);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedEditors.isNotEmpty
              ? () => Navigator.of(context).pop(_selectedEditors.toList())
              : null,
          child: Text('Add ${_selectedEditors.length} Editors'),
        ),
      ],
    );
  }
}