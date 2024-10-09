# KQL quries

## Generate Log Size by table name

```kql
union withsource=_TableName *
| extend sizeEstimateOfColumn = estimate_data_size(*)
| summarize totalSize=sum(sizeEstimateOfColumn) by _TableName
| extend sizeGB = format_bytes(totalSize,2,"GB")
| order by sizeGB desc  


```

