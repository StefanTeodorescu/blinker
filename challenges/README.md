# Example challenges for Blinker

## How to build

To build a convenient .deb out of a challenge, run `package-blinker-challenge.sh
challenge_name` (preferably in an empty directory).

## Included challenges

### The simplest example

This type of challenge does not really benefit from using Blinker, so this
serves more as an example of how to use the Blinker DSL as a Makefile.

* XorCipher: A several paragraphs long message containing the flag is
  encrypted using an XOR cipher. This means that a short (8-12 bytes) random key
  is repeated as necessary to yield a key of the same length as the plaintext.
  Then the two are XOR-ed together to yield the ciphertext. Such a cipher can be
  broken by simple statistical analysis if the message is long enough.

### Purpose-built challenges

These challenges were designed for use with Blinker. (Each one also exists in a
'static' version, which is essentially just one specific challenge instance
hardcoded into a template. These were used in the user study conducted to
evaluate the effectiveness of Blinker.)

* AmazingRop: A text based game in which the player must find their way out
  of a maze. The input mechanism is broken, and thus the player is unable to
  move. The input mechanism also contains a trivial stack-based buffer overflow.
  Exploiting this will allow the player to execute a simple ROP
  chain, where each gadget is one of the functions intended to enable movement.
  The binary employs a small amount of `ptrace` trickery to make
  debugging more painful and force the player to solve the challenge in the
  intended way.

* HommageAIrc: A simple chat server with a text based protocol implemented
  as a 32-bit application. The implementation contains a format string injection
  vulnerability, and a `write_flag` function, which must be executed to
  acquire the flag. The vulnerability can be triggered by a new user
  connecting to the server when the last message was a specially crafted one.

* Mysecuresite: A network packet capture file is provided to players. The
  packet capture is a recording of a padding oracle attack against a
  CBC-encrypted cookie value acquired from a web application. The
  attack traffic is intermingled with benign traffic from other hosts. Isolating
  the attack traffic and reconstructing the plaintext value of the cookie yields
  the flag.
  
* ReNormalize: The application asks for a password, which is then fed into a
  function with a large number of similar basic blocks. Each basic block
  compares a byte at a fixed offset in the input to a hardcoded value and jumps
  somewhere depending on the result. Most of the checks are red herrings, which
  eventually lead to the rejection of the password, or non-termination of the
  application. The right password can be found by performing a depth first
  search on the control flow graph to find the sequence of comparisons that
  eventually lead to the acceptance of the password.
  
* Refunge: A befunge interpreter with an embedded program. The
  embedded program prompts for a password, performs simple format checks, then
  proceeds to treat the password as a 128 bit number, and verifies that it
  equals a chosen number by checking its modulus with four carefully chosen 32
  bit numbers, exploiting the Chinese Remainder Theorem.

* SimpleBof: A basic single-line echo server with a trivial stack-based
  buffer overflow. The flag is contained in a text file in the working
  directory. The difficulty is that the binary is too small to contain enough
  useful ROP gadgets. Therefore a return-to-libc attack
   must be executed. However, ASLR is enabled,
  so to discover the address of the desired gadget in libc, a series of memory
  leaks must be exploited first, each time also diverting control flow to allow
  another buffer overflow instead of exiting.

### 3rd party challenges

These are challenges that appeared at major CTF events. I did not have sources
available, so I have reimplemented them from scratch. Therefore the resemblance
will not be perfect, but in each case it should be good enough that exploits
working against the original binary work against the reimplementation too (maybe
with some small modifications). In each case, the original challenge binary and
exploit are provided for reference.

For each challenge, there is also a randomised version (prefixed with 'Random')
that tries to utilise Blinker to generate different challenge instances, as
opposed to recreating the original as closely as possible.

* Seccon2016Checker: The challenge named 'checker' from SECCON 2016 Online
  CTF. The application contains a simple stack-based buffer overflow, but
  exploitation is thwarted by the use of stack canaries. However, the
  `argv[0]` pointer can be overwritten to point to the flag instead,
  which results in the flag being printed by the canary error handler.

* Codegate2016Serial: The challenge named 'serial' from Codegate CTF 2016
  Quals. The application first asks for a serial number, finding which is a
  simple exercise in reverse engineering. Afterwards, the application presents
  a menu-based interface that allows storing and recalling fixed-size strings.
  When adding a new string, a `memcpy` call allows overwriting a function
  pointer, which will be called when printing the string. The problem is
  somewhat open-ended, but the simplest avenue of exploitation is once again a
  series of memory leaks followed by a return-to-libc attack.
  
* Nuitduhack2016NightDeamonicHeap: The challenge named 'Night Deamonic Heap'
  [sic] from Nuit du Hack CTF Quals 2016. The application models the character
  selection interface of a text based role playing game. The character creation
  mechanism involves a heap-based buffer overflow, which can be exploited to
  change the size of a free `malloc` chunk. This allows overlapping a user
  controlled string with a vtable pointer. After having acquired control of the
  instruction pointer, exploitation proceeds as previously.
