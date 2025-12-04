# createBlockEnvironment Design Plan

## 📋 Overview

`createBlockEnvironment` is a new version of `createNewComponent` that creates **complete design environment** for a specific block (DUT).

### Purpose
- **Validation & Verification**: Lint, UPF Verify, SDC Verify, Simulation
- **Synthesis**: Using Design Compiler, etc.
- **Timing Analysis**: Timing verification through STA
- **Formal Verification**: Equivalence Check, etc.

### Core Design Principles
1. **YAML-based Configuration**: Template variables managed in `config/template.yaml`
2. **Jinja2 Templates**: All generated files are template-based
3. **Polymorphism-based Generators**: Extensibility through Base Class + concrete classes
4. **Override Notification**: Notify user when config values are changed via CLI arguments

---

## 🏗️ Directory Structure

### Project Structure

```
createBlockEnvironment/
├── config/
│   ├── folders.yaml          # Folder structure definition
│   ├── files.yaml            # File generation definition (template mapping)
│   └── template.yaml         # Template variables definition (code + user)
├── template/
│   ├── filelist/
│   │   ├── package_rtl.f.jinja2
│   │   ├── package_models.f.jinja2
│   │   ├── package_tb.f.jinja2
│   │   └── package_svt.f.jinja2
│   ├── rtl/
│   │   └── wrapper.sv.jinja2
│   ├── lint/
│   │   ├── Makefile.jinja2
│   │   └── hooks/
│   │       ├── pre_check.tcl.jinja2
│   │       └── post_check.tcl.jinja2
│   ├── upfVerify/
│   │   ├── Makefile.jinja2
│   │   └── hooks/
│   │       ├── pre_check.tcl.jinja2
│   │       └── post_check.tcl.jinja2
│   ├── sdcVerify/
│   │   ├── Makefile.jinja2
│   │   └── hooks/
│   │       ├── pre_check.tcl.jinja2
│   │       └── post_check.tcl.jinja2
│   ├── synthesis/
│   │   ├── Makefile.jinja2
│   │   └── hooks/
│   │       ├── pre_elaborate.tcl.jinja2
│   │       ├── post_elaborate.tcl.jinja2
│   │       ├── pre_compile.tcl.jinja2
│   │       └── post_compile.tcl.jinja2
│   ├── formal/
│   │   ├── Makefile.jinja2
│   │   └── hooks/
│   │       ├── pre_check.tcl.jinja2
│   │       └── post_check.tcl.jinja2
│   ├── magillem/
│   │   └── Makefile.jinja2
│   ├── sim/
│   │   ├── Makefile.jinja2
│   │   └── testbench/
│   │       ├── interface.sv.jinja2
│   │       ├── tb_program.sv.jinja2
│   │       ├── tb.sv.jinja2
│   │       └── model.sv.jinja2
│   ├── uvmComponent/
│   │   ├── pkg.sv.jinja2
│   │   ├── driver.svh.jinja2
│   │   ├── monitor.svh.jinja2
│   │   ├── agent.svh.jinja2
│   │   ├── scoreboard.svh.jinja2
│   │   ├── sequencer.svh.jinja2
│   │   ├── sequence.svh.jinja2
│   │   ├── ral.svh.jinja2
│   │   ├── env.svh.jinja2
│   │   └── test.svh.jinja2
│   └── readme/
│       └── README.md.jinja2
├── src/
│   ├── main.py                     # Entry point
│   ├── generators/
│   │   ├── __init__.py
│   │   ├── base.py                 # Abstract Base Class
│   │   ├── makefile.py             # Makefile generator
│   │   ├── hook.py                 # Hook script generator
│   │   ├── filelist.py             # Filelist generator
│   │   ├── testbench.py            # Testbench generator
│   │   ├── uvm.py                  # UVM Component generator
│   │   ├── readme.py               # README generator
│   │   └── gitkeep.py              # .gitkeep inserter
│   └── utils/
│       ├── __init__.py
│       ├── verbose.py              # Verbose logging utility (simplified, no decorators)
│       ├── argument.py             # CLI argument parser
│       ├── config_loader.py        # YAML config loader + Override handler
│       └── file_ops.py             # File operations (folder + copy + symlink)
└── requirements.txt
```

### Generated Output Structure

```
<output_path>/
├── 00.constraint/
│   ├── sdc/
│   │   └── origin/
│   └── upf/
│       └── origin/
├── 01.rtl/
│   ├── filelist/
│   │   ├── package_rtl.f
│   │   └── package_models.f
│   ├── ipxact/
│   │   └── <by cli argument>
│   ├── magillem/
│   │   ├── script/
│   │   └── Makefile
│   ├── ip_bundle/
│   │   └── <by cli argument>
│   └── verilog/
│       ├── wrapper/
│       │   └── <block_name>_wrapper.sv
│       └── <symbolic_link_of_ip_bundles>
├── 02.lint/
│   ├── Makefile
│   └── script/
│       └── hooks/
│           ├── pre_check.tcl
│           └── post_check.tcl
├── 03.upfVerify/
│   ├── Makefile
│   └── script/
│       └── hooks/
│           ├── pre_check.tcl
│           └── post_check.tcl
├── 04.sdcVerify/
│   ├── Makefile
│   └── script/
│       └── hooks/
│           ├── pre_check.tcl
│           └── post_check.tcl
├── 05.synthesis/
│   ├── Makefile
│   └── script/
│       └── hooks/
│           ├── pre_elaborate.tcl
│           ├── post_elaborate.tcl
│           ├── pre_compile.tcl
│           └── post_compile.tcl
├── 06.formal/
│   ├── Makefile
│   └── script/
│       └── hooks/
│           ├── pre_check.tcl
│           └── post_check.tcl
├── 10.sim/
│   ├── 01.filelist/
│   │   ├── package_tb.f
│   │   └── package_svt.f
│   ├── 02.tb/
│   │   ├── <block_name>_if.sv
│   │   ├── tb_program.sv
│   │   └── tb.sv
│   ├── 03.uvmComponent/
│   │   ├── driver/
│   │   │   └── <block_name>_driver.svh
│   │   ├── monitor/
│   │   │   └── <block_name>_monitor.svh
│   │   ├── agent/
│   │   │   └── <block_name>_agent.svh
│   │   ├── scoreboard/
│   │   │   └── <block_name>_scoreboard.svh
│   │   ├── sequencer/
│   │   │   └── <block_name>_sequencer.svh
│   │   ├── sequence/
│   │   │   └── <block_name>_example_seq.svh
│   │   ├── ral/
│   │   │   └── <block_name>_ral.svh
│   │   ├── env/
│   │   │   └── <block_name>_env.svh
│   │   ├── test/
│   │   │   └── <block_name>_base_test.svh
│   │   └── <block_name>_pkg.sv
│   ├── 04.simModels/
│   │   └── <block_name>_model.sv
│   └── 10.run/
│       ├── Makefile
│       └── log/
└── README.md
```

---

## 📁 YAML Configuration Design

### `config/template.yaml`

Defines all variables passed to Jinja2 templates. Divided into `code` and `user` sections.

```yaml
# config/template.yaml
# ============================================================================
# All key-value pairs in this file are passed directly to Jinja2 templates.
# Users can refer to this file to check available variables in templates.
# ============================================================================

#==============================================================================
# code: Values automatically set by Python code
#       - Overridden by CLI arguments or environment variables
#       - Notifies user via verbose when overridden
#       - Users do not need to modify these directly
#==============================================================================
code:
  block_name: ""                    # [Required] Overridden by first CLI argument
  author: ""                        # Overridden by USER environment variable
  date: ""                          # Overridden by current date (YYYY-MM-DD)
  version: "v01p00"                 # Script version
  output_path: ""                   # Overridden by CLI -o argument
  ip_bundle_paths: []               # Overridden by CLI -ip argument
  vlog_link_targets: []             # Overridden by CLI -t argument
  
  # Auto-generated by FilelistGenerator (for package_rtl.f)
  rtl_files: []                     # List of RTL files found in ip_bundle/*, wrapper/*
  rtl_incdirs: []                   # List of include directories

#==============================================================================
# user: Static values for user to use in templates
#       - Users modify these directly
#       - For dynamic values: modify Python code after generation
#==============================================================================
user:
  # Example: User-defined variables (add as needed)
  # project_name: "MyProject"
  # company_name: "SuperGate"
  # custom_define: "MY_DEFINE"
```

### `config/folders.yaml`

Defines the folder structure to be generated.

```yaml
# config/folders.yaml
# Folder structure definition - gitkeep: true inserts .gitkeep in empty folders

folders:
  # Constraints
  - path: "00.constraint/sdc"
    gitkeep: true
  - path: "00.constraint/sdc/origin"
    gitkeep: true
  - path: "00.constraint/upf"
    gitkeep: true
  - path: "00.constraint/upf/origin"
    gitkeep: true

  # RTL
  - path: "01.rtl/filelist"
  - path: "01.rtl/ipxact"
    gitkeep: true
  - path: "01.rtl/magillem/script"
    gitkeep: true
  - path: "01.rtl/ip_bundle"
    gitkeep: true
  - path: "01.rtl/verilog/wrapper"

  # Lint
  - path: "02.lint/script/hooks"

  # UPF Verify
  - path: "03.upfVerify/script/hooks"

  # SDC Verify
  - path: "04.sdcVerify/script/hooks"

  # Synthesis
  - path: "05.synthesis/script/hooks"

  # Formal
  - path: "06.formal/script/hooks"

  # Simulation
  - path: "10.sim/01.filelist"
  - path: "10.sim/02.tb"
  - path: "10.sim/03.uvmComponent/driver"
  - path: "10.sim/03.uvmComponent/monitor"
  - path: "10.sim/03.uvmComponent/agent"
  - path: "10.sim/03.uvmComponent/scoreboard"
  - path: "10.sim/03.uvmComponent/sequencer"
  - path: "10.sim/03.uvmComponent/sequence"
  - path: "10.sim/03.uvmComponent/ral"
  - path: "10.sim/03.uvmComponent/env"
  - path: "10.sim/03.uvmComponent/test"
  - path: "10.sim/04.simModels"
    gitkeep: true
  - path: "10.sim/10.run/log"
    gitkeep: true
```

### `config/files.yaml`

Defines files to generate and their template mappings.

```yaml
# config/files.yaml
# File generation definition - maps templates to output paths
# Output paths can use variables like {{ block_name }}

files:
  # ============================================================================
  # Filelist (Template-based)
  # ============================================================================
  # package_rtl.f: Auto-filled with ip_bundles/*, wrapper/* files and +incdir+
  - template: "filelist/package_rtl.f.jinja2"
    output: "01.rtl/filelist/package_rtl.f"
    generator: "FilelistGenerator"

  # package_models.f: Template with intentional error (user must modify)
  - template: "filelist/package_models.f.jinja2"
    output: "01.rtl/filelist/package_models.f"
    generator: "FilelistGenerator"

  # package_tb.f: Template (user modifies later)
  - template: "filelist/package_tb.f.jinja2"
    output: "10.sim/01.filelist/package_tb.f"
    generator: "FilelistGenerator"

  # package_svt.f: Template (TBD - controlled by -svt argument later)
  - template: "filelist/package_svt.f.jinja2"
    output: "10.sim/01.filelist/package_svt.f"
    generator: "FilelistGenerator"

  # ============================================================================
  # RTL
  # ============================================================================
  - template: "rtl/wrapper.sv.jinja2"
    output: "01.rtl/verilog/wrapper/{{ block_name }}_wrapper.sv"
    generator: "TestbenchGenerator"

  # ============================================================================
  # Magillem
  # ============================================================================
  - template: "magillem/Makefile.jinja2"
    output: "01.rtl/magillem/Makefile"
    generator: "MakefileGenerator"

  # ============================================================================
  # Lint
  # ============================================================================
  - template: "lint/Makefile.jinja2"
    output: "02.lint/Makefile"
    generator: "MakefileGenerator"

  - template: "lint/hooks/pre_check.tcl.jinja2"
    output: "02.lint/script/hooks/pre_check.tcl"
    generator: "HookGenerator"

  - template: "lint/hooks/post_check.tcl.jinja2"
    output: "02.lint/script/hooks/post_check.tcl"
    generator: "HookGenerator"

  # ============================================================================
  # UPF Verify
  # ============================================================================
  - template: "upfVerify/Makefile.jinja2"
    output: "03.upfVerify/Makefile"
    generator: "MakefileGenerator"

  - template: "upfVerify/hooks/pre_check.tcl.jinja2"
    output: "03.upfVerify/script/hooks/pre_check.tcl"
    generator: "HookGenerator"

  - template: "upfVerify/hooks/post_check.tcl.jinja2"
    output: "03.upfVerify/script/hooks/post_check.tcl"
    generator: "HookGenerator"

  # ============================================================================
  # SDC Verify
  # ============================================================================
  - template: "sdcVerify/Makefile.jinja2"
    output: "04.sdcVerify/Makefile"
    generator: "MakefileGenerator"

  - template: "sdcVerify/hooks/pre_check.tcl.jinja2"
    output: "04.sdcVerify/script/hooks/pre_check.tcl"
    generator: "HookGenerator"

  - template: "sdcVerify/hooks/post_check.tcl.jinja2"
    output: "04.sdcVerify/script/hooks/post_check.tcl"
    generator: "HookGenerator"

  # ============================================================================
  # Synthesis
  # ============================================================================
  - template: "synthesis/Makefile.jinja2"
    output: "05.synthesis/Makefile"
    generator: "MakefileGenerator"

  - template: "synthesis/hooks/pre_elaborate.tcl.jinja2"
    output: "05.synthesis/script/hooks/pre_elaborate.tcl"
    generator: "HookGenerator"

  - template: "synthesis/hooks/post_elaborate.tcl.jinja2"
    output: "05.synthesis/script/hooks/post_elaborate.tcl"
    generator: "HookGenerator"

  - template: "synthesis/hooks/pre_compile.tcl.jinja2"
    output: "05.synthesis/script/hooks/pre_compile.tcl"
    generator: "HookGenerator"

  - template: "synthesis/hooks/post_compile.tcl.jinja2"
    output: "05.synthesis/script/hooks/post_compile.tcl"
    generator: "HookGenerator"

  # ============================================================================
  # Formal
  # ============================================================================
  - template: "formal/Makefile.jinja2"
    output: "06.formal/Makefile"
    generator: "MakefileGenerator"

  - template: "formal/hooks/pre_check.tcl.jinja2"
    output: "06.formal/script/hooks/pre_check.tcl"
    generator: "HookGenerator"

  - template: "formal/hooks/post_check.tcl.jinja2"
    output: "06.formal/script/hooks/post_check.tcl"
    generator: "HookGenerator"

  # ============================================================================
  # Simulation - Makefile
  # ============================================================================
  - template: "sim/Makefile.jinja2"
    output: "10.sim/10.run/Makefile"
    generator: "MakefileGenerator"

  # ============================================================================
  # Simulation - Testbench
  # ============================================================================
  - template: "sim/testbench/interface.sv.jinja2"
    output: "10.sim/02.tb/{{ block_name }}_if.sv"
    generator: "TestbenchGenerator"

  - template: "sim/testbench/tb_program.sv.jinja2"
    output: "10.sim/02.tb/tb_program.sv"
    generator: "TestbenchGenerator"

  - template: "sim/testbench/tb.sv.jinja2"
    output: "10.sim/02.tb/tb.sv"
    generator: "TestbenchGenerator"

  # ============================================================================
  # Simulation - Models
  # ============================================================================
  - template: "sim/testbench/model.sv.jinja2"
    output: "10.sim/04.simModels/{{ block_name }}_model.sv"
    generator: "TestbenchGenerator"

  # ============================================================================
  # UVM Components
  # ============================================================================
  - template: "uvmComponent/pkg.sv.jinja2"
    output: "10.sim/03.uvmComponent/{{ block_name }}_pkg.sv"
    generator: "UVMGenerator"

  - template: "uvmComponent/driver.svh.jinja2"
    output: "10.sim/03.uvmComponent/driver/{{ block_name }}_driver.svh"
    generator: "UVMGenerator"

  - template: "uvmComponent/monitor.svh.jinja2"
    output: "10.sim/03.uvmComponent/monitor/{{ block_name }}_monitor.svh"
    generator: "UVMGenerator"

  - template: "uvmComponent/agent.svh.jinja2"
    output: "10.sim/03.uvmComponent/agent/{{ block_name }}_agent.svh"
    generator: "UVMGenerator"

  - template: "uvmComponent/scoreboard.svh.jinja2"
    output: "10.sim/03.uvmComponent/scoreboard/{{ block_name }}_scoreboard.svh"
    generator: "UVMGenerator"

  - template: "uvmComponent/sequencer.svh.jinja2"
    output: "10.sim/03.uvmComponent/sequencer/{{ block_name }}_sequencer.svh"
    generator: "UVMGenerator"

  - template: "uvmComponent/sequence.svh.jinja2"
    output: "10.sim/03.uvmComponent/sequence/{{ block_name }}_example_seq.svh"
    generator: "UVMGenerator"

  - template: "uvmComponent/ral.svh.jinja2"
    output: "10.sim/03.uvmComponent/ral/{{ block_name }}_ral.svh"
    generator: "UVMGenerator"

  - template: "uvmComponent/env.svh.jinja2"
    output: "10.sim/03.uvmComponent/env/{{ block_name }}_env.svh"
    generator: "UVMGenerator"

  - template: "uvmComponent/test.svh.jinja2"
    output: "10.sim/03.uvmComponent/test/{{ block_name }}_base_test.svh"
    generator: "UVMGenerator"

  # ============================================================================
  # README
  # ============================================================================
  - template: "readme/README.md.jinja2"
    output: "README.md"
    generator: "ReadmeGenerator"
```

---

## 🛠️ Utils Module Design

### Verbose Utility (Simplified, No Decorators)

```python
# src/utils/verbose.py
#!/usr/bin/env python3
#----------------------------------------------------------------------
# Verbose utility - Simplified version without decorators
# Based on original verbose.py by seongbeom
#----------------------------------------------------------------------

import argparse
import builtins
import inspect
import os
from typing import Union, Any
from enum import IntEnum


# =============================================================================
# Verbose Level
# =============================================================================

class VerboseLevel(IntEnum):
    """Verbose level enumeration"""
    NONE = 0
    ERROR = 1  
    WARNING = 2
    INFO = 3
    DEBUG = 4
    TRACE = 5

_VERBOSE_LEVEL = VerboseLevel.INFO

VERBOSE_LEVELS = {
    0: "NONE",
    1: "ERROR",
    2: "WARNING",
    3: "INFO",
    4: "DEBUG",
    5: "TRACE"
}

VERBOSE_LEVELS_INV = {v: k for k, v in VERBOSE_LEVELS.items()}


# =============================================================================
# Getters / Setters
# =============================================================================

def get_verbose_level() -> int:
    """Get the current verbose level."""
    return _VERBOSE_LEVEL.value


def set_verbose_level(level: Union[int, str]) -> None:
    """Set the global verbose level."""
    global _VERBOSE_LEVEL
    if isinstance(level, str):
        try:
            _VERBOSE_LEVEL = getattr(VerboseLevel, level.upper())
        except AttributeError:
            raise ValueError(f"Invalid verbose level: {level}. Must be one of {[e.name for e in VerboseLevel]}.")
    else:
        try:
            _VERBOSE_LEVEL = VerboseLevel(level)
        except ValueError:
            raise ValueError(f"Invalid verbose level: {level}. Must be one of {list(VERBOSE_LEVELS.keys())}.")


# =============================================================================
# Argument Parser Integration
# =============================================================================

def add_verbose_arguments(parser: argparse.ArgumentParser) -> None:
    """Add verbose level argument to the argument parser."""
    parser.add_argument(
        '--verbose', '-v',
        type=int,
        choices=list(VERBOSE_LEVELS.keys()),
        default=3,  # Default to INFO level
        help='Set the verbosity level: ' +
             ', '.join(f'{k}={v}' for k, v in VERBOSE_LEVELS.items())
    )


def parse_verbose_arguments(args: argparse.Namespace) -> None:
    """Parse the verbose level from command line arguments."""
    if hasattr(args, 'verbose'):
        set_verbose_level(args.verbose)
        original_print(f"[SG-INFO    ] Verbose level set to {args.verbose} ({VERBOSE_LEVELS[args.verbose]})")
    else:
        original_print("[SG-WARNING ] No verbose level specified. Defaulting to INFO level.")
        set_verbose_level(3)


# =============================================================================
# Print Functions
# =============================================================================

# Save original print function
original_print = builtins.print


def print_level(verbose_level: Union[str, int], *args: Any, **kwargs) -> None:
    """Enhanced print with verbose level support."""
    if isinstance(verbose_level, str):
        if verbose_level in VERBOSE_LEVELS.values():
            level_name = verbose_level
            message_level = VERBOSE_LEVELS_INV[verbose_level]
        else:
            level_name = "LOG"
            message_level = 3
    elif isinstance(verbose_level, int):
        level_name = VERBOSE_LEVELS.get(verbose_level)
        if level_name is None:
            original_print("ERROR", f"Invalid verbose level: {verbose_level}")
            exit(1)
        message_level = verbose_level
    
    if message_level > _VERBOSE_LEVEL.value:
        return
    
    prefix = f"[SG-{level_name:<8}]"
    
    if _VERBOSE_LEVEL.value >= VerboseLevel.DEBUG and message_level >= VerboseLevel.DEBUG:
        frame = inspect.currentframe()
        try:
            caller_frame = frame.f_back.f_back
            if caller_frame:
                filename = caller_frame.f_code.co_filename
                function_name = caller_frame.f_code.co_name
                line_number = caller_frame.f_lineno
                try:
                    rel_path = os.path.relpath(filename, os.getcwd())
                except ValueError:
                    rel_path = filename
                call_info = f" [{rel_path}:{function_name}:{line_number}]"
                original_print(prefix, *args, call_info, **kwargs)
            else:
                original_print(prefix, *args, **kwargs)
        finally:
            del frame
    else:
        original_print(prefix, *args, **kwargs)


def verbose_print(level: Union[str, int], *msg: object) -> None:
    """Print a message at the specified verbose level (backward compatibility)."""
    print_level(level, *msg)


# =============================================================================
# Simple Interface Functions
# =============================================================================

def error(*args, **kwargs):
    """Print error message"""
    print_level("ERROR", *args, **kwargs)

def warning(*args, **kwargs):
    """Print warning message"""
    print_level("WARNING", *args, **kwargs)

def info(*args, **kwargs):
    """Print info message"""
    print_level("INFO", *args, **kwargs)

def debug(*args, **kwargs):
    """Print debug message"""
    print_level("DEBUG", *args, **kwargs)

def trace(*args, **kwargs):
    """Print trace message"""
    print_level("TRACE", *args, **kwargs)
```

### Config Loader

```python
# src/utils/config_loader.py
import os
import yaml
import datetime
from typing import Dict, Any, List
from .verbose import info, warning, error


def load_template_config(yaml_path: str, cli_args: Dict[str, Any]) -> Dict[str, Any]:
    """Load template.yaml and override with CLI arguments"""
    with open(yaml_path, 'r', encoding='utf-8') as f:
        config = yaml.safe_load(f)
    
    code_vars = config.get('code', {})
    user_vars = config.get('user', {})
    
    auto_values = {
        'author': os.environ.get('USER', os.environ.get('USERNAME', 'unknown')),
        'date': datetime.datetime.now().strftime('%Y-%m-%d'),
    }
    
    for key, value in auto_values.items():
        if key in code_vars:
            old_value = code_vars[key]
            if old_value != value and old_value != "":
                info(f"Override (auto): {key} = '{old_value}' -> '{value}'")
            code_vars[key] = value
    
    cli_mapping = {
        'block_name': 'componentName',
        'output_path': 'output_path',
        'ip_bundle_paths': 'ip_bundle_path',
        'vlog_link_targets': 'vlog_link_target',
    }
    
    for config_key, cli_key in cli_mapping.items():
        if cli_key in cli_args and cli_args[cli_key]:
            cli_value = cli_args[cli_key]
            if config_key in code_vars:
                old_value = code_vars[config_key]
                if old_value != cli_value and old_value not in ("", []):
                    info(f"Override (CLI): {config_key} = '{old_value}' -> '{cli_value}'")
                code_vars[config_key] = cli_value
    
    result = {}
    result.update(code_vars)
    result.update(user_vars)
    
    return result


def load_folders_config(yaml_path: str) -> List[Dict[str, Any]]:
    """Load folders.yaml"""
    with open(yaml_path, 'r', encoding='utf-8') as f:
        config = yaml.safe_load(f)
    return config.get('folders', [])


def load_files_config(yaml_path: str) -> List[Dict[str, Any]]:
    """Load files.yaml"""
    with open(yaml_path, 'r', encoding='utf-8') as f:
        config = yaml.safe_load(f)
    return config.get('files', [])
```

### Argument Parser

```python
# src/utils/argument.py
import argparse
import os
from .verbose import add_verbose_arguments


def parse_arguments():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(
        description='Create Block Environment - DUT Design Environment Generator'
    )

    parser.add_argument('componentName', type=str, help='Block/Component name (required)')
    parser.add_argument('-o', '--output_path', type=str, default=os.path.join(os.getcwd(), "build"), help='Output path (default: ./build)')
    parser.add_argument('-ip', '--ip_bundle_path', type=str, nargs='+', default=[], help="List of IP Bundle paths to copy")
    parser.add_argument('-t', '--vlog_link_target', type=str, nargs='+', default=[], help='List of folder names to create symbolic links in 01.rtl/verilog')
    parser.add_argument('-i', '--ipxact_files', type=str, nargs='+', default=[], help="List of IP-XACT file paths to copy")
    parser.add_argument('-s', '--sdc_files', type=str, nargs='+', default=[], help="List of SDC file paths to copy")
    parser.add_argument('-u', '--upf_files', type=str, nargs='+', default=[], help="List of UPF file paths to copy")
    parser.add_argument('-f', '--force', action='store_true', help='Force overwrite existing files/folders')
    
    add_verbose_arguments(parser)

    return parser.parse_args()
```

### File Operations

```python
# src/utils/file_ops.py
import os
import shutil
from pathlib import Path
from typing import List
from .verbose import info, warning, error


def create_folder(path: str, force: bool) -> bool:
    """Create a single folder"""
    if os.path.exists(path):
        if force:
            try:
                if os.path.isdir(path):
                    shutil.rmtree(path)
                else:
                    os.remove(path)
                os.makedirs(path)
                info(f"[Force] Recreated Folder: {path}")
                return True
            except Exception as e:
                error(f"Failed to recreate folder {path}: {e}")
                return False
        else:
            warning(f"Folder Already Exists: {path}")
            return False
    else:
        try:
            os.makedirs(path)
            info(f"Created Folder: {path}")
            return True
        except Exception as e:
            error(f"Failed to create folder {path}: {e}")
            return False


def create_folders_from_config(base_path: str, folders_config: List[dict], force: bool) -> bool:
    """Create folders based on config"""
    success = True
    for folder in folders_config:
        folder_path = folder.get('path', '')
        full_path = os.path.join(base_path, folder_path)
        if not create_folder(full_path, force):
            warning(f"Failed to create: {full_path}")
            success = False
    return success


def insert_gitkeep(base_path: str, folders_config: List[dict]) -> bool:
    """Insert .gitkeep in empty folders marked with gitkeep: true"""
    success = True
    for folder in folders_config:
        if not folder.get('gitkeep', False):
            continue
        folder_path = Path(os.path.join(base_path, folder.get('path', '')))
        if not folder_path.is_dir():
            continue
        if any(folder_path.iterdir()):
            continue
        gitkeep_file = folder_path / '.gitkeep'
        try:
            with open(gitkeep_file, 'w') as f:
                f.write("# Keep this folder tracked by git\n")
            info(f"Inserted .gitkeep in: {gitkeep_file}")
        except Exception as e:
            error(f"Failed to insert .gitkeep in {gitkeep_file}: {e}")
            success = False
    return success


def copy_file_safe(src: str, dst_dir: str, force: bool) -> bool:
    """Copy a file or directory to dst_dir, handling force overwrite."""
    if not os.path.exists(src):
        error(f"Source not found: {src}")
        return False
    base_name = os.path.basename(src)
    dst_path = os.path.join(dst_dir, base_name)
    is_file = os.path.isfile(src)
    if os.path.exists(dst_path):
        if force:
            try:
                if os.path.isfile(dst_path) or os.path.islink(dst_path):
                    os.remove(dst_path)
                else:
                    shutil.rmtree(dst_path)
                info(f"[Force] Removed existing: {dst_path}")
            except Exception as e:
                error(f"Failed to remove existing: {dst_path}, Reason: {e}")
                return False
        else:
            warning(f"Already exists: {dst_path} (skipped)")
            return False
    try:
        if is_file:
            shutil.copy(src, dst_path)
            info(f"Copied file: {src} -> {dst_path}")
        else:
            shutil.copytree(src, dst_path)
            info(f"Copied directory: {src} -> {dst_path}")
        return True
    except Exception as e:
        error(f"Failed to copy {src} -> {dst_path}, Reason: {e}")
        return False


def create_symbolic_links(search_paths: List[str], dest_dir: str, link_target: str) -> None:
    """Create symbolic links for the specified target directory."""
    os.makedirs(dest_dir, exist_ok=True)
    for root_base in search_paths:
        if not os.path.isdir(root_base):
            warning(f"Search path is not a directory: {root_base}")
            continue
        for root, dirs, _ in os.walk(root_base):
            if link_target in dirs:
                src_path = os.path.join(root, link_target)
                link_path = os.path.join(dest_dir, link_target)
                try:
                    if os.path.islink(link_path) or os.path.exists(link_path):
                        if os.path.isdir(link_path) and not os.path.islink(link_path):
                            shutil.rmtree(link_path)
                        else:
                            os.remove(link_path)
                        info(f"Removed existing link or directory: {link_path}")
                    rel_src = os.path.relpath(src_path, start=os.path.dirname(link_path))
                    os.symlink(rel_src, link_path)
                    info(f"Created relative symlink: {link_path} -> {rel_src}")
                except Exception as e:
                    error(f"Failed to create symlink for {src_path}: {e}")
                break
        else:
            warning(f"No matching '{link_target}' directory found under {root_base}")


def scan_verilog_files(search_paths: List[str]) -> tuple:
    """
    Scan directories for Verilog/SystemVerilog files.
    Returns (file_list, incdir_list)
    """
    vlog_extensions = ('.v', '.sv', '.vh', '.svh')
    files = []
    incdirs = set()
    
    for search_path in search_paths:
        if not os.path.exists(search_path):
            continue
        for root, dirs, filenames in os.walk(search_path, followlinks=True):
            for filename in filenames:
                if filename.endswith(vlog_extensions):
                    file_path = os.path.join(root, filename)
                    files.append(file_path)
                    incdirs.add(root)
    
    return sorted(files), sorted(incdirs)
```

### Utils __init__.py

```python
# src/utils/__init__.py
from .verbose import (
    info, warning, error, debug, trace,
    verbose_print, print_level, original_print,
    get_verbose_level, set_verbose_level,
    add_verbose_arguments, parse_verbose_arguments,
    VerboseLevel, VERBOSE_LEVELS, VERBOSE_LEVELS_INV,
)
from .argument import parse_arguments
from .config_loader import load_template_config, load_folders_config, load_files_config
from .file_ops import (
    create_folder, create_folders_from_config, insert_gitkeep,
    copy_file_safe, create_symbolic_links, scan_verilog_files,
)

__all__ = [
    'info', 'warning', 'error', 'debug', 'trace',
    'verbose_print', 'print_level', 'original_print',
    'get_verbose_level', 'set_verbose_level',
    'add_verbose_arguments', 'parse_verbose_arguments',
    'VerboseLevel', 'VERBOSE_LEVELS', 'VERBOSE_LEVELS_INV',
    'parse_arguments',
    'load_template_config', 'load_folders_config', 'load_files_config',
    'create_folder', 'create_folders_from_config', 'insert_gitkeep',
    'copy_file_safe', 'create_symbolic_links', 'scan_verilog_files',
]
```

---

## 🎭 Polymorphism-based Generator Design

### Base Generator Class

```python
# src/generators/base.py
from abc import ABC
from typing import Dict, Any
import os
import jinja2
from utils.verbose import info, error


class BaseGenerator(ABC):
    """Base class for all generators"""
    
    def __init__(self, context: Dict[str, Any], template_root: str, output_root: str):
        self.context = context
        self.template_root = template_root
        self.output_root = output_root
        self.env = jinja2.Environment(
            loader=jinja2.FileSystemLoader(template_root),
            trim_blocks=True,
            lstrip_blocks=True
        )
    
    def generate(self, template_path: str, output_path: str) -> bool:
        """Render template and generate file"""
        try:
            template = self.env.get_template(template_path)
            resolved_output = self._resolve_path(output_path)
            full_output_path = os.path.join(self.output_root, resolved_output)
            os.makedirs(os.path.dirname(full_output_path), exist_ok=True)
            rendered = template.render(**self.context)
            with open(full_output_path, 'w') as f:
                f.write(rendered)
            info(f"Generated: {full_output_path}")
            return True
        except Exception as e:
            error(f"Failed to generate {output_path}: {e}")
            return False
    
    def _resolve_path(self, path: str) -> str:
        """Resolve Jinja2 variables in path"""
        template = jinja2.Template(path)
        return template.render(**self.context)
```

### Concrete Generator Classes

```python
# src/generators/makefile.py
from .base import BaseGenerator

class MakefileGenerator(BaseGenerator):
    """Makefile generator"""
    pass


# src/generators/hook.py
from .base import BaseGenerator

class HookGenerator(BaseGenerator):
    """Hook TCL script generator"""
    pass


# src/generators/filelist.py
from .base import BaseGenerator

class FilelistGenerator(BaseGenerator):
    """Filelist generator - scans directories and fills template"""
    pass


# src/generators/testbench.py
from .base import BaseGenerator

class TestbenchGenerator(BaseGenerator):
    """Testbench generator"""
    pass


# src/generators/uvm.py
from .base import BaseGenerator

class UVMGenerator(BaseGenerator):
    """UVM Component generator"""
    pass


# src/generators/readme.py
from .base import BaseGenerator

class ReadmeGenerator(BaseGenerator):
    """README generator"""
    pass


# src/generators/gitkeep.py
from .base import BaseGenerator

class GitkeepGenerator(BaseGenerator):
    """Gitkeep inserter for empty folders"""
    pass
```

---

## 📝 Template Examples

### Filelist Templates

#### package_rtl.f (Auto-filled with scanned files)

```jinja2
{# template/filelist/package_rtl.f.jinja2 #}
//==============================================================================
// {{ block_name }} RTL Filelist
// Author: {{ author }}
// Date: {{ date }}
//==============================================================================

//------------------------------------------------------------------------------
// Include Directories
//------------------------------------------------------------------------------
{% for incdir in rtl_incdirs %}
+incdir+{{ incdir }}
{% endfor %}

//------------------------------------------------------------------------------
// Source Files
//------------------------------------------------------------------------------
{% for file in rtl_files %}
{{ file }}
{% endfor %}
```

#### package_models.f (Intentional error - user must modify)

```jinja2
{# template/filelist/package_models.f.jinja2 #}
//==============================================================================
// {{ block_name }} Models Filelist
// Author: {{ author }}
// Date: {{ date }}
//
// [ACTION REQUIRED] This file must be modified by the user!
//
// Include your memory models and standard cell libraries here:
//   - Memory models (SRAM, ROM, etc.)
//   - Standard cell simulation models
//   - Other behavioral models
//
// Example:
//   /path/to/memory/sram_model.v
//   /path/to/stdcell/typical.v
//
//==============================================================================

/ERROR/USER_ACTION_REQUIRED/ADD_MEMORY_MODELS_AND_STANDARD_CELL_LIBRARIES
```

#### package_tb.f (Template - user modifies later)

```jinja2
{# template/filelist/package_tb.f.jinja2 #}
//==============================================================================
// {{ block_name }} Testbench Filelist
// Author: {{ author }}
// Date: {{ date }}
//==============================================================================

// TODO: User modifies this file

//------------------------------------------------------------------------------
// Include Directories
//------------------------------------------------------------------------------
+incdir+../02.tb
+incdir+../03.uvmComponent

//------------------------------------------------------------------------------
// Source Files
//------------------------------------------------------------------------------
// UVM Package
../03.uvmComponent/{{ block_name }}_pkg.sv

// Testbench
../02.tb/{{ block_name }}_if.sv
../02.tb/tb_program.sv
../02.tb/tb.sv

// Models
../04.simModels/{{ block_name }}_model.sv
```

#### package_svt.f (TBD - controlled by -svt argument)

```jinja2
{# template/filelist/package_svt.f.jinja2 #}
//==============================================================================
// {{ block_name }} SVT Filelist
// Author: {{ author }}
// Date: {{ date }}
//
// [TBD] This file will be configured by -svt argument in future versions.
//
//==============================================================================

// TODO: SVT configuration to be added
```

### Testbench Templates

#### Interface

```jinja2
{# template/sim/testbench/interface.sv.jinja2 #}
//----------------------------------------------------------------------
// {{ block_name }}_if - Interface
// Author: {{ author }}
// Date: {{ date }}
//----------------------------------------------------------------------

interface {{ block_name }}_if(input logic clk, input logic rst_n);
    
    // TODO: Add interface signals
    
    // Clocking blocks
    clocking drv_cb @(posedge clk);
        // TODO: Add driver clocking block signals
    endclocking
    
    clocking mon_cb @(posedge clk);
        // TODO: Add monitor clocking block signals
    endclocking
    
    // Modports
    modport DRV(clocking drv_cb, input rst_n);
    modport MON(clocking mon_cb, input rst_n);
    modport DUT(/* TODO: Add DUT modport */);

endinterface
```

#### tb_program.sv

```jinja2
{# template/sim/testbench/tb_program.sv.jinja2 #}
//----------------------------------------------------------------------
// tb_program - Test Program
// Author: {{ author }}
// Date: {{ date }}
//----------------------------------------------------------------------

program tb_program({{ block_name }}_if vif);
    
    import uvm_pkg::*;
    import {{ block_name }}_pkg::*;
    
    initial begin
        // Set interface to config_db
        uvm_config_db#(virtual {{ block_name }}_if)::set(null, "*", "vif", vif);
        
        // Run test
        run_test();
    end

endprogram
```

#### tb.sv (Top-level Testbench)

```jinja2
{# template/sim/testbench/tb.sv.jinja2 #}
//----------------------------------------------------------------------
// tb - Top-level Testbench
// Author: {{ author }}
// Date: {{ date }}
//----------------------------------------------------------------------

module tb;
    
    // Clock and Reset
    logic clk;
    logic rst_n;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100MHz
    end
    
    // Reset generation
    initial begin
        rst_n = 0;
        #100;
        rst_n = 1;
    end
    
    // Interface
    {{ block_name }}_if vif(clk, rst_n);
    
    // DUT instance
    {{ block_name }}_wrapper u_dut (
        .clk    (clk),
        .rst_n  (rst_n)
        // TODO: Connect DUT ports
    );
    
    // Test program
    tb_program u_program(vif);
    
    // Dump waveform
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb);
    end

endmodule
```

### RTL Wrapper Template

```jinja2
{# template/rtl/wrapper.sv.jinja2 #}
//----------------------------------------------------------------------
// {{ block_name }}_wrapper - RTL Wrapper
// Author: {{ author }}
// Date: {{ date }}
//----------------------------------------------------------------------

module {{ block_name }}_wrapper (
    input  logic clk,
    input  logic rst_n
    // TODO: Add ports
);

    // TODO: Instantiate RTL modules

endmodule
```

### UVM Package Template

```jinja2
{# template/uvmComponent/pkg.sv.jinja2 #}
//----------------------------------------------------------------------
// {{ block_name }}_pkg - UVM Package
// Author: {{ author }}
// Date: {{ date }}
//----------------------------------------------------------------------

package {{ block_name }}_pkg;
    
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    
    // Include UVM components
    `include "driver/{{ block_name }}_driver.svh"
    `include "monitor/{{ block_name }}_monitor.svh"
    `include "sequencer/{{ block_name }}_sequencer.svh"
    `include "agent/{{ block_name }}_agent.svh"
    `include "scoreboard/{{ block_name }}_scoreboard.svh"
    `include "ral/{{ block_name }}_ral.svh"
    `include "env/{{ block_name }}_env.svh"
    `include "sequence/{{ block_name }}_example_seq.svh"
    `include "test/{{ block_name }}_base_test.svh"

endpackage
```

---

## 🚀 Execution Flow

```
User Execution
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│ 1. Parse CLI Arguments (utils/argument.py)                  │
│    - componentName, output_path, ip_bundle_path, etc.       │
│    - Parse verbose level from --verbose / -v                │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Load config/template.yaml (utils/config_loader.py)       │
│    - code section: Override with auto values + CLI args     │
│    - user section: Keep as-is                               │
│    - Notify via verbose.info() when overridden              │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Create Folder Structure (utils/file_ops.py)              │
│    - Load config/folders.yaml                               │
│    - Create each folder                                     │
│    - Insert .gitkeep in folders with gitkeep: true          │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. Copy Files (utils/file_ops.py)                           │
│    - SDC files -> 00.constraint/sdc/origin/                 │
│    - UPF files -> 00.constraint/upf/origin/                 │
│    - IP-XACT files -> 01.rtl/ipxact/                        │
│    - IP Bundle -> 01.rtl/ip_bundle/                         │
│    - Symbolic Links -> 01.rtl/verilog/                      │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. Scan Verilog Files (for package_rtl.f)                   │
│    - Scan ip_bundle/*, wrapper/* for *.v, *.sv files        │
│    - Generate rtl_files and rtl_incdirs lists               │
│    - Add to context for template rendering                  │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. Generate Files (generators/*.py)                         │
│    - Load config/files.yaml                                 │
│    - For each file:                                         │
│      1. Instantiate Generator class                         │
│      2. Render template -> output                           │
│      3. Pass context (from template.yaml + scanned files)   │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│ 7. Complete                                                 │
│    - Output tree if verbose level >= DEBUG                  │
└─────────────────────────────────────────────────────────────┘
```

### Usage Examples

```bash
# Basic usage
python main.py my_block -o ./output

# Full options
python main.py my_block \
    -o ./output \
    -ip /path/to/ip_bundle1 /path/to/ip_bundle2 \
    -t rtl_src \
    -s /path/to/constraint.sdc \
    -u /path/to/power.upf \
    -i /path/to/ip.xml \
    -f \
    -v 3
```

---

## 📌 Implementation Priority

### Phase 1: Foundation
- [ ] Create project directory structure
- [ ] Create `config/template.yaml`
- [ ] Create `config/folders.yaml`
- [ ] Create `config/files.yaml`

### Phase 2: Utils
- [ ] `src/utils/__init__.py`
- [ ] `src/utils/verbose.py`
- [ ] `src/utils/argument.py`
- [ ] `src/utils/config_loader.py`
- [ ] `src/utils/file_ops.py`

### Phase 3: Generators
- [ ] `src/generators/__init__.py`
- [ ] `src/generators/base.py`
- [ ] `src/generators/makefile.py`
- [ ] `src/generators/hook.py`
- [ ] `src/generators/filelist.py`
- [ ] `src/generators/testbench.py`
- [ ] `src/generators/uvm.py`
- [ ] `src/generators/readme.py`
- [ ] `src/generators/gitkeep.py`

### Phase 4: Templates
- [ ] Filelist templates (package_rtl, package_models, package_tb, package_svt)
- [ ] RTL wrapper template
- [ ] Makefile templates (lint, upfVerify, sdcVerify, synthesis, formal, magillem, sim)
- [ ] Hook templates
- [ ] Testbench templates (interface, tb_program, tb, model)
- [ ] UVM Component templates (pkg, driver, monitor, agent, scoreboard, sequencer, sequence, ral, env, test)
- [ ] README template

### Phase 5: Integration
- [ ] Integrate `src/main.py`
- [ ] Testing

---

## ✅ Confirmed Decisions Summary

| Item | Decision |
|------|----------|
| **UVM Component** | Keep all (driver, monitor, agent, scoreboard, sequencer, sequence, ral, env, test) + pkg.sv |
| **Magillem** | `script/` (folder) + `Makefile` (file) |
| **Makefile Template** | Empty skeleton provided, user modifies later |
| **Hook Script** | `proc pre_<filename> {} { }` format |
| **Config Structure** | `template.yaml` - code (auto) / user (manual) sections, notify on override |
| **Additional Files** | .gitignore, setup.csh, etc. not needed |
| **Language** | English only in code and YAML files |
| **File Naming** | `*_generator.py` -> `*.py` (e.g., `base.py`, `makefile.py`) |
| **Utils Structure** | `src/utils/` folder with `verbose.py`, `argument.py`, `config_loader.py`, `file_ops.py` |
| **Verbose** | Use simplified `verbose.py` (no decorators), integrated with argparse |
| **Filelist** | All template-based: package_rtl (auto-fill), package_models (error), package_tb (user), package_svt (TBD) |
| **Testbench** | Separated: `<block>_if.sv`, `tb_program.sv`, `tb.sv` |
| **Wrapper** | `<block_name>_wrapper.sv` in `01.rtl/verilog/wrapper/` |

---

*Created: 2025-12-04*  
*Version: Final v1.3*
