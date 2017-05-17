#!/bin/bash

gcc -o serial -fstack-protector serial.c
strip serial
