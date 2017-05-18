A helper tool used by blinker-framework when generating packet capture files.
Basically just a thin layer of glue code above Mininet.

The dependencies on chromium, chromedriver, and xvfb are present to make it easy
to create realistic automated web clients for challenges (e.g. XSS scenarios),
but are not strictly necessary for packet capture generation to work.
