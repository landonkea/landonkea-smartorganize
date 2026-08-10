# landonkea-smartorganize - Design & Workflow

## High-Level Overview

```mermaid
graph TB
    subgraph "landonkea-smartorganize"
        A[bin/smartorganize] --> B[lib/smartorganize/]
        B --> C[scanner.rb]
        B --> D[organizer.rb]
        B --> E[undo.rb]
        B --> F[stats.rb]
        B --> G[config.rb]
    end

    subgraph "Configuration"
        H[.smartorganize.yml] --> G
    end

    subgraph "Tests"
        I[spec/] --> B
    end
```

## Command Workflow

```mermaid
flowchart TD
    A[User runs command] --> B{Command?}
    B -->|scan| C[Scan directory]
    B -->|organize| D[Scan + Move]
    B -->|undo| E[Undo last]
    B -->|stats| F[Show stats]

    C --> G[Group by extension]
    G --> H[Print preview]

    D --> G
    G --> I[Move files]
    I --> J[Write log]

    E --> K[Read log]
    K --> L[Reverse moves]

    F --> M[Read log]
    M --> N[Calculate stats]
```

## File Organization Flow

```mermaid
sequenceDiagram
    participant U as User
    participant S as Scanner
    participant O as Organizer
    participant L as Log

    U->>S: smartorganize organize ~/Downloads
    S->>S: Scan all files
    S->>S: Group by extension
    S-->>O: File list
    O->>O: Create category folders
    loop Each file
        O->>O: Move to category
        O->>L: Log the move
    end
    O-->>U: Done
```

## File Relationships

| File | Purpose | Used By |
|------|---------|---------|
| `bin/smartorganize` | CLI entry point | User |
| `lib/smartorganize/scanner.rb` | Scan files | Organizer |
| `lib/smartorganize/organizer.rb` | Move files | CLI |
| `lib/smartorganize/undo.rb` | Undo moves | CLI |
| `lib/smartorganize/stats.rb` | Show stats | CLI |
| `lib/smartorganize/config.rb` | Load config | Scanner |
| `spec/` | Tests | RSpec |

## draw.io

[Open in draw.io](https://app.diagrams.net/#RSmartorganize%20architecture)
