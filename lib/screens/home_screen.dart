import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:window_manager/window_manager.dart';
import '../models/project.dart';
import '../models/editor.dart';
import '../services/database_service.dart';
import '../services/launcher_service.dart';
import '../services/path_service.dart';
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
  final PathService _pathService = PathService();
  
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
      AppLogger.info('📋 Loading projects, editors, and groups...');
      final projects = await _databaseService.getProjects();
      final editors = await _databaseService.getEditors();
      final groups = await _databaseService.getDistinctGroups();
      
      setState(() {
        _projects = projects;
        _editors = editors;
        _groups = ['All', ...groups];
        _isLoading = false;
      });
      
      AppLogger.info('✅ Loaded ${projects.length} projects, ${editors.length} editors, and ${groups.length} groups');
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
      filtered = filtered.where((p) => 
        p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        p.path.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    return filtered;
  }



  Future<void> _launchWithEditor(Project project, String editorName) async {
    AppLogger.info('🚀 Launching ${project.name} with $editorName');
    
    try {
      final editor = _editors.firstWhere(
        (e) => e.name.toLowerCase() == editorName.toLowerCase(),
        orElse: () => throw Exception('Editor $editorName not found'),
      );
      final success = await _launcherService.launchProjectAsync(project, editor);
      
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to launch ${project.name} with $editorName')),
        );
      }
    } catch (e) {
      AppLogger.error('❌ Error launching project', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Editor $editorName not found')),
        );
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
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Are you sure you want to remove "${project.name}" from the list?'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${project.name} removed')),
        );
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
    AppLogger.info('🚀 Launching ${project.name} with default editor');
    
    try {
      final defaultEditor = await _databaseService.getDefaultEditor();
      if (defaultEditor != null) {
        final success = await _launcherService.launchProjectAsync(project, defaultEditor);
        
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to launch ${project.name} with ${defaultEditor.name}')),
          );
        }
      } else {
        // If no default editor, try to launch with the first available editor
        if (_editors.isNotEmpty) {
          final success = await _launcherService.launchProjectAsync(project, _editors.first);
          
          if (!success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to launch ${project.name} with ${_editors.first.name}')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No editors available. Please add editors first.')),
            );
          }
        }
      }
    } catch (e) {
      AppLogger.error('❌ Error launching project', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching project: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Manager'),
        actions: [
          IconButton(
            onPressed: _toggleFullScreen,
            icon: const Icon(Icons.fullscreen),
            tooltip: 'Toggle Full Screen (F11)',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search projects...',
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
                  items: _groups.map((group) => DropdownMenuItem(
                    value: group,
                    child: Text(group),
                  )).toList(),
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProjects.isEmpty
                    ? const Center(
                        child: Text(
                          'No projects found.\nTap + to add your first project.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          // Responsive grid: more columns on wider screens
                          int crossAxisCount;
                          if (constraints.maxWidth > 1400) {
                            crossAxisCount = 5; // Very wide screens
                          } else if (constraints.maxWidth > 1100) {
                            crossAxisCount = 4; // Large screens
                          } else if (constraints.maxWidth > 800) {
                            crossAxisCount = 3; // Medium screens
                          } else {
                            crossAxisCount = 2; // Small screens
                          }
                          
                          return GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                              childAspectRatio: 2.5, // Ultra compact - much wider than tall
                            ),
                            itemCount: _filteredProjects.length,
                            itemBuilder: (context, index) {
                              final project = _filteredProjects[index];
                              return ProjectCard(
                                project: project,
                                pathService: _pathService,
                                editors: _editors,
                                onLaunchVSCode: () => _launchWithEditor(project, 'VS Code'),
                                onLaunchCursor: () => _launchWithEditor(project, 'Cursor'),
                                onLaunchWindsurf: () => _launchWithEditor(project, 'Windsurf'),
                                onLaunchWithDefault: () => _launchWithDefaultEditor(project),
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
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Manage Editor Button
            Expanded(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const EditorManagementScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.code, size: 18),
                label: const Text('Manage Editor'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Add Project Button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (context) => const AddProjectScreen(),
                    ),
                  );
                  
                  if (result == true) {
                    _loadData();
                  }
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Project'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Close Button
            Expanded(
              child: TextButton.icon(
                onPressed: () async {
                  await windowManager.close();
                },
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Close'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProjectCard extends StatelessWidget {
  final Project project;
  final PathService pathService;
  final List<Editor> editors;
  final VoidCallback onLaunchVSCode;
  final VoidCallback onLaunchCursor;
  final VoidCallback onLaunchWindsurf;
  final VoidCallback onLaunchWithDefault;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProjectCard({
    super.key,
    required this.project,
    required this.pathService,
    required this.editors,
    required this.onLaunchVSCode,
    required this.onLaunchCursor,
    required this.onLaunchWindsurf,
    required this.onLaunchWithDefault,
    required this.onEdit,
    required this.onDelete,
  });

  Widget _getEditorIcon(String editorName, {double size = 24.0}) {
    // VS Code icon - use actual SVG
    if (editorName.toLowerCase().contains('vs code') || 
        editorName.toLowerCase().contains('code')) {
      return SvgPicture.asset(
        'assets/icons/vscode.svg',
        width: size,
        height: size,
        // ignore: deprecated_member_use
        color: null, // Don't apply color to preserve original colors
      );
    }
    
    // Cursor AI Editor icon - use actual SVG
    if (editorName.toLowerCase().contains('cursor')) {
      return SvgPicture.asset(
        'assets/icons/cursor.svg',
        width: size,
        height: size,
        // ignore: deprecated_member_use
        color: null, // Don't apply color to preserve original colors
      );
    }
    
    // Windsurf IDE icon - use actual SVG
    if (editorName.toLowerCase().contains('windsurf')) {
      return SvgPicture.asset(
        'assets/icons/windsurf.svg',
        width: size,
        height: size,
        // ignore: deprecated_member_use
        color: null, // Don't apply color to preserve original colors
      );
    }
    
    // Default icon for unknown editors
    return Icon(Icons.code, size: size, color: Colors.grey);
  }

  Widget _getSvgIcon(String assetPath, {double size = 24.0, Color? color}) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      // ignore: deprecated_member_use
      color: color, // Apply the color for edit/delete icons
    );
  }

  bool _hasEditor(String editorName) {
    return editors.any((editor) => 
      editor.name.toLowerCase() == editorName.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(1),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row: Group title (replaces folder icon) + Project name + manipulate buttons
            Row(
              children: [
                // Group title replaces folder icon
                if (project.group != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      project.group!.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: GestureDetector(
                    onTap: onLaunchWithDefault,
                    child: Text(
                      project.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // Manipulate group (right side)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: onEdit,
                      icon: _getSvgIcon('assets/icons/edit.svg', 
                          color: Theme.of(context).colorScheme.primary),
                      tooltip: 'Edit Project',
                      splashRadius: 10,
                      iconSize: 14,
                      padding: const EdgeInsets.all(2),
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: _getSvgIcon('assets/icons/delete.svg', 
                          color: Theme.of(context).colorScheme.error),
                      tooltip: 'Delete Project',
                      splashRadius: 10,
                      iconSize: 14,
                      padding: const EdgeInsets.all(2),
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Editor group (left side, under project name)
            Row(
              children: [
                // VS Code
                IconButton(
                  onPressed: _hasEditor('VS Code') ? onLaunchVSCode : null,
                  icon: _getEditorIcon('VS Code', size: 16),
                  tooltip: _hasEditor('VS Code') ? 'Open with VS Code' : 'VS Code not available',
                  splashRadius: 10,
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
                // Cursor
                IconButton(
                  onPressed: _hasEditor('Cursor') ? onLaunchCursor : null,
                  icon: _getEditorIcon('Cursor', size: 16),
                  tooltip: _hasEditor('Cursor') ? 'Open with Cursor' : 'Cursor not available',
                  splashRadius: 10,
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
                // Windsurf
                IconButton(
                  onPressed: _hasEditor('Windsurf') ? onLaunchWindsurf : null,
                  icon: _getEditorIcon('Windsurf', size: 16),
                  tooltip: _hasEditor('Windsurf') ? 'Open with Windsurf' : 'Windsurf not available',
                  splashRadius: 10,
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}