#!/bin/bash

sudo modprobe -r ec_sys
sudo modprobe ec_sys write_support=1
echo -n -e "\x0a" | sudo dd of="/sys/kernel/debug/ec/ec0/io" bs=1 seek=12 count=1 conv=notrunc 2> /dev/null
sudo modprobe -r ec_sys