#!/usr/bin/env python3
"""
Test suite for Markdown documentation files.
Validates structure, formatting, and consistency.
"""

import os
import re
import sys
from pathlib import Path


class MarkdownValidator:
    def __init__(self, md_path):
        self.path = Path(md_path)
        with open(self.path, 'r') as f:
            self.content = f.read()
            self.lines = self.content.split('\n')

    def validate_structure(self):
        """Test basic markdown structure"""
        tests_passed = []
        tests_failed = []
        
        print(f"\n[{self.path.name}] Structure Tests")
        
        # Check for headers
        has_headers = any(line.startswith('#') for line in self.lines)
        if has_headers:
            tests_passed.append("✓ Contains markdown headers")
            print("  ✓ Contains markdown headers")
        else:
            tests_failed.append("✗ Contains markdown headers")
            print("  ✗ Contains markdown headers")
        
        # Check for code blocks
        code_block_count = self.content.count('```')
        if code_block_count % 2 == 0:
            tests_passed.append(f"✓ Code blocks are balanced ({code_block_count // 2} blocks)")
            print(f"  ✓ Code blocks are balanced ({code_block_count // 2} blocks)")
        else:
            tests_failed.append("✗ Code blocks are not balanced")
            print("  ✗ Code blocks are not balanced")
        
        # Check for trailing whitespace
        lines_with_trailing = [i+1 for i, line in enumerate(self.lines) if line.endswith(' ') or line.endswith('\t')]
        if not lines_with_trailing:
            tests_passed.append("✓ No trailing whitespace")
            print("  ✓ No trailing whitespace")
        else:
            tests_failed.append(f"✗ Trailing whitespace on lines: {lines_with_trailing[:5]}")
            print(f"  ✗ Trailing whitespace on lines: {lines_with_trailing[:5]}")
        
        # Check for multiple blank lines
        multiple_blanks = []
        for i in range(len(self.lines) - 2):
            if not self.lines[i] and not self.lines[i+1] and not self.lines[i+2]:
                multiple_blanks.append(i+1)
        
        if not multiple_blanks:
            tests_passed.append("✓ No multiple consecutive blank lines")
            print("  ✓ No multiple consecutive blank lines")
        else:
            tests_failed.append(f"✗ Multiple blank lines at: {multiple_blanks[:3]}")
            print(f"  ✗ Multiple blank lines at: {multiple_blanks[:3]}")
        
        return len(tests_passed), len(tests_failed)

    def validate_links(self):
        """Test links in markdown"""
        tests_passed = []
        tests_failed = []
        
        print(f"\n[{self.path.name}] Link Validation Tests")
        
        # Find all markdown links [text](url)
        link_pattern = r'\[([^\]]+)\]\(([^\)]+)\)'
        links = re.findall(link_pattern, self.content)
        
        if links:
            print(f"  Found {len(links)} links")
            
            # Check for empty link text
            empty_text = [url for text, url in links if not text.strip()]
            if not empty_text:
                tests_passed.append("✓ No links with empty text")
                print("  ✓ No links with empty text")
            else:
                tests_failed.append(f"✗ {len(empty_text)} links with empty text")
                print(f"  ✗ {len(empty_text)} links with empty text")
            
            # Check for malformed URLs
            for _text, url in links:
                if url.startswith('http'):
                    if ' ' in url:
                        tests_failed.append(f"✗ Malformed URL with spaces: {url[:50]}")
                        print(f"  ✗ Malformed URL with spaces: {url[:50]}")
                        break
            else:
                tests_passed.append("✓ No malformed HTTP URLs")
                print("  ✓ No malformed HTTP URLs")
        else:
            tests_passed.append("✓ No links to validate")
            print("  ✓ No links to validate")
        
        return len(tests_passed), len(tests_failed)

    def validate_consistency(self):
        """Test formatting consistency"""
        tests_passed = []
        tests_failed = []
        
        print(f"\n[{self.path.name}] Consistency Tests")
        
        # Check header hierarchy (no skipping levels)
        headers = [(i+1, line) for i, line in enumerate(self.lines) if line.startswith('#')]
        if headers:
            header_levels = [len(line.split()[0]) for _, line in headers]
            
            # Check if headers skip levels
            skips_levels = False
            for i in range(1, len(header_levels)):
                if header_levels[i] - header_levels[i-1] > 1:
                    skips_levels = True
                    break
            
            if not skips_levels:
                tests_passed.append("✓ Header levels don't skip")
                print("  ✓ Header levels don't skip")
            else:
                tests_failed.append("✗ Header levels skip (e.g., # to ###)")
                print("  ✗ Header levels skip (e.g., # to ###)")
        
        # Check for consistent code block language tags
        code_blocks = re.findall(r'```(\w*)', self.content)
        if code_blocks:
            tagged_blocks = [lang for lang in code_blocks if lang]
            if len(tagged_blocks) == len(code_blocks):
                tests_passed.append("✓ All code blocks have language tags")
                print("  ✓ All code blocks have language tags")
            elif len(tagged_blocks) == 0:
                tests_passed.append("✓ Code blocks consistently untagged")
                print("  ✓ Code blocks consistently untagged")
            else:
                tests_failed.append(f"✗ Inconsistent code block tagging ({len(tagged_blocks)}/{len(code_blocks)})")
                print(f"  ✗ Inconsistent code block tagging ({len(tagged_blocks)}/{len(code_blocks)})")
        
        # Check list formatting consistency
        unordered_lists = len([line for line in self.lines if re.match(r'^\s*[-*+]\s', line)])
        ordered_lists = len([line for line in self.lines if re.match(r'^\s*\d+\.\s', line)])
        
        if unordered_lists > 0 or ordered_lists > 0:
            tests_passed.append(f"✓ Found {unordered_lists} unordered + {ordered_lists} ordered list items")
            print(f"  ✓ Found {unordered_lists} unordered + {ordered_lists} ordered list items")
        
        return len(tests_passed), len(tests_failed)


def test_runner_setup_md():
    """Test RUNNER-SETUP.md specifically"""
    validator = MarkdownValidator('/home/jailuser/git/RUNNER-SETUP.md')
    
    print("\n" + "="*60)
    print("RUNNER-SETUP.md Validation Tests")
    print("="*60)
    
    passed1, failed1 = validator.validate_structure()
    passed2, failed2 = validator.validate_links()
    passed3, failed3 = validator.validate_consistency()
    
    # Specific tests for RUNNER-SETUP.md
    print("\n[RUNNER-SETUP.md] Content-Specific Tests")
    
    passed4 = 0
    failed4 = 0
    
    # Check that the file doesn't have the Author line (was removed in diff)
    if 'Author:' not in validator.content:
        print("  ✓ Author line properly removed")
        passed4 += 1
    else:
        print("  ✗ Author line still present")
        failed4 += 1
    
    # Check for Last Updated
    if 'Last Updated:' in validator.content:
        print("  ✓ Contains Last Updated field")
        passed4 += 1
    else:
        print("  ✗ Missing Last Updated field")
        failed4 += 1
    
    # Check for Hardware field
    if 'Hardware:' in validator.content:
        print("  ✓ Contains Hardware field")
        passed4 += 1
    else:
        print("  ✗ Missing Hardware field")
        failed4 += 1
    
    # Check for Repository link
    if 'Repository:' in validator.content and 'github.com' in validator.content:
        print("  ✓ Contains Repository link")
        passed4 += 1
    else:
        print("  ✗ Missing Repository link")
        failed4 += 1
    
    # Check no trailing spaces in metadata lines
    metadata_lines = [line for line in validator.lines if line.startswith('**') and ':**' in line]
    trailing_in_metadata = [line for line in metadata_lines if line.endswith(' ')]
    
    if not trailing_in_metadata:
        print("  ✓ No trailing spaces in metadata lines")
        passed4 += 1
    else:
        print(f"  ✗ Trailing spaces in {len(trailing_in_metadata)} metadata lines")
        failed4 += 1
    
    # Report
    total_passed = passed1 + passed2 + passed3 + passed4
    total_failed = failed1 + failed2 + failed3 + failed4
    
    print("\n" + "="*60)
    print(f"Total tests: {total_passed + total_failed}")
    print(f"Passed: {total_passed}")
    print(f"Failed: {total_failed}")
    print("="*60)
    
    return total_failed == 0


def main():
    os.chdir('/home/jailuser/git')
    
    success = test_runner_setup_md()
    
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()