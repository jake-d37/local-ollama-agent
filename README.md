# Local Ollama Agent Runner

My personal take on creating an AI agent that you don't need to pay tokens for. This will literally just open Ollama and paste your prompt in there. 

Eventually it will be able to perform actions on your device based on what your local model thinks. 

## Prerequisites

1. You need Ollama

```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama -v
```

2. You need a model downloaded

```bash
ollama pull <model_name>
```

## How to use

Run the shell script `run_local_agent.sh`

```bash
./run_local_agent --model model_name
```

Speak to the agent and tell it your prompt.

## How to add skills

Haven't worked this out yet

## Next steps

- Improve TUI
- Ollama can call public functions from scripts in the repo
    - You can add your own functions that can be called by the agent by adding to the skills folder. 
- Customisable personality system prompt 
- Knowledge bases that you can call on per session (or not at all)