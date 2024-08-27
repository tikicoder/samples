# AKS KQL quries

## Generate Log Size by Pod Namespace

```kql
ContainerLogV2
| where LogSource == 'stderr'
| extend sizeEstimateOfColumn = estimate_data_size(*)
| summarize
    ErrorCount = countif(LogLevel == 'error'),
    WarnCount = countif(LogLevel == 'warn'),
    TotalNonErrorLogEntries = count(PodNamespace) - countif(LogLevel == 'error'),
    TotalLogEntries = count(PodNamespace),
    AvgLogEntriesPerMin = count(PodNamespace) / 1440,
    sizeEstimateOfColumn = format_bytes(sum(sizeEstimateOfColumn))
    by PodNamespace, format_datetime(TimeGenerated, 'yyyy/MM/dd')
| order by ErrorCount



```

