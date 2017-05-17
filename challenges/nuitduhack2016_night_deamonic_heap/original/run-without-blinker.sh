#!/bin/bash

socat tcp4-listen:12345,reuseaddr exec:./role_gaming
