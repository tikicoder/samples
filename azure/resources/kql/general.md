# KQL quries

## Generate Log Size by table name

```kql
union withsource=_TableName *
| extend sizeEstimateOfColumn = estimate_data_size(*)
| summarize totalSize=sum(sizeEstimateOfColumn) by _TableName
| extend sizeGB = format_bytes(totalSize,2,"GB")
| order by sizeGB desc  


```

## Generate CPU usage by family over the last 4 hours grouped by 1 hour

```kql
VMComputer 
| where TimeGenerated >= ago(4h)
| summarize sum(Cpus) by tolower(replace_regex(AzureSize, @'^([A-Za-z]{1,}_)([a-zA-Z]{1,})(\d)(.*)', @'\1\2\4')), bin(TimeGenerated, 1h)


```