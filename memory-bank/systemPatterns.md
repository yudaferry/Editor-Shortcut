# System Patterns

## Application Structure

The application follows a standard Flutter project structure, separating concerns into different
directories.

```mermaid
graph TD
    A[main.dart] --> B(Screens)
    B --> C{State Management}
    C --> D(Services)
    D --> E[Models]
    D --> F[Database]

    subgraph "UI"
        B
    end

    subgraph "Logic"
        C
        D
    end

    subgraph "Data"
        E
        F
    end
```

### Key Components:

- **`main.dart`**: The application entry point with window configuration for borderless mode.
- **`screens/`**: Contains the UI for different parts of the application (e.g., `home_screen.dart`,
  `add_project_screen.dart`).
- **`models/`**: Defines the data structures of the application, such as `Project`, `Editor`, and
  `ProjectGroup`.
- **`services/`**: Handles business logic and communication with external resources like the
  database (`database_service.dart`) and the system (`launcher_service.dart`, `path_service.dart`).
- **`utils/`**: Contains utility classes, like `logger.dart`.
- **Database**: A local SQLite database is used to persist project and editor configurations.
  `database_service.dart` abstracts the database operations.

### Window Management Pattern:

The application uses a clean window configuration:

- Visible OS title bar (default behavior, no titleBarStyle override)
- Hidden window buttons (`windowButtonVisibility: false`) to remove close and maximize buttons
- Custom AppBar provides application controls (fullscreen toggle, navigation)
- Window title bar remains functional for dragging and system menu access
