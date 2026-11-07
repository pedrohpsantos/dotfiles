## Description of Changes

<!-- Briefly describe the technical purpose and changes included in this PR -->

## Type of Change

- [ ] `fix`: Bug fix, error resolution, or regression patch
- [ ] `feat`: New Stow module, script, or configuration feature
- [ ] `docs`: Documentation updates or additions
- [ ] `refactor`: Structural code cleanup without changing behavior
- [ ] `style`: Formatting, whitespace, or aesthetics
- [ ] `chore`: CI, tooling, dependency, or governance updates

## Quality & Governance Checklist

- [ ] All shell scripts pass `sh -n` without syntax errors
- [ ] ShellCheck passes with zero warnings: `shellcheck install.sh` and `shellcheck -S style local-bin/.local/bin/*`
- [ ] Zsh files pass syntax check: `zsh -n zsh/.zshenv zsh/.zprofile zsh/.zshrc`
- [ ] Dry-run simulation tested: `./install.sh --dry-run`
- [ ] Stow conflict check passes: `stow --simulate --restow --no-folding -t "$HOME" ...`
- [ ] No secrets, tokens, or credentials added (`gitleaks detect`)
- [ ] No Mason or glibc dependencies introduced (strict musl compatibility)
- [ ] Corresponding documentation updated in `docs/` or `README.md`
