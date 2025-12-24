# Robot Framework Test Suite - Quick Start

## Automatic Setup (Recommended)

The framework automatically installs all required dependencies:

```bash
./setup.sh
```

This will install:
- Robot Framework 7.x
- Pabot (parallel execution)
- RequestsLibrary
- All required Python dependencies

## Running Tests

### Single Test
```bash
robot --outputdir results tests/CIS/Windows/windows_server_2019_standard.robot
```

### Multiple Tests in Parallel
```bash
# Run 4 tests in parallel (on different VMs)
pabot --processes 4 tests/CIS/
```

### Specific Test Suite
```bash
# Run all Windows tests
pabot --processes 2 tests/CIS/Windows/

# Run all Linux tests
pabot --processes 3 tests/CIS/Linux/
```

## ⚠️ Important: Parallel Execution with Credential Protection

✅ **Parallel execution is FULLY SUPPORTED** with automatic VM credential protection!

### Automatic Credential-Based Locking

The framework automatically prevents tests using the **same VM credentials** from running simultaneously while allowing tests on **different VMs** to run in parallel.

### Quick Start - Safe Parallel Execution

```bash
# Step 1: Generate credential locks (one-time or when tests change)
python3 scripts/generate_pabot_locks.py

# Step 2: Run tests in parallel with automatic protection
pabot --argumentfile .pabotsuitenames --processes 4
```

The script detects conflicts:
```
⚠️  CIS_Microsoft_Windows-Server-2019 (WILL RUN SEQUENTIALLY):
   ├─ windows_server_2019_standard.robot
   └─ windows_sever_2019_standalone.robot
```

### Manual Parallel Execution Examples

❌ **DON'T DO THIS (Same VM - will conflict):**
```bash
# Both tests use same Windows 2019 VM - will interfere!
pabot --processes 2 \
  tests/CIS/Windows/windows_server_2019_standard.robot \
  tests/CIS/Windows/windows_sever_2019_standalone.robot
```

✅ **DO THIS (Different VMs - safe to run in parallel):**
```bash
# Each test uses different VM - no conflicts
pabot --processes 4 \
  tests/CIS/Windows/windows_server_2019_standard.robot \
  tests/CIS/Linux/RHEL/RHEL9benchmarks.robot \
  tests/CIS/Linux/Ubuntu/ubuntu_20.04_benchmarks.robot \
  tests/CIS/Oracle/oracle19cbenchmark.robot
```

✅ **BEST: Use automatic locks:**
```bash
pabot --argumentfile .pabotsuitenames --processes 4
```
This handles all conflicts automatically!

## Manual Installation (Alternative)

If you prefer manual installation:

```bash
pip install -r requirements.txt
```

## Verifying Installation

Check that all dependencies are installed:

```bash
python3 -c "import robot, pabot, RequestsLibrary; print('✅ All dependencies installed')"
```

## Project Structure

```
.
├── setup.sh              # Automatic dependency installation
├── requirements.txt      # Python dependencies
├── resources/           # Reusable Robot Framework resources
│   ├── parallel_utils.robot  # Parallel execution utilities
│   └── e2e_benchmark_testing.robot  # Main test framework
├── tests/              # Test files organized by standard
│   ├── CIS/
│   │   ├── Windows/
│   │   ├── Linux/
│   │   └── Oracle/
│   └── DISA/
├── testdata/           # Configuration and test data
│   └── vm_config.json  # VM credentials and connection info
└── results/            # Test execution results
```

## Configuration

Edit `testdata/vm_config.json` to configure VM credentials and connection details for your environment.

## Support

For issues or questions, refer to the test execution logs in the `results/` directory.
