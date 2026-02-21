# Local Ollama Agent Runner

My personal take on creating an AI agent that you don't need to pay tokens for — a fully local, terminal-based chat interface powered by Ollama with persistent conversation history, a custom system prompt system, and a clean styled UI.

Basically a worse OpenClaw. Just building it from the ground up as a means of getting experience building AI systems.

## Prerequisites

### 1. Ollama

```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama -v
```

### 2. A model downloaded

```bash
ollama pull <model_name>
```

### 3. Required CLI tools

The runner depends on `jq` and `curl`. Install them if you don't have them:

```bash
# macOS
brew install jq curl

# Ubuntu/Debian
sudo apt install jq curl
```

### 4. Config file

Copy the example config and edit it to set your default model and system prompt:

```bash
cp resources/config.example.conf resources/config.conf
```

Edit `resources/config.conf` to set your preferences:

```properties
MODEL="mistral"
SYSTEM_PROMPT_PATH="$PROJECT_ROOT/system-prompts/_default.txt"
```

## How to use

Run the shell script from the project root:

```bash
./run_local_agent.sh --model <model_name>
```

Type your message and press **Enter twice** to send. Type `exit` to end the session.

### Available flags

| Flag | Description |
|---|---|
| `--model <name>` | Ollama model to use (overrides config default) |
| `--sysprompt <path>` | Path to a custom system prompt `.txt` file |
| `--output <path>` | Custom path for the session output log |
| `--help` | Show help text |

### Example

```bash
# Use a specific model
./run_local_agent.sh --model llama3

# Use a custom system prompt
./run_local_agent.sh --model mistral --sysprompt system-prompts/researcher.txt
```

## System prompts

System prompts live in the `system-prompts/` directory. The default prompt is loaded from the path set in `resources/config.conf`. You can create your own `.txt` files there and pass them in with `--sysprompt` to give the agent a different personality or set of instructions per session.

You can reset the default system prompt by updating `SYSTEM_PROMPT_PATH` in `resources/config.conf` to point to your preferred prompt.

## Session logs

Each session is automatically saved to an `outputs/` directory with a timestamped filename (`ollama_output_YYYYMMDD_HHMMSS.txt`), so you always have a record of your conversations.

## How to add skills

Drop scripts into the `skills/` folder. This system is still being developed — see next steps below.

## Next steps

- Ollama can call public functions from scripts in the repo
    - You can add your own functions that can be called by the agent by adding to the skills folder.
- Customisable personality system prompt
- Knowledge bases that you can call on per session (or not at all)
- Embed previous conversations in memory for future reference
    - Include `--ignore` tag to ensure this isn't inclulded in memory
- Possibility to send HTTP request to this and run that through Ollama
    - Can act as your home server to call from your phone etc.