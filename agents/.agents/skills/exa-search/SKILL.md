---
name: exa-search
description: "Deep research powered by Exa. Use for lead generation, literature reviews, deep dives, competitive analysis, or any query where one search falls short, including phrases like 'research this', 'find everything about', 'find me all', or 'deep dive on'."
---

# Exa Research with Pi

Pi can use Exa search via `uv tool`. The CLI is installed as `exa-cli` (UV tool) and the API key is in `~/.pi/agent/secrets/exa-api-key.txt`.

## Commands

### Search
```bash
API_KEY=$(cat ~/.pi/agent/secrets/exa-api-key.txt) EXA_API_KEY=$API_KEY exa-cli search "your query" --num=5
```

### Fetch content
```bash
API_KEY=$(cat ~/.pi/agent/secrets/exa-api-key.txt) EXA_API_KEY=$API_KEY exa-cli fetch https://example.com
```

## Usage in Pi

Pi should:
1. Read the API key from the secrets file
2. Run the exa-cli command via bash tool
3. Parse the JSON output
4. Summarize or use the results

## Example search pattern
```bash
API_KEY=$(cat ~/.pi/agent/secrets/exa-api-key.txt) EXA_API_KEY=$API_KEY exa-cli search "best AI research papers 2025" --num=10
```

## Example fetch pattern
```bash
API_KEY=$(cat ~/.pi/agent/secrets/exa-api-key.txt) EXA_API_KEY=$API_KEY exa-cli fetch https://example.com/article --num=10
```
