# TODOs

We need to create a plan for all these in the proper order

Change repo name to agent-box-tooling and delete the old repo

Get a proper terminal (Ghostty)

## AI setup

I need to set up the AI in a way that I can add skills. I need to set up security. I need to have an agent's MD file. And Claude MD should actually be the link to this file. In the agent's MD, I want to have a concise style that's part AI setup.

Second is skill setup for the different agents that I'm using which is Claude Code, Cursor CLI, and Codex. These need skills and rules and different directories, and I want to have the skills in a general format and setup, and then just copy them over to the places where the tools expect them. Also, if I'm at a certain system like my laptop and I change the rules there or add something to the agents' MD, I want some way to sync them back to this repository, and then sync from this repository back to the other repos and systems that I have.

## Github ssh keys

I need to create SSH keys to be able to work with GitHub, and these should be separate from my normal keys. I also need to store my normal keys in Bitwarden to actually store them in a safe place.

## Ubuntu only

I want to remove the Windows parts for the setup.The setup should be Ubuntu only. I want to make this way more concise, so this is the reason why I want to have a thing in the agents.md file where I say "be concise, don't talk so much, don't do so many graphical things and overviews and all this stuff that agents do like to do which I actually don't". There's setup tips as well, I would need to go through them.

## AI sec

Also, a very big part is the security setup. So, I would actually like to run in "dangerously set" you know, YOLO mode, whatever, but I want to restrict network access for this to only a couple of domains where it can be fairly certain that the probability of a prompt injection attack is fairly low. Also, I would try and limit the agents to the projects directory and maybe home projects or whatever. Another one where I just mount stuff, and I would have to figure out the mounting part as well. So, for instance, I would have Ubuntu, I would mount from the external file system, and then I would change route to try to prevent the agent from doing harmful things.

## Browser automation

I also want to try if Cursor CLI, which has the browser baked in, actually works on Windows. I also have to try, well, I should actually vote for a bug where Claude on WSL is not working, and I need to check out if Codex has a thing for this. So, I only need one tool that can work in a browser, but I definitely need one tool that actually can do it.

## Consolidate with blocks-docs/setup

There are a couple of setup instructions already in the docs project, and I am going to move them out and move them here.

## Initial VM setup

Then I would need a way to set up a VM. This VM should obviously run Ubuntu, of course. But I need support for microphones. I may need support for snapshots. It should be seamless working with it. It should be nice. I should be able to run like four of them on a Windows host machine. I'm willing to pay money if the solution is superior.
The VM should be able to run all these coding agents, so Claude, Codex and Cursor CLI. It should have Cursor. It should have all the tools we need. The Bash should do apt update, apt upgrade, and all this. So there needs to be kind of like a bootstrap script, I guess, which just maybe is cloned or copied or even pasted and pulls the Git repo and does all the tooling and then has the list of things it actually needs to do to follow these steps. But I'm not really sure what it will need to do. But I could try and figure this out basically when I create the VM. And then we'll see what happens.

## IDE tooling

I want, of course, all the when I set up a project, right? So I will check out certain projects (maybe always all of them) into the projects folder, and then I will need to install Cursor and install all the extensions. I would like to automate this so I don't have to do this over and over and over again. Then there are style concerns, so for instance, I have a plugin it's called MarkdownLint and it has certain rules that the markdowns that the browser creates (well, that the agent creates) is different and doesn't follow these rules, so I have to manually adjust this. There should be a rule if there's something off. Can I actually add a skill for it? Which I need to put into agentsMDE. Bottom line is there should be skills and guidelines to actually make the agent work better with all this stuff.

## To explore later

### Claude

[Status line](https://code.claude.com/docs/en/statusline)
[AGENTS.md should have only ~500 lines, move stuff to skills](https://code.claude.com/docs/en/costs#move-instructions-from-claude-md-to-skills)
[More skills](https://code.claude.com/docs/en/skills) and [https://simonwillison.net/2025/Oct/16/claude-skills/](https://simonwillison.net/2025/Oct/16/claude-skills/)
[LSP / Code intelligence plugins](https://code.claude.com/docs/en/discover-plugins#code-intelligence)
[Subagents](https://code.claude.com/docs/en/sub-agents)
[Check workflow here](https://code.claude.com/docs/en/costs#work-efficiently-on-complex-tasks)

### Codex

[simonwillison openai-skills](https://simonwillison.net/2025/Dec/12/openai-skills/)
