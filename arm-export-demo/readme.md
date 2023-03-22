## Route Table Export Demo
Script example to export a specified route table and commit it to an Azure DevOps Git repo. 

This should be used in an Automation Account Runbook with appropriate permissions assigned.

The AA's managed identity should have access to:
- key vault secrets (for the personal access token) 
- read access to the resource group containing the route table
