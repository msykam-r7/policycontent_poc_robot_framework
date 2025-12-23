*** Settings ***
Documentation     Windows Server 2019 CIS Benchmark Compliance Testing

Resource          ../../../resources/e2e_benchmark_testing.robot


*** Test Cases ***
Windows 2019-CIS Benchmarks
    [Documentation]    Validates Windows Server 2019 against CIS Level 1 benchmark
    [Tags]    windows    windows2019    cis    benchmark    level1    compliance    e2e
    
    # Generate unique identifiers for this test run
    ${timestamp}=    Evaluate    int(__import__('time').time())
    ${site_name}=    Set Variable    Windows2019_CIS_Level1_${timestamp}
    ${template_name}=    Set Variable    windows2019_cis_template_${timestamp}
    
    # Execute Windows Server 2019 CIS Level 1 compliance test
    ${results}=    Run Complete E2E Benchmark Test
    ...    os_identifier=CIS_Microsoft_Windows-Server-2019
    ...    vm_cred_types=compliance,server
    ...    os_benchmark_identifier=Microsoft_Windows_Server_2019_Stand-alone
    ...    version=3.0.0
    ...    scan_template=cis
    ...    server_service=ssh
    ...    scope=S
    ...    site_name=${site_name}
    ...    template_name=${template_name}
    ...    policy_list=all
    ...    csv_file=${EXECDIR}/testdata/validation_rules/CIS/Ubuntu/ubuntu_stig/ubuntu20.04_rules.csv
    
    [Teardown]    Cleanup Test Resources    ${results}[site_id]    ${results}[template_id]