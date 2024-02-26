#!/bin/bash

dry_run=0
pipeline_id=""
organization=""
project=""
default_reporef=''
default_bodyjson='{"previewRun": true, "templateParameters": {}, "resources":{"repositories":{"self":{"refName":"%refname%"}}}}'