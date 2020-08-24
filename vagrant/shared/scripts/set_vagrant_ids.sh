#!/bin/sh
usermod -u 21006 vagrant 2>&1 > /tmp/temp_usermod.output
groupmod -g 31006 vagrant 2>&1 > /tmp/temp_groupmod.output
