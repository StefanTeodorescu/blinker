#!/bin/bash

gcc -o checker -fstack-protector -z relro -z now checker.c
