# Domain-Specific Skill Patterns

Patterns and templates for creating skills in specific domains.

## Healthcare / NDIS Domain

### Key Considerations
- Compliance and audit requirements
- Privacy and data protection (Australian Privacy Principles)
- Participant-centric language
- Integration with MyGov and NDIS portal
- Service agreement terminology

### Skill Categories
1. **Participant Management**: Plans, goals, supports, reviews
2. **Provider Operations**: Scheduling, billing, reporting
3. **Compliance**: Quality standards, incident reporting
4. **Assessment**: Functional capacity, support needs

### Example Frontmatter
```yaml
name: ndis-plan-management
description: NDIS plan creation and management with goal setting, support allocation, and budget tracking. Use when creating participant plans, reviewing support categories, or generating plan reports.
```

## Software Development Domain

### Key Considerations
- Framework-specific patterns (Flutter, React, etc.)
- Testing and debugging workflows
- Code quality and architecture
- Build and deployment

### Skill Categories
1. **Core Development**: Patterns, architecture, utilities
2. **Testing**: Unit, widget, integration testing
3. **API Integration**: REST, GraphQL, authentication
4. **Deployment**: CI/CD, versioning, releases

### Example Frontmatter (Flutter)
```yaml
name: flutter-widget-testing
description: Comprehensive Flutter widget testing toolkit with finder patterns, pump strategies, and golden testing. Use when writing widget tests, debugging test failures, or setting up test infrastructure.
```

## Business Operations Domain

### Key Considerations
- CRM and customer data
- Sales and marketing workflows
- Reporting and analytics
- Communication templates

### Skill Categories
1. **Customer Management**: Records, interactions, lifecycle
2. **Sales Workflows**: Pipeline, forecasting, closing
3. **Reporting**: Dashboards, metrics, exports
4. **Automation**: Triggers, notifications, integrations

### Example Frontmatter
```yaml
name: sales-pipeline-management
description: Sales pipeline tracking with opportunity scoring, forecast modeling, and stage management. Use when managing sales opportunities, generating forecasts, or analyzing conversion rates.
```

## Data & Analytics Domain

### Key Considerations
- Schema documentation
- Query optimization
- Data quality and validation
- Visualization patterns

### Skill Categories
1. **Query Building**: SQL, BigQuery, optimization
2. **ETL Workflows**: Extract, transform, load
3. **Data Quality**: Validation, cleansing, monitoring
4. **Visualization**: Charts, dashboards, reports

### Example Frontmatter
```yaml
name: bigquery-analytics
description: BigQuery analytics toolkit with query templates, cost optimization, and schema management. Use when building BigQuery queries, optimizing performance, or managing datasets.
```

## Creative & Design Domain

### Key Considerations
- Brand consistency
- Accessibility standards
- Design system components
- Asset management

### Skill Categories
1. **Brand Guidelines**: Colors, typography, voice
2. **Component Library**: UI patterns, templates
3. **Asset Management**: Images, icons, fonts
4. **Accessibility**: WCAG compliance, testing

### Example Frontmatter
```yaml
name: brand-design-system
description: Brand design system with color palettes, typography scales, and component patterns. Use when creating branded materials, checking design consistency, or generating style guides.
```

## Integration Patterns

### API Integration Template
```markdown
## Authentication
[Auth setup code]

## Endpoints
### GET /resource
### POST /resource

## Error Handling
| Code | Meaning | Action |

## Rate Limiting
[Rate limit strategy]
```

### Webhook Integration Template
```markdown
## Webhook Setup
[Registration process]

## Event Types
| Event | Payload | Response |

## Validation
[Signature verification]

## Error Recovery
[Retry strategies]
```
