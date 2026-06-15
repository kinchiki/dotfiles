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
    proc = subprocess.run(
        ["ruby", "-ryaml", "-rjson", "-e", script],
        input=text,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )

    if proc.returncode != 0:
        raise YAMLError(proc.stderr.strip() or "Ruby YAML parser failed")

    return json.loads(proc.stdout)
