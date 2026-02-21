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

## Tools

Any Python scripts placed in your tools directory can be called by the agent as tools. The tools directory defaults to `~/tools/` but can be changed by setting `TOOLS_DIR` in `resources/config.conf`.

For the agent to understand what tools are available, each function needs a docstring describing what it does. The program reads these docstrings to generate a **skills report** — a plain text summary of all callable functions — which is passed to the agent as part of its system prompt at the start of each session.

### Writing a tool

Add a docstring to any public function in your tool scripts:

```python
def mkdir(name: str):
    """Creates a directory with the given name in the current working directory.
    Example: [CALL:mkdir(my_folder)]
    """
    os.makedirs(name, exist_ok=True)
```

### Generating the skills report

After adding or updating any tool scripts, run this from the project root:

```bash
./generate_skills_report.sh
```

This scrapes the docstrings from all Python scripts in your tools directory and writes the result to `skills_report.txt` in the project root. Re-run it any time you make changes to your tools.

> **Warning:** If no skills report is present, the agent will have no knowledge of available tools and will not be able to call any of them. You'll see a warning at the start of the session if this is the case.

## Next steps

- Create a "call queue"
    - tool calling should run on a loop with the following structure
        - add call event to queue
        - run current call event
        - wait for response
        - evaluate whether there was an error, or whether next call should be run
- Ask permission to add something to the call queue
- Embedded knowledge base on local system 
- Knowledge bases that you can call on per session (or not at all)
- Embed previous conversations in memory for future reference
    - Include `--ignore` tag to ensure this isn't inclulded in memory
- Possibility to send HTTP request to this and run that through Ollama
    - Can act as your home server to call from your phone etc.

### Next steps (project maintainability)

- Add CI tests that check that the required folders exist
- Add test runner for personal tools