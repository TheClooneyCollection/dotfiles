#!/usr/bin/env python3
"""Compatibility entry point for the renamed manager's test suite."""
from pathlib import Path
import runpy

runpy.run_path(str(Path(__file__).with_name('test-skill-manager.py')), run_name='__main__')
