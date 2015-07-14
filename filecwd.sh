#!/bin/bash
for f in $(ls -a)
do
    file "$f"
done
