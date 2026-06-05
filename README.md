# Missing Player AI Chatbot Engine

This project is a Flutter-built Missing Player AI Engine designed to manage multiple independent Gemini agent instances sharing a single, unified live timeline. The system acts as a tabletop session helper, allowing game masters to run multiple missing player characters as automated companion agents that are fully context-aware of the session events and each other's dialogue.

## Quick Start Deployment

Follow these terminal instructions to clone, configure, and launch the application:

1. Clone the repository to your local machine:
   ```bash
   git clone <repository_url>
   cd missing-player-chatbot
   ```

2. Create a configuration environment file named `.env` at the root of the project workspace and populate it with your Gemini API key:
   ```env
   GEMINI_API_KEY=your_actual_api_key_here
   ```

3. Retrieve project package dependencies:
   ```bash
   flutter pub get
   ```

4. Launch the application in desktop debug mode for Linux:
   ```bash
   flutter run -d linux
   ```

## Storage Architecture

All local campaign assets, character stats, profile configurations, and unified timelines are organized under the local `Saved_Prompts/` folder at the root of the workspace. The directory tree is structured as follows:

```text
Saved_Prompts/
└── characters/
    └── [character_name]/
        ├── [character_name].json <-- Profile Blueprint (JSON Schema)
        ├── identity.md            <-- Persona Constraints & Behavioral Directives
        ├── sheet.md               <-- Stats, Abilities, & Inventory (Markdown)
        ├── sheet_old.md           <-- Rollback Backup for Undo operations
        ├── summary.md             <-- Compacted Long-Term Memory Summary
        └── current_session.md     <-- Dialogue Session Timeline Log (Markdown)
```

## Presentation Feature Checklist

The following core underlying mechanics are available to showcase during presentation demonstrations:

* **Multi-Character Selection:** Sibling widget controls in the setup screen support multi-selecting checkboxes to bring more than one character profile into the active session simultaneously.
* **Shared Handshake Dialogue Loop:** Character sessions share a unified dialogue timeline file. When narration is submitted, the engine appends it to the log, then sequentially prompts each active character session. This ensures each companion agent reads previous characters' actions before formulating their response, maintaining context-awareness at the table.
* **Context-Aware Intent Roller:** The engine runs background intent extraction to determine if rolls (such as Initiative or Perception checks) are requested. A ValueNotifier updates the UI to dynamically display contextual action buttons that generate a d20 roll and write it straight to the session history.
* **Safe Undo Engine:** Background parsers update character condition tags and stats automatically. In case of unexpected changes or rolls, the engine supports a one-click rollback by swapping the active `sheet.md` with the backed-up `sheet_old.md`.
* **Tiered History Compactor:** When a character's active `current_session.md` timeline exceeds the 2,000-word threshold, a background compactor parses the oldest 70% of history, builds a 3-paragraph executive summary saved to `summary.md`, and purges the active log, keeping the LLM context size compact and fast.
