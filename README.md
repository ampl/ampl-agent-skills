# AMPL Knowledge Skill

A portable Agent Skill that gives an LLM specialized knowledge of AMPL — syntax, the amplpy/ampls-api Python interfaces, modeling best practices, and tutorial content — to help OR and optimization practitioners (beginners through advanced) write better AMPL models.

Agent Skills are an open, filesystem-based format (a folder with a `SKILL.md` file plus reference material) for extending LLM agents with specialized knowledge. This skill has no dependency on any particular vendor or platform — it's plain Markdown reference content intended to work with any LLM tool or agent runtime that supports the Agent Skills format.

This repository is the distribution point for the skill. It contains the finished, ready-to-install package — not the source material or build process used to create it.

## What's in this repo

```
skill/                       # The skill itself (name: ampl-skill)
  SKILL.md                   # Entry point — routes questions to the right reference file
  CHANGELOG.md
  references/
    core-language/           # Syntax, sets, data, commands, scripting, options
    modeling-patterns/       # LP, network, columnwise, piecewise-linear, NLP, MIP, complementarity
    amplpy/                  # amplpy Python API
    ampls/                   # ampls solver-callback API
    mp-library/              # MP solver interface: expressions, multi-objective, reformulation
    solver-options/          # Gurobi, CPLEX, Xpress, COPT, HiGHS tuning guides
    tutorials-and-examples/  # Worked tutorial, reference models
    troubleshooting-and-faqs.md
.claude-plugin/              # Claude plugin manifest and marketplace catalog
packaging/                   # OpenAI/Codex plugin manifest and ZIP build script
assets/icon.png              # Listing icon
```

## Quick install via skill.ampl.com

[skill.ampl.com](https://skill.ampl.com) redirects to this repository, so if your AI tool can browse the web or run commands (e.g. Claude Code, Codex, Cursor), you can use the skill for the current session without installing it by simply telling your AI tool:

> load skill.ampl.com

To install it permanently, ask your AI tool:

> Install the AMPL agent skill from https://skill.ampl.com — download the `.skill` file from the latest release, unzip it, and add the `ampl-skill` folder to your skills directory.

## Install as a plugin

**Claude (Claude Code, claude.ai, Cowork):** this repository is a Claude plugin marketplace. In Claude Code, run:

```
/plugin install ampl --marketplace ampl/ampl-agent-skills
```

or, on older versions, `/plugin marketplace add ampl/ampl-agent-skills` followed by `/plugin install ampl@ampl`.

**OpenAI Codex:** each release includes an `ampl-codex-plugin-vX.Y.Z.zip` package in the Codex plugin layout.

## What the plugin does and doesn't do

The plugin contains one skill made only of Markdown reference files. It has no hooks, MCP servers, scripts, or executables, does not run AMPL or any solver, and does not read, store, or send any data. Claude loads the reference files only when a task involves AMPL.

## Installing the skill

The `skill/` folder is the installable unit. How you load it depends on your agent or tool's Agent Skills support — generally either:
- **Filesystem-based**: copy the contents of `skill/` into wherever your tool looks for installed skills (a local skills directory).
- **Upload-based**: download the `.skill` file from the latest [release](https://github.com/ampl/ampl-agent-skills/releases/latest) and upload it wherever your tool accepts skill packages (it's a standard zip archive, so you can rename it to `.zip` if your tool requires that).

Consult your specific tool's documentation for the exact mechanism it expects.

## Versioning

Releases are tagged (`v1.0.0`, `v1.1.0`, ...) at each point a new version is distributed. A GitHub Action creates the release and its `.skill` package automatically whenever the top version in `CHANGELOG.md` changes. See [CHANGELOG.md](./skill/CHANGELOG.md) for what changed in each version. There's no auto-update mechanism — updating an already-installed copy of the skill means re-downloading and re-uploading/replacing it wherever it's installed.

## Scope and limits

This skill is built from AMPL documentation, tutorials, and reference material current as of the date of each release — it reflects a snapshot, not a live feed. It does not execute or solve AMPL models; it provides knowledge to help write, structure, and troubleshoot them correctly.

