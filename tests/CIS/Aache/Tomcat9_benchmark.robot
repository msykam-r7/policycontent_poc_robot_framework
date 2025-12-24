*** Settings ***
Documentation     Apache Tomcat 9 CIS Benchmark Compliance Testing

Resource          ../../../resources/e2e_benchmark_testing.robot


*** Test Cases ***
Tomcat 9 - CIS Benchmark Level 1 Compliance Test
    [Documentation]    Validates Apache Tomcat 9 against CIS Level 1 benchmark
    [Tags]    tomcat    tomcat9    application    cis    benchmark    level1    compliance    e2e
    
    # Generate unique identifiers for this test run
    ${timestamp}=    Evaluate    int(__import__('time').time())
    ${site_name}=    Set Variable    Tomcat9_CIS_Level1_${timestamp}
    ${template_name}=    Set Variable    tomcat9_cis_template_${timestamp}
    
    # Execute Apache Tomcat 9 CIS Level 1 compliance test
    ${results}=    Run Complete E2E Benchmark Test
    ...    os_identifier=CIS_Apache_Tomcat_9
    ...    vm_cred_types=compliance,server
    ...    os_benchmark_identifier=CIS_Apache_Tomcat_9_Benchmark
    ...    version=1.2.0
    ...    scan_template=cis
    ...    server_service=ssh
    ...    scope=S
    ...    site_name=${site_name}
    ...    template_name=${template_name}
    ...    policy_list=all
    ...    csv_file=${EXECDIR}/testdata/validation_rules/CIS/Tomcat9/level1.csv


