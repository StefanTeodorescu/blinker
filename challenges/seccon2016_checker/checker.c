// A reimplementation of 'checker' (pwn300) from SECCON 2016.
// A nice write-up: https://bannsecurity.com/index.php/home/10-ctf-writeups/39-seccon-2016-checker

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <unistd.h>
#include <fcntl.h>

char name[128];
char flag[128];

void read_flag(char *file) {
  int fd = open(file, 0);

  if (fd == -1) {
    perror(file);
    exit(-1);
  }

  read(fd, flag, sizeof(flag));
  close(fd);
}

__attribute__((constructor)) void init() {
  read_flag("flag");
}

unsigned getaline(char *buf) {
  unsigned r = 0;
  char c = 0xff;

  while (c) {
    read(0, &c, 1);
    if (!c)
      break;

    if (c == '\n')
      c = 0;

    *buf++ = c;
    r++;
  }

  return r;
}

int main(int argc, char **argv) {
  char buf[128];

  dprintf(1, "Hello! What is your name?\nNAME : ");
  getaline(name);

  do {
    dprintf(1, "\nDo you know flag?\n>> ");
    getaline(buf);
  } while (strcmp(buf, "yes"));

  dprintf(1, "\nOh, Really??\nPlease tell me the flag!\nFLAG : ");
  getaline(buf);

  if (!buf[0]) {
    dprintf(1, "Why won't you tell me that???\n");
    exit(0);
  }

  dprintf(1, (strcmp(flag, buf)) ? "You are a liar...\n" : "Thank you, %s!!\n", name);
  return 0;
}
