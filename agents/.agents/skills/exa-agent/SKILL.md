---
name: exa-agent
description: "Use Exa Agent for multi-step web research, list-building, enrichment, structured output, run continuation, and coverage validation. Exa Agent can access additional data providers: fiber, financial_datasets, similarweb, baselayer, affiliate, particle, and jinko."
---

# Exa Agent with Pi

Pi can use Exa for advanced search and content fetching via the `exa-cli` UV tool.

## Prerequisites

- Exa API key stored in `~/.pi/agent/secrets/exa-api-key.txt`
- `exa-cli` installed as a UV tool

## Usage

### Simple Search
```bash
API_KEY=$(cat ~/.pi/agent/secrets/exa-api-key.txt) EXA_API_KEY=$API_KEY exa-cli search "query" --num=5
```

### Content Fetching
```bash
API_KEY=$(cat ~/.pi/agent/secrets/exa-api-key.txt) EXA_API_KEY=$API_KEY exa-cli fetch https://example.com/article
```

### Category Search
```bash
API_KEY=$(cat ~/.pi/agent/secrets/exa-api-key.txt) EXA_API_KEY=$API_KEY exa-cli search "top AI companies" --category=company --num=10
```

## Categories

Exa supports these categories:
- `company` - Company information and metadata
- `people` - People profiles and details
- `publication` - Academic papers and publications
- `news` - News articles
- `personal site` - Blogs and personal pages
- `financial report` - Financial documents
- `github` - GitHub repositories
- `tweet` - Tweets
- `pdf` - PDF documents
