# Blinker

Please see the [website](https://gs509.user.srcf.net/blinker/) for
documentation.

## How to build

You will need Ruby 2.3 and [FPM](https://github.com/jordansissel/fpm/)
installed. The preferred way is to install Ruby from a source of your choice and
then install FPM from Rubygems. On Ubuntu 16.04 the following should do it:
`apt-get install ruby2.3 && gem install fpm`.

The current build system is a hodge-podge of bash scripts. You will want to
create a new directory outside of the source tree, and run the build scripts
from there. This will result in .deb files popping up in the working directory.

The build script for each component is in the appropriate folder, and is called
something like `package-blinker-foo.sh`.

## License

[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)
