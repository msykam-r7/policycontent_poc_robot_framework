#!/bin/bash
# Run all benchmark tests with proper sequencing and retry logic

cd /Users/msykam/poc_robot_framework

echo "==========================================="
echo "Starting Benchmark Compliance Test Suite"
echo "==========================================="
echo ""

# Run RHEL 9 Test
echo "1/3: Running RHEL 9 CIS Benchmark Test..."
robot tests/CIS/Linux/RHEL/RHEL9benchmarks.robot
RHEL_EXIT=$?
echo "RHEL 9 Exit Code: $RHEL_EXIT"
echo ""
sleep 5

# Run Oracle 19c Test
echo "2/3: Running Oracle 19c CIS Benchmark Test..."
robot tests/CIS/Oracle/oracle19cbenchmark.robot
ORACLE_EXIT=$?
echo "Oracle 19c Exit Code: $ORACLE_EXIT"
echo ""
sleep 5

# Run Windows 10 Test
echo "3/3: Running Windows 10 DISA STIG Test..."
robot tests/DISA/windows10benchmark.robot
WINDOWS_EXIT=$?
echo "Windows 10 Exit Code: $WINDOWS_EXIT"
echo ""

echo "==========================================="
echo "Test Suite Completion Summary"
echo "==========================================="
echo "RHEL 9:     Exit Code $RHEL_EXIT"
echo "Oracle 19c: Exit Code $ORACLE_EXIT"
echo "Windows 10: Exit Code $WINDOWS_EXIT"
echo ""

if [ $RHEL_EXIT -eq 0 ] && [ $ORACLE_EXIT -eq 0 ] && [ $WINDOWS_EXIT -eq 0 ]; then
    echo "✓ ALL TESTS PASSED"
    exit 0
else
    echo "✗ SOME TESTS FAILED"
    exit 1
fi
