#!/bin/bash

g++ -o role_gaming -fstack-protector -fPIE -pie -O1 -z relro -z now role_gaming.cxx
