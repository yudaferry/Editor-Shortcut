import 'package:flutter/material.dart';
import '../models/project.dart';
import '../services/database_service.dart';
import '../services/path_service.dart';
import '../utils/logger.dart';

class AddProjectScreen extends StatefulWidget {
  final Project? project;

  const AddProjectScreen({super.key, this.project});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _databaseService = DatabaseService();
  final PathService _pathService = PathService();

  late final TextEditingController _nameController;
  late final TextEditingController _pathController;
  late final TextEditingController _groupController;

  List<String> _existingGroups = [];
  bool _isLoading = false;
  bool _pathExists = false;
  bool _hasProjectIndicators = false;
  String _selectedPlatform = 'wsl'; // 'windows' or 'wsl'

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _pathController = TextEditingController(text: widget.project?.path ?? '');
    _groupController = TextEditingController(text: widget.project?.group ?? '');

    _loadExistingGroups();
    if (_pathController.text.isNotEmpty) {
      _validatePath(_pathController.text);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pathController.dispose();
    _groupController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingGroups() async {
    final groups = await _databaseService.getDistinctGroups();
    setState(() {
      _existingGroups = groups;
    });
  }

  Future<void> _validatePath(String path) async {
    if (path.isEmpty) {
      setState(() {
        _pathExists = false;
        _hasProjectIndicators = false;
      });
      return;
    }

    final exists = await _pathService.pathExists(path);
    final hasIndicators =
        exists ? await _pathService.hasProjectIndicators(path) : false;

    setState(() {
      _pathExists = exists;
      _hasProjectIndicators = hasIndicators;
    });

    // Auto-generate project name if path is valid and name is empty
    if (exists && _nameController.text.isEmpty) {
      final projectName = _pathService.getProjectNameFromPath(path);
      _nameController.text = projectName;
    }
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();

      final project = Project(
        id: widget.project?.id,
        name: _nameController.text.trim(),
        path: _pathController.text.trim(),
        group:
            _groupController.text.trim().isEmpty
                ? null
                : _groupController.text.trim(),
        createdAt: widget.project?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.project == null) {
        await _databaseService.insertProject(project);
      } else {
        await _databaseService.updateProject(project);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      AppLogger.error('❌ Error saving project', e);
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving project: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.project != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Project' : 'Add Project'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: TextButton(
                onPressed: _saveProject,
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.headlineSmall,
                  overlayColor: Colors.transparent,
                  foregroundColor: Theme.of(context).primaryColor,
                ),
                child: Text(isEditing ? 'Update' : 'Save'),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Project Path with Platform Dropdown
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    flex: 4,
                    child: TextFormField(
                      controller: _pathController,
                      decoration: InputDecoration(
                        labelText: 'Project Path *',
                        hintText:
                            _selectedPlatform == 'windows'
                                ? 'e.g., C:\\Users\\username\\my-project'
                                : 'e.g., /mnt/c/Users/username/my-project or /home/user/my-project',
                        border: const OutlineInputBorder(),
                        helperText:
                            _pathExists
                                ? (_hasProjectIndicators
                                    ? 'Valid project directory ✓'
                                    : 'Directory exists ✓')
                                : _pathController.text.isNotEmpty
                                ? 'Path does not exist'
                                : null,
                        helperStyle: TextStyle(
                          color:
                              _pathExists
                                  ? (_hasProjectIndicators
                                      ? Colors.green
                                      : Colors.orange)
                                  : Colors.red,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Project path is required';
                        }
                        if (!_pathExists) {
                          return 'Path does not exist';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        _validatePath(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                        width: 1.0, // Match TextFormField border width
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedPlatform,
                      underline: const SizedBox(),
                      isDense: true,
                      items: const [
                        DropdownMenuItem(value: 'wsl', child: Text('WSL')),
                        DropdownMenuItem(
                          value: 'windows',
                          child: Text('Windows'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedPlatform = value;
                            _pathController.clear();
                            _pathExists = false;
                            _hasProjectIndicators = false;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Project Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Project Name *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Project name is required';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Group
            TextFormField(
              controller: _groupController,
              decoration: InputDecoration(
                labelText: 'Group (optional)',
                border: const OutlineInputBorder(),
                suffixIcon:
                    _existingGroups.isNotEmpty
                        ? PopupMenuButton<String>(
                          icon: const Icon(Icons.arrow_drop_down),
                          onSelected: (value) {
                            _groupController.text = value;
                          },
                          itemBuilder:
                              (context) =>
                                  _existingGroups
                                      .map(
                                        (group) => PopupMenuItem(
                                          value: group,
                                          child: Text(group),
                                        ),
                                      )
                                      .toList(),
                        )
                        : null,
              ),
            ),

            const SizedBox(height: 24),

            // Path Info Card
            if (_pathController.text.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Path Information',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Display Path:',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        _pathService.getDisplayPath(_pathController.text),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            _pathExists ? Icons.check_circle : Icons.error,
                            size: 16,
                            color: _pathExists ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _pathExists ? 'Path exists' : 'Path not found',
                            style: TextStyle(
                              color: _pathExists ? Colors.green : Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      if (_pathExists && _hasProjectIndicators) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.folder_special,
                              size: 16,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Contains project files',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class WSLPathSelectionDialog extends StatefulWidget {
  final String initialPath;
  final PathService pathService;

  const WSLPathSelectionDialog({
    super.key,
    required this.initialPath,
    required this.pathService,
  });

  @override
  State<WSLPathSelectionDialog> createState() => _WSLPathSelectionDialogState();
}

class _WSLPathSelectionDialogState extends State<WSLPathSelectionDialog> {
  late final TextEditingController _controller;
  bool _pathExists = false;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPath);
    if (widget.initialPath.isNotEmpty) {
      _validatePath(widget.initialPath);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _validatePath(String path) async {
    if (path.isEmpty) {
      setState(() {
        _pathExists = false;
        _isValidating = false;
      });
      return;
    }

    setState(() => _isValidating = true);

    try {
      final exists = await widget.pathService.pathExists(path);
      setState(() {
        _pathExists = exists;
        _isValidating = false;
      });
    } catch (e) {
      setState(() {
        _pathExists = false;
        _isValidating = false;
      });
    }
  }

  void _insertCommonPath(String path) {
    _controller.text = path;
    _validatePath(path);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('WSL Directory Path'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'WSL Path',
                border: const OutlineInputBorder(),
                helperText:
                    _isValidating
                        ? 'Validating...'
                        : (_pathExists ? 'Path exists ✓' : 'Path not found'),
                helperStyle: TextStyle(
                  color:
                      _isValidating
                          ? Colors.orange
                          : (_pathExists ? Colors.green : Colors.red),
                ),
                suffixIcon:
                    _isValidating
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                        : null,
              ),
              onChanged: (value) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_controller.text == value) {
                    _validatePath(value);
                  }
                });
              },
              maxLines: 1,
            ),
            const SizedBox(height: 16),
            const Text(
              'Common WSL Paths:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildPathChip('/mnt/c/Users/'),
                _buildPathChip('/home/'),
                _buildPathChip('/mnt/c/'),
                _buildPathChip('/tmp/'),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Examples:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildExampleText('/mnt/c/Users/username/project'),
                _buildExampleText('/home/username/project'),
                _buildExampleText('/mnt/c/dev/my-project'),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed:
              _controller.text.isNotEmpty && !_isValidating
                  ? () => Navigator.of(context).pop(_controller.text)
                  : null,
          child: const Text('Select'),
        ),
      ],
    );
  }

  Widget _buildPathChip(String path) {
    return ActionChip(
      label: Text(path),
      onPressed: () => _insertCommonPath(path),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildExampleText(String example) {
    return InkWell(
      onTap: () => _insertCommonPath(example),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          example,
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}
