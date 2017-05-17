// A reimplementation of 'serial' (pwn440) from Codegate Quals 2016.
// Excellent write-up: http://ebfe.dk/ctf/2016/03/21/codegate_quals_serial/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

void check_serial(char *buf) {
  short decimals[3];
  int i = 0, j = 0;
  short decimal_accum = 0;
  unsigned short var_x = 0xf0fu, var_y = 0xff0u, var_z = 0xababu, var_v = 0xacacu;
  unsigned long long var_w;

  for (; i <= 11; i++) {
    if ((unsigned)(buf[i] - '0') > 9) {
      puts("number only");
      exit(-1);
    }

    decimal_accum = decimal_accum * 10 + buf[i] - '0';

    if (i % 4 == 3) {
      decimals[j++] = decimal_accum;
      decimal_accum = 0;
    }
  }

  var_v = ((var_x >> 8 | var_x << 8) + (var_v ^ var_z ^ var_y)) ^ decimals[0];
  var_z = ((var_z << 5 | var_z >> 11) + (var_z ^ var_v ^ var_x)) ^ decimals[1];
  var_y = ((var_z << 3 | var_z >> 13) + (var_y ^ var_z ^ var_v)) ^ decimals[2];
  var_w = (((((unsigned long long)var_v << 16) ^ (unsigned long long)var_z) << 16) ^ (unsigned long long)var_y) << 16;

  if (var_w == 0) {
    puts("Correct!");
  } else {
    puts("Wrong!");
    exit(-1);
  }
}

void read_line(char *buf) {
  fgets(buf, 32, stdin);
  strtok(buf, "\n");
}

void error(char *buf) {
  printf("hey! %p\n", (void *)(long long)buf[0]);
}

typedef struct _entry {
  char buf[24];
  void (*func)(struct _entry *);
} entry;

unsigned char counter = 0;

void default_dump_func(entry *array) {
  for (unsigned int i = 0; i < counter; i++)
    if (array[i].buf[0])
      printf("%d. %s\n", i, array[i].buf);
}

void add_fun(entry *array) {
  if (counter <= 9) {
    char buf[32];

    array[counter].func = default_dump_func;

    printf("insert >> ");
    read_line(buf);

    memcpy(array[counter++].buf, buf, strlen(buf));
  } else {
    puts("full");
  }
}

void remove_fun(entry *array) {
  if (counter != 0) {
    char choice;
    char buf[8];

    default_dump_func(array);

    printf("choice>> ");
    read_line(buf);
    choice = buf[0] - '0';

    if (choice < 0 || choice > 9) {
      puts("Wrong index");
      exit(-1);
    } else {
      if (array[choice].buf[0]) {
        memset(array[choice].buf, 0, 4);
        counter--;

        for (unsigned int i = choice; i < counter; i++)
          array[i] = array[i+1];
      } else {
        puts("empty element");
      }
    }
  } else {
    puts("empty");
  }
}

void dump_fun(entry *entry) {
  if (entry->buf[0]) {
    printf("func : %p\n", entry->func);
    entry->func(entry);
  }
}

int main(int argc, char **argv) {
  char product_key[24];
  char choice[16];
  entry *array;

  fflush(stdout);
  setvbuf(stdout, NULL, _IONBF, 0);

  array = calloc(10, 32);

  printf("input product key: ");
  read_line(product_key);
  check_serial(product_key);

  while (true) {
    puts("Smash me!");
    puts("1. Add 2. Remove 3. Dump 4. Quit");
    printf("choice >> ");
    read_line(choice);

    if (choice[0] == '2') {
      remove_fun(array);
      continue;
    } else if (choice[0] > '2') {
      if (choice[0] == '3') {
        dump_fun(array);
        continue;
      } else if (choice[0] == '4') {
        puts("bye");
        return -1;
      }
    } else if (choice[0] == '1') {
        add_fun(array);
        continue;
    }

    error(choice);
  }
}
