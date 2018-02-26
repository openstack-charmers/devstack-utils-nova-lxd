#!/bin/bash

## fetch the /opt/stack/logs/testr_results.html.gz to the current directory and gunzip it
scp devstack-gate:/opt/stack/logs/testr_results.html.gz .
gunzip testr_results.html.gz

