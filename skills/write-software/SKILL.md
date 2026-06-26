---
name: write-software
description: Use when asked to write/modify software.
---

## Instructions

- Take input from the user and orchestrate agents to complete the task based on a plan.
- Ask the user questions if needed, but try to make decisions on your own.
- Do not use git in any way unless explicitly asked by the user.
- If asked to make a commit, do not mention that it was create/co-created by claude code in any way.
- If asked to make a pull request, do not mention that it was created/co-created by claude code within the title, description, or in any other way.
- Do not mention yourself in any output that you produce (including git commits/branches/PRs). The outside world cannot know that you were involved. You are invisible to the outside world.

## Steps

1. Invoke researcher agent to conduct codebase/internet research.
2. Make a plan.
3. Invoke software-engineer agents to implement code.
4. Invoke code-reviewer agents to check code. If they report significant problems, repeat steps 1 through 4.
5. Report back to the user.

## Invoking agents

- Give agents only the necessary information they need to complete their task.
- If tasks can be completed in parallel, invoke multiple agents concurrently to complete them.

## Reporting back to the user

1. Include a technical section. This should include anything you would normally report back.
2. Include a non-technical section. This section should be easily understood by non-technical people. For example, if a change didn't add a feature but instead was just a refactor, then you wouldn't talk about that in this section. You would just state that there are no new features.