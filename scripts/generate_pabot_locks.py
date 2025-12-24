#!/usr/bin/env python3
"""
Generate Pabot resource locks based on VM credentials used by test files.
Tests using the same VM credentials will be locked to run sequentially.
"""

import os
import re
import json
from pathlib import Path


def extract_os_identifier(robot_file):
    """Extract os_identifier from a Robot Framework test file."""
    try:
        with open(robot_file, 'r', encoding='utf-8') as f:
            content = f.read()
            # Look for os_identifier parameter in test cases
            match = re.search(r'os_identifier=([^\s\n]+)', content)
            if match:
                return match.group(1)
    except Exception as e:
        print(f"Warning: Could not read {robot_file}: {e}")
    return None


def get_vm_credentials(os_identifier, vm_config_file):
    """Get the actual VM credentials used by this os_identifier."""
    try:
        with open(vm_config_file, 'r', encoding='utf-8') as f:
            config = json.load(f)
        
        # Parse os_identifier (format: BENCHMARK_OS_VERSION)
        parts = os_identifier.split('_')
        if len(parts) < 3:
            return None
        
        benchmark = parts[0]
        os_name = parts[1]
        version = '_'.join(parts[2:])  # Handle multi-part versions
        
        # Navigate through config structure
        if benchmark in config and os_name in config[benchmark]:
            os_config = config[benchmark][os_name]
            
            # Handle both direct and versioned structures
            if version in os_config:
                # Has version layer (e.g., CIS -> NGINX -> default -> ...)
                version_config = os_config[version]
            else:
                # No version layer (direct access)
                version_config = os_config
            
            # Extract credential keys (compliance, server, database, etc.)
            creds = []
            for key in version_config.keys():
                if isinstance(version_config[key], dict) and 'vm_ip' in version_config[key]:
                    vm_ip = version_config[key]['vm_ip']
                    creds.append(f"{os_identifier}_{key}_{vm_ip}")
            
            return creds if creds else [os_identifier]
    
    except Exception as e:
        print(f"Warning: Could not process os_identifier {os_identifier}: {e}")
    
    return [os_identifier]  # Fallback to os_identifier as lock


def find_robot_tests(test_dir):
    """Find all Robot Framework test files."""
    robot_files = []
    for root, dirs, files in os.walk(test_dir):
        for file in files:
            if file.endswith('.robot') and not file.startswith('_'):
                robot_files.append(os.path.join(root, file))
    return robot_files


def generate_pabot_locks(workspace_root):
    """Generate .pabotsuitenames file with resource locks."""
    test_dir = os.path.join(workspace_root, 'tests')
    vm_config = os.path.join(workspace_root, 'testdata', 'vm_config.json')
    output_file = os.path.join(workspace_root, '.pabotsuitenames')
    
    if not os.path.exists(vm_config):
        print(f"Error: VM config not found at {vm_config}")
        return False
    
    # Find all test files
    robot_files = find_robot_tests(test_dir)
    print(f"Found {len(robot_files)} test files")
    
    # Build mapping of test suites to their VM credentials
    suite_locks = {}
    credential_groups = {}  # Group tests by credentials
    
    for robot_file in robot_files:
        os_identifier = extract_os_identifier(robot_file)
        if os_identifier:
            # Get relative path for suite name
            rel_path = os.path.relpath(robot_file, workspace_root)
            suite_name = rel_path.replace('.robot', '').replace('/', '.').replace('tests.', '')
            
            # Get VM credentials used
            creds = get_vm_credentials(os_identifier, vm_config)
            cred_key = tuple(sorted(creds))  # Use as grouping key
            
            suite_locks[suite_name] = {
                'file': rel_path,
                'os_identifier': os_identifier,
                'locks': creds
            }
            
            # Group by credentials
            if cred_key not in credential_groups:
                credential_groups[cred_key] = []
            credential_groups[cred_key].append(suite_name)
            
            print(f"  {suite_name}")
            print(f"    OS: {os_identifier}")
            print(f"    Locks: {', '.join(creds)}")
    
    # Write .pabotsuitenames file with proper format
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("# Pabot Argument File with Resource Locks\n")
        f.write("# Tests using the same VM credentials will run sequentially\n")
        f.write("# Different VMs can run in parallel\n\n")
        
        # Add test directory
        f.write("# Test directory\n")
        f.write("tests\n\n")
        
        f.write("# Resource locks per suite\n")
        for suite_name, info in sorted(suite_locks.items()):
            f.write(f"# {suite_name} uses {info['os_identifier']}\n")
            for lock in info['locks']:
                f.write(f"--lock\n{lock}:{suite_name}\n")
    
    # Print credential conflict warnings
    print(f"\n✅ Generated {output_file}")
    print(f"   {len(suite_locks)} test suites with credential-based locks\n")
    
    print("Credential Groups (tests with same credentials will run sequentially):")
    for cred_key, suites in credential_groups.items():
        if len(suites) > 1:
            print(f"  ⚠️  {', '.join(cred_key)}:")
            for suite in suites:
                print(f"     - {suite}")
    
    print("\nTests using the same VM will now run sequentially!")
    print("Different VMs can still run in parallel.\n")
    
    return True


if __name__ == '__main__':
    # Get workspace root (script is in scripts/ subdirectory)
    script_dir = Path(__file__).parent
    workspace_root = script_dir.parent
    
    print("Generating Pabot resource locks...\n")
    success = generate_pabot_locks(str(workspace_root))
    
    if success:
        print("Usage:")
        print("  pabot --argumentfile .pabotsuitenames --processes 4")
        print("\nThis will automatically prevent parallel execution of tests using the same VM!")
    else:
        exit(1)
