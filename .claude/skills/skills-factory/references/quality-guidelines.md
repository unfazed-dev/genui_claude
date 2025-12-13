# Skill Quality Guidelines

Best practices for creating high-quality Claude skills.

## Content Quality

### The Token Economy Principle

Every token in a skill must justify its cost. The context window is shared with:
- System prompt
- Conversation history
- Other skills' metadata
- User messages

**Ask for each paragraph:**
- Does Claude really need this explanation?
- Could this be shortened without losing meaning?
- Is this information Claude doesn't already have?

### Writing Style

**DO:**
- Use imperative voice: "Extract the data" not "You should extract"
- Use third-person in descriptions: "Processes files" not "I process files"
- Be concise: Prefer examples over explanations
- Be specific: Include concrete triggers and file types

**DON'T:**
- Include unnecessary context about skill creation
- Explain things Claude already knows
- Use passive voice excessively
- Include user documentation (README, CHANGELOG)

## Progressive Disclosure

### Level 1: Metadata (~100 words)
Loaded at startup for ALL skills:
- `name`: Short identifier
- `description`: Comprehensive but concise

### Level 2: SKILL.md Body (<5k words)
Loaded when skill triggers:
- Core instructions
- Quick start examples
- Links to detailed references

### Level 3: Bundled Resources (unlimited)
Loaded on-demand:
- Detailed documentation
- Large code libraries
- Domain-specific schemas

## Freedom Levels

Match constraint level to operation fragility:

### High Freedom (Guidelines Only)
Use when:
- Multiple valid approaches exist
- Context determines best action
- Creativity is beneficial

Example:
```markdown
## Writing Style
- Keep responses conversational
- Adapt tone to user context
- Use examples when helpful
```

### Medium Freedom (Parameterized)
Use when:
- Preferred patterns exist
- Some variation acceptable
- Configuration affects behavior

Example:
```markdown
## Report Generation
Generate reports using this structure:
1. Executive Summary (2-3 paragraphs)
2. Key Findings (adapt sections to content)
3. Recommendations (specific and actionable)

Adjust depth based on user request.
```

### Low Freedom (Exact Scripts)
Use when:
- Operations are fragile
- Consistency is critical
- Exact sequence required

Example:
```markdown
## PDF Form Filling

ALWAYS follow this exact sequence:
1. Run `scripts/extract_fields.py` to get field list
2. Run `scripts/validate_fields.py` to check values
3. Run `scripts/fill_form.py` to apply values
4. Run `scripts/verify_output.py` to confirm success

DO NOT skip steps or reorder.
```

## Description Best Practices

### Formula
```
[Core capability] for [domain/type]. Use when [trigger 1], [trigger 2], or [trigger 3].
```

### Checklist
- [ ] Describes WHAT the skill does
- [ ] Describes WHEN to use it
- [ ] Uses third-person voice
- [ ] Under 200 characters (ideal)
- [ ] Under 1024 characters (maximum)
- [ ] Includes relevant file types/keywords

### Examples

**Good:**
```
Comprehensive PDF manipulation toolkit for extracting text and tables, creating new PDFs, merging/splitting documents, and handling forms. When Claude needs to fill in a PDF form or programmatically process, generate, or analyze PDF documents at scale.
```

**Bad:**
```
A skill that helps with PDFs. (Too vague, no triggers)
```

**Bad:**
```
I can help you work with PDF files whenever you need to do something with them. (First person, vague)
```

## Bundled Resources

### Scripts (`scripts/`)
- Must be executable
- Must have shebang (#!/usr/bin/env python3)
- Must have docstring
- Should be tested
- Should handle errors gracefully

### References (`references/`)
- Must be referenced from SKILL.md
- Should indicate when to read them
- Should not duplicate SKILL.md content
- Keep under 10k words each

### Assets (`assets/`)
- For files used in output
- Not loaded into context
- Include templates, images, fonts
- Organize in subdirectories if many

## Anti-Patterns

### Content Anti-Patterns
1. **Kitchen Sink**: Including everything; be focused
2. **Explanation Overload**: Claude is smart; be concise
3. **Redundant Documentation**: No README, CHANGELOG
4. **First Person Voice**: Always use third person
5. **Vague Descriptions**: Must specify WHEN to use

### Structure Anti-Patterns
1. **Monolithic SKILL.md**: Split large content to references
2. **Untested Scripts**: All scripts must be verified
3. **Orphaned References**: Must be referenced from SKILL.md
4. **Excessive Nesting**: Keep directory structure flat

### Trigger Anti-Patterns
1. **No Trigger Info**: Description must say when to use
2. **Generic Triggers**: Be specific to your domain
3. **Conflicting Triggers**: Don't overlap with other skills

## Quality Checklist

Before packaging:

- [ ] SKILL.md starts with valid YAML frontmatter
- [ ] `name` is hyphen-case, matches directory
- [ ] `description` includes what and when
- [ ] Body is under 500 lines
- [ ] No TODO placeholders remain
- [ ] All referenced files exist
- [ ] Scripts have shebangs and docstrings
- [ ] Scripts are executable and tested
- [ ] No forbidden files (README, CHANGELOG)
- [ ] Progressive disclosure is appropriate
