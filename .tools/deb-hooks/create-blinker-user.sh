#!/bin/bash

egrep '^blinker:' /etc/passwd >/dev/null || useradd -d /nonexistent -M -r blinker
