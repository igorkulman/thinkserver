#!/bin/bash

grep -q close /proc/acpi/button/lid/*/state

if [ $? = 0 ]; then
    sleep 0.2 && vbetool dpms off
fi

grep -q open /proc/acpi/button/lid/*/state

if [ $? = 0 ]; then
    vbetool dpms on
fi