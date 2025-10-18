#!/usr/bin/env python3
"""
Comprehensive test suite for GitHub Actions workflow YAML files.
Tests the workflows modified in the current branch for correctness,
best practices, and proper structure.
"""

import os
import re
import sys
import yaml
from pathlib import Path

# Simple test framework (no external dependencies)
class TestRunner:
    def __init__(self):
        self.tests_run = 0
        self.tests_passed = 0
        self.tests_failed = 0
        self.failures = []

    def assert_true(self, condition, message):
        self.tests_run += 1
        if condition:
            self.tests_passed += 1
            print(f"  ✓ {message}")
        else:
            self.tests_failed += 1
            self.failures.append(message)
            print(f"  ✗ {message}")

    def assert_equal(self, actual, expected, message):
        self.assert_true(actual == expected, f"{message} (expected: {expected}, got: {actual})")

    def assert_in(self, item, container, message):
        self.assert_true(item in container, message)

    def assert_not_in(self, item, container, message):
        self.assert_true(item not in container, message)

    def report(self):
        print("\n" + "="*60)
        print(f"Tests run: {self.tests_run}")
        print(f"Passed: {self.tests_passed}")
        print(f"Failed: {self.tests_failed}")
        if self.failures:
            print("\nFailures:")
            for failure in self.failures:
                print(f"  - {failure}")
        print("="*60)
        return self.tests_failed == 0


class WorkflowValidator:
    def __init__(self, workflow_path):
        self.path = Path(workflow_path)
        with open(self.path, 'r') as f:
            self.content = f.read()
            try:
                self.yaml_data = yaml.safe_load(self.content)
            except yaml.YAMLError as e:
                print(f"ERROR: Failed to parse {workflow_path}: {e}")
                self.yaml_data = None

    def validate_basic_structure(self, runner):
        """Test basic workflow structure"""
        print(f"\n[{self.path.name}] Basic Structure Tests")
        
        runner.assert_true(
            self.yaml_data is not None,
            f"{self.path.name} is valid YAML"
        )
        
        if self.yaml_data:
            runner.assert_in('name', self.yaml_data, "Has 'name' field")
            runner.assert_in('on', self.yaml_data, "Has 'on' (triggers) field")
            runner.assert_in('jobs', self.yaml_data, "Has 'jobs' field")
            
            if 'jobs' in self.yaml_data:
                runner.assert_true(
                    len(self.yaml_data['jobs']) > 0,
                    "Has at least one job defined"
                )

    def validate_triggers(self, runner):
        """Test workflow triggers"""
        print(f"\n[{self.path.name}] Trigger Configuration Tests")
        
        if self.yaml_data and 'on' in self.yaml_data:
            triggers = self.yaml_data['on']
            
            # Check for schedule or workflow_dispatch
            has_schedule = 'schedule' in triggers
            has_dispatch = 'workflow_dispatch' in triggers
            
            runner.assert_true(
                has_schedule or has_dispatch,
                "Has either schedule or workflow_dispatch trigger"
            )
            
            if has_schedule:
                runner.assert_true(
                    isinstance(triggers['schedule'], list),
                    "Schedule trigger is a list"
                )
                if isinstance(triggers['schedule'], list) and len(triggers['schedule']) > 0:
                    runner.assert_in(
                        'cron',
                        triggers['schedule'][0],
                        "Schedule has cron expression"
                    )

    def validate_heredoc_usage(self, runner):
        """Test that heredocs are properly used for multi-line content"""
        print(f"\n[{self.path.name}] Heredoc Usage Tests")
        
        # Count heredoc markers
        heredoc_start = len(re.findall(r'cat\s*>\s*\S+\s*<<\s*[\'"]?EOF[\'"]?', self.content))
        heredoc_end = len(re.findall(r'^\s*EOF\s*$', self.content, re.MULTILINE))
        
        runner.assert_equal(
            heredoc_start,
            heredoc_end,
            "Heredoc EOF markers are balanced"
        )
        
        # Check for --notes-file or --body-file usage if using heredoc
        if heredoc_start > 0:
            if 'gh release create' in self.content:
                runner.assert_true(
                    '--notes-file' in self.content,
                    "Uses --notes-file with heredoc"
                )
                runner.assert_true(
                    '--notes "' not in self.content,
                    "Does not use inline --notes with heredoc"
                )
            
            if 'gh issue create' in self.content:
                runner.assert_true(
                    '--body-file' in self.content,
                    "Uses --body-file with heredoc"
                )
                runner.assert_true(
                    '--body "' not in self.content,
                    "Does not use inline --body with heredoc"
                )


def test_docker_weekly_build():
    """Test docker-weekly-build.yml"""
    runner = TestRunner()
    validator = WorkflowValidator('.github/workflows/docker-weekly-build.yml')
    
    validator.validate_basic_structure(runner)
    validator.validate_triggers(runner)
    validator.validate_heredoc_usage(runner)
    
    print("\n[docker-weekly-build.yml] Specific Tests")
    
    # Test for riscv64 runner
    runner.assert_true(
        'riscv64' in validator.content,
        "Uses riscv64 runner"
    )
    
    # Test for release creation
    runner.assert_true(
        'gh release create' in validator.content,
        "Creates GitHub release"
    )
    
    # Test for required release note sections
    if 'Moby Version:' in validator.content:
        runner.assert_true(True, "Release notes include Moby Version")
    else:
        runner.assert_true(False, "Release notes include Moby Version")
    
    runner.assert_true(
        'Build Date:' in validator.content,
        "Release notes include Build Date"
    )
    
    runner.assert_true(
        'Architecture: riscv64' in validator.content,
        "Release notes specify riscv64 architecture"
    )
    
    runner.assert_true(
        'Installation:' in validator.content,
        "Release notes include installation instructions"
    )
    
    runner.assert_true(
        'dockerd' in validator.content and 'docker-proxy' in validator.content,
        "Mentions both dockerd and docker-proxy"
    )
    
    # Check for submodule checkout
    if validator.yaml_data and 'jobs' in validator.yaml_data:
        found_submodules = False
        for _job_name, job_data in validator.yaml_data['jobs'].items():
            if 'steps' in job_data:
                for step in job_data['steps']:
                    if 'uses' in step and 'actions/checkout' in step['uses']:
                        if 'with' in step and 'submodules' in step['with']:
                            found_submodules = True
        runner.assert_true(found_submodules, "Checks out git submodules")
    
    return runner


def test_track_moby_releases():
    """Test track-moby-releases.yml"""
    runner = TestRunner()
    validator = WorkflowValidator('.github/workflows/track-moby-releases.yml')
    
    validator.validate_basic_structure(runner)
    validator.validate_triggers(runner)
    validator.validate_heredoc_usage(runner)
    
    print("\n[track-moby-releases.yml] Specific Tests")
    
    # Test for moby repository reference
    runner.assert_true(
        'moby/moby' in validator.content,
        "References moby/moby repository"
    )
    
    # Test for issue creation
    runner.assert_true(
        'gh issue create' in validator.content,
        "Creates GitHub issue"
    )
    
    # Test for labels
    runner.assert_true(
        'build-request' in validator.content,
        "Uses build-request label"
    )
    
    runner.assert_true(
        'moby-release' in validator.content,
        "Uses moby-release label"
    )
    
    # Test for workflow trigger instructions
    runner.assert_true(
        'gh workflow run' in validator.content,
        "Provides workflow trigger instructions"
    )
    
    # Check for ubuntu-latest runner
    if validator.yaml_data and 'jobs' in validator.yaml_data:
        for job_name, job_data in validator.yaml_data['jobs'].items():
            if 'runs-on' in job_data:
                runner.assert_true(
                    'ubuntu' in str(job_data['runs-on']).lower(),
                    f"Job '{job_name}' uses ubuntu runner"
                )
    
    return runner


def test_track_runner_releases():
    """Test track-runner-releases.yml"""
    runner = TestRunner()
    validator = WorkflowValidator('.github/workflows/track-runner-releases.yml')
    
    validator.validate_basic_structure(runner)
    validator.validate_triggers(runner)
    validator.validate_heredoc_usage(runner)
    
    print("\n[track-runner-releases.yml] Specific Tests")
    
    # Test for runner repository reference
    runner.assert_true(
        'ChristopherHX/github-act-runner' in validator.content,
        "References github-act-runner repository"
    )
    
    # Test for issue creation
    runner.assert_true(
        'gh issue create' in validator.content,
        "Creates GitHub issue"
    )
    
    # Test for labels
    runner.assert_true(
        'maintenance' in validator.content,
        "Uses maintenance label"
    )
    
    runner.assert_true(
        'runner-update' in validator.content,
        "Uses runner-update label"
    )
    
    # Test for update instructions
    runner.assert_true(
        'Update steps:' in validator.content,
        "Provides update steps"
    )
    
    runner.assert_true(
        'systemctl restart' in validator.content,
        "Includes service restart command"
    )
    
    # Test for version display
    runner.assert_true(
        'Current version:' in validator.content,
        "Shows current version"
    )
    
    runner.assert_true(
        'New version:' in validator.content,
        "Shows new version"
    )
    
    return runner


def test_cross_workflow_consistency():
    """Test consistency across all workflows"""
    runner = TestRunner()
    
    print("\n[Cross-Workflow] Consistency Tests")
    
    workflows = [
        '.github/workflows/docker-weekly-build.yml',
        '.github/workflows/track-moby-releases.yml',
        '.github/workflows/track-runner-releases.yml'
    ]
    
    # Check that all workflows use GH_TOKEN when using gh CLI
    for workflow_path in workflows:
        with open(workflow_path, 'r') as f:
            content = f.read()
            if 'gh ' in content and ('gh issue' in content or 'gh release' in content):
                runner.assert_true(
                    'GH_TOKEN:' in content,
                    f"{Path(workflow_path).name} sets GH_TOKEN for gh CLI"
                )
    
    # Check that all heredocs use consistent style
    heredoc_pattern = r'cat\s*>\s*(\S+)\s*<<\s*[\'"]?EOF[\'"]?'
    for workflow_path in workflows:
        with open(workflow_path, 'r') as f:
            content = f.read()
            matches = re.findall(heredoc_pattern, content)
            if matches:
                runner.assert_true(
                    all('.md' in m for m in matches),
                    f"{Path(workflow_path).name} writes heredocs to .md files"
                )
    
    # Check indentation consistency
    for workflow_path in workflows:
        with open(workflow_path, 'r') as f:
            content = f.read()
            # YAML should not have literal tab characters
            runner.assert_true(
                '\t' not in content,
                f"{Path(workflow_path).name} does not contain tab characters"
            )
    
    return runner


def main():
    print("="*60)
    print("GitHub Actions Workflow Validation Test Suite")
    print("="*60)
    
    # Change to repo root
    os.chdir('/home/jailuser/git')
    
    # Run all test suites
    runners = [
        test_docker_weekly_build(),
        test_track_moby_releases(),
        test_track_runner_releases(),
        test_cross_workflow_consistency()
    ]
    
    # Combined report
    print("\n" + "="*60)
    print("COMBINED TEST REPORT")
    print("="*60)
    
    total_run = sum(r.tests_run for r in runners)
    total_passed = sum(r.tests_passed for r in runners)
    total_failed = sum(r.tests_failed for r in runners)
    
    print(f"Total tests run: {total_run}")
    print(f"Total passed: {total_passed}")
    print(f"Total failed: {total_failed}")
    
    all_passed = all(r.report() for r in runners)
    
    sys.exit(0 if all_passed else 1)


if __name__ == '__main__':
    main()