import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:window_manager/window_manager.dart';
import '../models/project.dart';
import '../models/editor.dart';
import '../services/database_service.dart';
import '../services/launcher_service.dart';
import '../utils/logger.dart';
import 'add_project_screen.dart';
import 'editor_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final LauncherService _launcherService = LauncherService();

  List<Project> _projects = [];
  List<Editor> _editors = [];
  List<String> _groups = ['All'];
  String _selectedGroup = 'All';
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final projects = await _databaseService.getProjects();
      final editors = await _databaseService.getEditors();
      final groups = await _databaseService.getDistinctGroups();

      setState(() {
        _projects = projects;
        _editors = editors;
        _groups = ['All', ...groups];
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to load projects', e, stackTrace);
      setState(() => _isLoading = false);

      // Don't show error in UI, just log it
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('Error loading projects: $e')),
      //   );
      // }
    }
  }

  List<Project> get _filteredProjects {
    var filtered = _projects;

    // Filter by group
    if (_selectedGroup != 'All') {
      filtered = filtered.where((p) => p.group == _selectedGroup).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered
              .where(
                (p) =>
                    p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    p.path.toLowerCase().contains(_searchQuery.toLowerCase()),
              )
              .toList();
    }

    return filtered;
  }

  Future<void> _launchWithEditor(Project project, String editorName) async {
    try {
      final editor = _editors.firstWhere(
        (e) => e.name.toLowerCase() == editorName.toLowerCase(),
        orElse: () => throw Exception('Editor $editorName not found'),
      );
      final success = await _launcherService.launchProjectAsync(
        project,
        editor,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to launch ${project.name} with $editorName'),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('❌ Error launching project', e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Editor $editorName not found')));
      }
    }
  }

  Future<void> _editProject(Project project) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddProjectScreen(project: project),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _deleteProject(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Project'),
            content: Text(
              'Are you sure you want to remove "${project.name}" from the list?',
            ),
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
      await _databaseService.deleteProject(project.id!);
      _loadData();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${project.name} removed')));
      }
    }
  }

  Future<void> _toggleFullScreen() async {
    bool isFullScreen = await windowManager.isFullScreen();
    if (isFullScreen) {
      await windowManager.setFullScreen(false);
    } else {
      await windowManager.setFullScreen(true);
    }
  }

  Future<void> _launchWithDefaultEditor(Project project) async {
    try {
      final defaultEditor = await _databaseService.getDefaultEditor();
      if (defaultEditor != null) {
        final success = await _launcherService.launchProjectAsync(
          project,
          defaultEditor,
        );

        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to launch ${project.name} with ${defaultEditor.name}',
              ),
            ),
          );
        }
      } else {
        // If no default editor, try to launch with the first available editor
        if (_editors.isNotEmpty) {
          final success = await _launcherService.launchProjectAsync(
            project,
            _editors.first,
          );

          if (!success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to launch ${project.name} with ${_editors.first.name}',
                ),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'No editors available. Please add editors first.',
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      AppLogger.error('❌ Error launching project', e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error launching project: $e')));
      }
    }
  }

  Future<void> _navigateToAddProject() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const AddProjectScreen()),
    );

    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor Shortcut'),
        elevation: 0,
        shape: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EditorManagementScreen(),
                ),
              );
            },
            icon: const Icon(Icons.edit_note_outlined),
            label: const Text('Editors'),
          ),
          IconButton(
            onPressed: _toggleFullScreen,
            icon: const Icon(Icons.fullscreen),
            tooltip: 'Toggle Full Screen',
          ),
          IconButton(
            onPressed: () => windowManager.close(),
            icon: const Icon(Icons.close),
            tooltip: 'Close Window',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search and filter bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search projects by name or path...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedGroup,
                  items:
                      _groups
                          .map(
                            (group) => DropdownMenuItem(
                              value: group,
                              child: Text(group),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedGroup = value);
                    }
                  },
                ),
              ],
            ),
          ),

          // Projects list
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredProjects.isEmpty
                    ? Center(
                      child: Text(
                        'No projects found.\nTap the + button to add one.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    )
                    : LayoutBuilder(
                      builder: (context, constraints) {
                        // Responsive grid: more columns on wider screens
                        int crossAxisCount;
                        if (constraints.maxWidth > 1600) {
                          crossAxisCount = 5;
                        } else if (constraints.maxWidth > 1200) {
                          crossAxisCount = 4;
                        } else if (constraints.maxWidth > 800) {
                          crossAxisCount = 3;
                        } else {
                          crossAxisCount = 2;
                        }

                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 6.0,
                              ),
                          itemCount: _filteredProjects.length,
                          itemBuilder: (context, index) {
                            final project = _filteredProjects[index];
                            return ProjectGridItem(
                              project: project,
                              editors: _editors,
                              onLaunchWithDefault:
                                  () => _launchWithDefaultEditor(project),
                              onLaunchVSCode:
                                  () => _launchWithEditor(project, 'VS Code'),
                              onLaunchCursor:
                                  () => _launchWithEditor(project, 'Cursor'),
                              onLaunchWindsurf:
                                  () => _launchWithEditor(project, 'Windsurf'),
                              onEdit: () => _editProject(project),
                              onDelete: () => _deleteProject(project),
                            );
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddProject,
        label: const Text('Add Project'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class ProjectGridItem extends StatelessWidget {
  final Project project;
  final List<Editor> editors;
  final VoidCallback onLaunchVSCode;
  final VoidCallback onLaunchCursor;
  final VoidCallback onLaunchWindsurf;
  final VoidCallback onLaunchWithDefault;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProjectGridItem({
    super.key,
    required this.project,
    required this.editors,
    required this.onLaunchVSCode,
    required this.onLaunchCursor,
    required this.onLaunchWindsurf,
    required this.onLaunchWithDefault,
    required this.onEdit,
    required this.onDelete,
  });

  Widget _getEditorIcon(
    String editorName,
    BuildContext context, {
    double size = 20.0,
  }) {
    String lowerCaseEditorName = editorName.toLowerCase();

    // Get appropriate color based on theme
    Color iconColor =
        Theme.of(context).brightness == Brightness.dark
            ? Colors
                .white70 // Light color for dark mode
            : Colors.black87; // Dark color for light mode

    if (lowerCaseEditorName.contains('vs code') ||
        lowerCaseEditorName.contains('code')) {
      return SvgPicture.asset(
        'assets/icons/vscode.svg',
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      );
    }
    if (lowerCaseEditorName.contains('cursor')) {
      return SvgPicture.asset(
        'assets/icons/cursor.svg',
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      );
    }
    if (lowerCaseEditorName.contains('windsurf')) {
      return SvgPicture.asset(
        'assets/icons/windsurf.svg',
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      );
    }
    return Icon(Icons.code, size: size, color: Colors.grey);
  }

  bool _hasEditor(String editorName) {
    return editors.any(
      (editor) => editor.name.toLowerCase() == editorName.toLowerCase(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onLaunchWithDefault,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: Row(
            children: [
              // Left section: Group and Project Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (project.group != null && project.group!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .secondaryContainer
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            project.group!,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    Flexible(
                      child: Text(
                        project.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Right section: Action icons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_hasEditor('VS Code'))
                    IconButton(
                      onPressed: onLaunchVSCode,
                      icon: _getEditorIcon('VS Code', context),
                      tooltip: 'Launch in VS Code',
                      iconSize: 20,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                    ),
                  if (_hasEditor('Cursor'))
                    IconButton(
                      onPressed: onLaunchCursor,
                      icon: _getEditorIcon('Cursor', context),
                      tooltip: 'Launch in Cursor',
                      iconSize: 20,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                    ),
                  if (_hasEditor('Windsurf'))
                    IconButton(
                      onPressed: onLaunchWindsurf,
                      icon: _getEditorIcon('Windsurf', context),
                      tooltip: 'Launch in Windsurf',
                      iconSize: 20,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                    ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder:
                        (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit_outlined),
                              title: Text('Edit'),
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete_outline),
                              title: Text('Delete'),
                            ),
                          ),
                        ],
                    icon: const Icon(Icons.more_vert),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
