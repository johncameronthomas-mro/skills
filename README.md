# Skills

These are just some simple skills and agents I wrote. A status line script is also included.

## `write-software`

This skill is pretty self-explanatory. Although it's a pretty simple skill, I really like the workflow that it implements along with the agents.

## `git-rules`

This skill describes some simple rules that I like models to follow when working with git and related tools.

## `talk-like-muthur`

This skill is intended to replicate the communication style of "MU/TH/UR 6000" from *Alien*. It's mostly an experiment, but it does reduce token usage somewhat.

## `status_line.sh`

This is a status line I made that displays some useful information in a nice format.

### Format

```
<model> with <effort> effort · <percentage>% of context used · $<cost> spent · working in "<directory>" · on branch "<branch>"
```

For example:
```
Opus 5 with high effort · 5% of context used · $1.35 spent · working in "~/Projects/skills" · on branch "main"
```

The context percentage is green under 50%, yellow from 50 to 74%, and red at 75% and above. Any segment with no data is dropped.

### Usage

Run
```bash
chmod +x /path/to/status_line.sh
```
and add
```json
"statusLine": { "type": "command", "command": "bash /path/to/status_line.sh" }
```
to `~/.claude/settings.json`.