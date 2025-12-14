# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-12-14

### Added

- **AnthropicContentGenerator**: Main `ContentGenerator` implementation for Claude AI
  - Direct API mode for development with API key
  - Proxy mode for production deployments (keeps API key on backend)
  - Streaming support for progressive UI rendering
  - Configurable timeouts, retries, and max tokens

- **A2uiMessageAdapter**: Bidirectional message conversion
  - Converts `anthropic_a2ui` messages to GenUI `A2uiMessage` format
  - Supports all A2UI message types: BeginRendering, SurfaceUpdate, DataModelUpdate, SurfaceDeletion
  - Preserves all properties including metadata and component data

- **CatalogToolBridge**: Catalog-to-tool conversion utilities
  - `fromItems()`: Convert list of `CatalogItem` to Claude tool schemas
  - `fromCatalog()`: Convert `Catalog` instance to tool schemas
  - `withA2uiTools()`: Combine widget tools with A2UI control tools
  - Automatic JSON schema conversion from `json_schema_builder`

- **A2uiControlTools**: Pre-defined A2UI control tool schemas
  - `beginRendering`: Initialize surface rendering
  - `surfaceUpdate`: Add/update UI components
  - `dataModelUpdate`: Update surface data model
  - `deleteSurface`: Remove a surface

- **MessageConverter**: GenUI to Claude message conversion
  - Converts `ChatMessage` history to Claude API format
  - Handles user messages, assistant messages, and tool results
  - Supports text and tool use content blocks

- **Configuration classes**:
  - `AnthropicConfig`: Direct mode settings (maxTokens, timeout, retries, streaming, headers)
  - `ProxyConfig`: Proxy mode settings (timeout, retries, includeHistory, maxHistoryMessages, headers)

### Dependencies

- Requires `genui: ^0.5.1`
- Requires `anthropic_a2ui` (sibling package)
- Flutter SDK `>=3.22.0`
- Dart SDK `^3.5.0`
