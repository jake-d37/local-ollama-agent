"""Terminal UI helpers using rich."""

from rich.console import Console
from rich.panel import Panel
from rich.text import Text
from rich import box

console = Console()


def print_banner(model: str, output_file: str) -> None:
    content = Text()
    content.append("Model   ", style="dim")
    content.append(f"{model}\n", style="cyan bold")
    content.append("Log     ", style="dim")
    content.append(str(output_file), style="dim")
    content.append("\n\nCommands: ", style="dim")
    content.append("/help  /clear  /model  /exit", style="dim italic")

    console.print(
        Panel(
            content,
            title="[bold blue]Ollama Chat Terminal[/bold blue]",
            border_style="blue",
            box=box.ROUNDED,
            padding=(0, 1),
        )
    )
    console.print()


def print_help() -> None:
    console.print("  [dim]/clear[/dim]   reset conversation history")
    console.print("  [dim]/model[/dim]   show current model")
    console.print("  [dim]/exit[/dim]    end session")
    console.print()


def print_model(model: str) -> None:
    console.print(f"  [dim]Current model:[/dim] [cyan]{model}[/cyan]\n")


def print_history_cleared() -> None:
    console.print("  [dim]History cleared.[/dim]\n")


def print_separator() -> None:
    console.print("[dim]" + "─" * 44 + "[/dim]")


def print_summary(msg_count: int, output_file: str) -> None:
    console.print()
    print_separator()
    console.print(f"  Exchanges : [cyan]{msg_count}[/cyan]")
    console.print(f"  Saved to  : [dim]{output_file}[/dim]")
    console.print()


def print_token_count(count: int) -> None:
    console.print(f"  [dim]({count} tokens)[/dim]")


def get_user_input() -> str:
    return console.input("[cyan bold] You › [/cyan bold]")