# AKS KQL quries

## ContainerLogV2 - Log Size by Pod Namespace

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

## AKSAuditAdmin - All Entra Users

```
AKSAuditAdmin
| extend UserDetails = parse_json(User)
| where UserDetails.username matches regex "^([a-z0-9]{8}-)([a-z0-9]{4}-)([a-z0-9]{4}-)([a-z0-9]{4}-)([a-z0-9]{12})$"

```

## AKSAuditAdmin - Estimate Size By RequestUri/Verb

```
AKSAuditAdmin
| extend sizeEstimateOfColumn = estimate_data_size(*)
| summarize totalSize=sum(sizeEstimateOfColumn) by RequestUri, Verb, UserAgent
| extend sizeGB = format_bytes(totalSize,2,"GB")
| order by totalSize desc

```

## AKSAuditAdmin - Estimate Size By RequestUri/Verb Dynamic Size Output

```
AKSAuditAdmin
| extend sizeEstimateOfColumn = estimate_data_size(*)
| summarize totalSize=sum(sizeEstimateOfColumn) by RequestUri, Verb, UserAgent
| extend sizeGB = iff(totalSize > 999999999, format_bytes(totalSize,2,"GB"), format_bytes(totalSize,2,"MB"))
| order by totalSize desc

```

## AKSAuditAdmin - Count By RequestUri/Verb

```
AKSAuditAdmin
| summarize Count=count() by RequestUri, Verb, UserAgent
| order by Count desc

```

