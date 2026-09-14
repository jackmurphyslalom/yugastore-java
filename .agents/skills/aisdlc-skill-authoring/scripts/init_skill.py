#!/usr/bin/env python3
"""Create a lean agent-skill scaffold."""

import argparse
import re
import sys
from pathlib import Path
from typing import List, Optional


VALID_RESOURCES = {"scripts", "references", "assets"}
NAME_PATTERN = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")

SKILL_TEMPLATE = """---
name: {skill_name}
description: "TODO: State what this skill does and the distinct situations that should trigger it."
---

# {skill_title}

TODO: Describe the outcome this skill enables in one sentence.

## Grounding Examples

- Typical: TODO
- Difficult or ambiguous: TODO
- Near miss that should not use this skill: TODO

## Workflow

### 1. TODO: Name the action

TODO: Give the agent the action, constraints needed at this point, and any
direct links to optional resources.

Completion criterion: TODO: State an observable condition.

## Definition of Done

- TODO: State the user-visible outcome.
- Every referenced file exists and is one hop from this file.
"""


def title_case_skill_name(skill_name: str) -> str:
    return " ".join(word.capitalize() for word in skill_name.split("-"))


def validate_skill_name(skill_name: str) -> Optional[str]:
    if len(skill_name) > 64:
        return "Skill name must be 64 characters or fewer"
    if not NAME_PATTERN.fullmatch(skill_name):
        return "Skill name must use lowercase letters, digits, and single hyphens"
    return None


def parse_resources(raw_resources: Optional[str]) -> List[str]:
    if not raw_resources:
        return []

    resources: List[str] = []
    for value in raw_resources.split(","):
        resource = value.strip()
        if not resource:
            continue
        if resource not in VALID_RESOURCES:
            raise ValueError(f"Unknown resource type: {resource}")
        if resource not in resources:
            resources.append(resource)
    return resources


def init_skill(skill_name: str, output_path: str, resources: List[str]) -> Path:
    skill_dir = Path(output_path).resolve() / skill_name
    if skill_dir.exists():
        raise ValueError(f"Skill directory already exists: {skill_dir}")

    skill_dir.mkdir(parents=True)
    skill_md = skill_dir / "SKILL.md"
    skill_md.write_text(
        SKILL_TEMPLATE.format(
            skill_name=skill_name,
            skill_title=title_case_skill_name(skill_name),
        ),
        encoding="utf-8",
    )

    for resource in resources:
        (skill_dir / resource).mkdir()

    return skill_dir


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Create a lean agent-skill scaffold")
    parser.add_argument("skill_name", help="Kebab-case skill name")
    parser.add_argument("--path", required=True, help="Directory that will contain the skill")
    parser.add_argument(
        "--resources",
        help="Comma-separated optional directories: scripts,references,assets",
    )
    return parser


def main() -> int:
    args = build_parser().parse_args()

    name_error = validate_skill_name(args.skill_name)
    if name_error:
        print(f"Error: {name_error}")
        return 1

    try:
        resources = parse_resources(args.resources)
        skill_dir = init_skill(args.skill_name, args.path, resources)
    except (OSError, ValueError) as error:
        print(f"Error: {error}")
        return 1

    print(f"Created skill: {skill_dir}")
    print("Next: replace every TODO, remove unused resources, then run quick_validate.py")
    return 0


if __name__ == "__main__":
    sys.exit(main())
