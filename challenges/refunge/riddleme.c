#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define STACK_SIZE 1024

int riddler(int w, int h, unsigned long long *prog) {
#define _AT(XPOS, YPOS) (prog[(YPOS)*w+(XPOS)])
#define _BOUNDS(XPOS, YPOS) ((XPOS)<0 || (XPOS)>=w || (YPOS)<0 || (YPOS)>=h)
#define AT(XPOS, YPOS) (_BOUNDS((XPOS),(YPOS)) ? exit(1),' ' : _AT((XPOS), (YPOS)))
#define SET(XPOS, YPOS, VAL) { if (_BOUNDS((XPOS),(YPOS))) exit(1); else _AT((XPOS), (YPOS)) = (unsigned long long)(VAL); }

  struct dd { int x, y; } d = { 1, 0 };
  int x = 0, y = 0;

  unsigned long long stack[STACK_SIZE];
  unsigned long long *sp = stack;

#define PUSH(VALUE) { if (sp < stack + STACK_SIZE) *sp++ = (unsigned long long)(VALUE); else (exit(1),0); }
#define POP() ((sp > stack) ? *(--sp) : (exit(1),0))
#define LEFT() { d = (struct dd){ -1, 0 }; }
#define RIGHT() { d = (struct dd){ 1, 0 }; }
#define UP() { d = (struct dd){ 0, -1 }; }
#define DOWN() { d = (struct dd){ 0, 1 }; }

  int str = 0, br = 0;

  while (1) {
    if (_BOUNDS(x,y)) exit(1);

    // #define DEBUG
    #ifdef DEBUG
    #define ANSI_COLOR_RED     "\x1b[31m"
    #define ANSI_BGCOLOR_RED   "\x1b[41m"
    #define ANSI_COLOR_GREEN   "\x1b[32m"
    #define ANSI_COLOR_YELLOW  "\x1b[33m"
    #define ANSI_COLOR_BLUE    "\x1b[34m"
    #define ANSI_COLOR_MAGENTA "\x1b[35m"
    #define ANSI_COLOR_CYAN    "\x1b[36m"
    #define ANSI_COLOR_RESET   "\x1b[0m"
    if (AT(x,y)!=' ') {
    puts("");
    /*for (int i = 0; i < h; i++) {
      for (int j = 0; j < w; j++) {
        unsigned v = AT(j,i);
        if (j == x && i == y)
          printf(ANSI_BGCOLOR_RED);
        if (v >= 32 && v <= 126) {
          printf("%c" ANSI_COLOR_RESET, (char)v);
        } else {
          printf(ANSI_COLOR_CYAN "?" ANSI_COLOR_RESET);
        }
      }
      puts("");
    }
    puts("");*/
    unsigned long long *d_sp = stack;
    while (d_sp < sp)
      printf("%llu ", *d_sp++);
    printf("\nExecuting: %c", (char)AT(x,y));
    puts("\n");
    }

    struct timespec wait = { 0, 50000000 };
    //nanosleep(&wait, NULL);

    #endif

    if (br) {
      br = 0;
    } else if (str) {
      if (AT(x,y)=='"')
        str = 0;
      else
        PUSH(AT(x,y));
    } else {
      unsigned long long t0, t1, t2;

      switch(AT(x,y)) {
      case '0':
      case '1':
      case '2':
      case '3':
      case '4':
      case '5':
      case '6':
      case '7':
      case '8':
      case '9':
        PUSH(AT(x,y)-'0');
        break;
      case '+':
        t0 = POP();
        t1 = POP();
        PUSH(t0 + t1);
        break;
      case '-':
        t0 = POP();
        t1 = POP();
        PUSH(t1-t0);
        break;
      case '*':
        t0 = POP();
        t1 = POP();
        PUSH(t0*t1);
        break;
      case '/':
        t0 = POP();
        t1 = POP();
        PUSH(t1/t0);
        break;
      case '%':
        t0 = POP();
        t1 = POP();
        PUSH(t1%t0);
        break;
      case '!':
        t0 = POP();
        PUSH(!t0);
        break;
      case '`':
        t0 = POP();
        t1 = POP();
        PUSH(t1>t0);
        break;
      case '>':
        RIGHT();
        break;
      case '<':
        LEFT();
        break;
      case '^':
        UP();
        break;
      case 'v':
        DOWN();
        break;
      case '?':
        switch (rand()%4) {
        case 0:
          LEFT();
          break;
        case 1:
          RIGHT();
          break;
        case 2:
          UP();
          break;
        case 3:
          DOWN();
          break;
        }
        break;
      case '_':
        t0 = POP();
        if (t0)
          LEFT()
        else
          RIGHT()
        break;
      case '|':
        t0 = POP();
        if (t0)
          UP()
        else
          DOWN()
        break;
      case '"':
        str = !str;
        break;
      case ':':
        t0 = POP();
        PUSH(t0);
        PUSH(t0);
        break;
      case '\\':
        t0 = POP();
        t1 = POP();
        PUSH(t0);
        PUSH(t1);
        break;
      case '$':
        POP();
        break;
      case '.':
        t0 = POP();
        printf("%llu ", t0);
        break;
      case ',':
        t0 = POP();
        printf("%c", (char)t0);
        break;
      case '#':
        br = 1;
        break;
      case 'p':
        t0 = POP();
        t1 = POP();
        t2 = POP();
        SET(t1,t0,t2);
        break;
      case 'g':
        t0 = POP();
        t1 = POP();
        PUSH(AT(t1,t0));
        break;
      case '&':
        scanf("%lld", &t0);
        PUSH(t0);
        break;
      case '~':
        #ifdef DEBUG
        printf("Waiting for input: ");
        #endif
        scanf("%c", (char *)&t0);
        PUSH(t0);
        break;
      case '@':
        exit(0);
        break;
      case ' ':
        break;
      default:
        exit(1);
      }
    }

    x += d.x;
    y += d.y;
  }

#undef DOWN
#undef UP
#undef RIGHT
#undef LEFT
#undef POP
#undef PUSH
#undef SET
#undef AT
#undef _BOUNDS
#undef _AT
}

char *riddle =
#include "challenge.h"
;

int main (int argc, char **argv) {
  unsigned long long *playfield = malloc(W*H*sizeof(unsigned long long));

  if (!playfield)
    exit(1);

  for (int y = 0; y < H; y++)
    for (int x = 0; x < W; x++)
      playfield[y*W+x] = (unsigned long long)riddle[y*W+x];

  riddler(W, H, playfield);
}


