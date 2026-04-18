#!/bin/bash

set -e

# 1. Listar branches remotas e escolher com fzf
select_branch=$(git branch -r | fzf --height 40% --layout=reverse --border | cut -d/ -f2- | sed 's/ *//')

if [[ -z "$select_branch" ]]; then
  echo "Nenhuma branch selecionada."
  exit 1
fi

# 2. Extrair apenas o nome da branch remota (sem 'origin/' para o fetch)
branch_name=$(echo "$select_branch" | sed 's|origin/||')

# 3. Buscar a branch remota
git fetch origin "$branch_name"
git checkout "$branch_name"

# 4. Gerar diff
git diff $(git merge-base HEAD origin/master) > /tmp/diff.patch

# 5. Preparar prompt para o Copilot CLI
prompt=$(cat <<EOF
You are a senior reviewer. Review this merge request diff:

$(cat /tmp/diff.patch)

Review this PR for:
- correctness
- readability
- maintainability
- test coverage
- backward compatibility

Rules:
- Only flag issues supported by evidence in the diff or provided context.
- Separate findings into Confirmed Issues, Possible Risks, and Nice-to-Have Improvements.
- For each finding, include severity, evidence, why it matters, and a concrete fix.
- If no major issues are present, say: No major issues detected.

Output:
1. One-paragraph summary
2. Findings by severity
3. ready-to-paste GitHub review comments

Respond in structured markdown.
Generate everything in pt-br.
EOF
)

# 6. Usar o copilot cli (ajuste se o seu comando for diferente)
copilot -p "$prompt" --model gpt-4.1 --allow-all-tools > /tmp/review.md

exit 0
