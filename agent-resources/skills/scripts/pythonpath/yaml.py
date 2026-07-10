import json
import subprocess


class YAMLError(Exception):
    pass


def safe_load(text):
    script = (
        'input = STDIN.read; '
        'data = YAML.safe_load(input, aliases: true); '
        'puts JSON.generate(data)'
    )
    try:
        proc = subprocess.run(
            ["ruby", "-ryaml", "-rjson", "-e", script],
            input=text,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    except FileNotFoundError as e:
        raise YAMLError(
            "ruby not found on PATH. This repository's YAML shim "
            "(agent-resources/skills/scripts/pythonpath/yaml.py) parses YAML "
            "frontmatter by delegating to the system ruby. Install ruby "
            "(e.g. `brew install ruby`) and retry."
        ) from e

    if proc.returncode != 0:
        raise YAMLError(proc.stderr.strip() or "Ruby YAML parser failed")

    return json.loads(proc.stdout)
