*** Settings ***
Documentation     Ubuntu 20.04 CIS Benchmark Compliance Testing

Resource          ../../../resources/e2e_benchmark_testing.robot


*** Test Cases ***
tfugug86755Ubuntu 20.04 -CIS Benchmarks
    [Documentation]    Validates Ubuntu 20.04 against CIS Level 1 benchmark
    [Tags]    ubuntu    ubuntu2004    linux    cis    benchmark    level1    compliance    e2e
    
    # Generate unique identifiers for this test run
    ${timestamp}=    Evaluate    int(__import__('time').time())
    ${site_name}=    Set Variable    Ubuntu2004_CIS_Level1_${timestamp}
    ${template_name}=    Set Variable    ubuntu2004_cis_template_${timestamp}
    
    # Execute Ubuntu 20.04 CIS Level 1 compliance test
    ${results}=    Run Complete E2E Benchmark Test
    ...    os_identifier=CIS_NGINX_NGINX
    ...    vm_cred_types=compliance,server
    ...    os_benchmark_identifier=CIS_NGINX_Benchmark
    ...    version=2.1.0
    ...    scan_template=cis
    ...    server_service=ssh
    ...    scope=S
    ...    site_name=${site_name}
    ...    template_name=${template_name}
    ...    policy_list=all
    ...    csv_file=${EMPTY}