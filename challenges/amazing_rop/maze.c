#ifdef BLINKER_FRAMEWORK_PRESENT

<%
width = 2 #7
height = 2 #3

# up, right, down, left
walls = (0...height).map { (0...width).map { [true, true, true, true] } }
visited = (0...height).map { [false]*width }

visited[0][0] = true
stack = [[0,0]]

until stack.empty?
  x, y = stack.pop

  choices = [[x,y-1,0],[x+1,y,1],[x,y+1,2],[x-1,y,3]].select { |nx, ny, _|
    visited[ny] && visited[ny][nx] == false && nx >= 0 && ny >= 0 && nx < width && ny < height
  }.shuffle

  unless choices.empty?
    stack.push [x,y]
    nx, ny, d = choices.first
    visited[ny][nx] = true
    walls[y][x][d] = false
    walls[ny][nx][(d+2)%4] = false
    stack.push [nx,ny]
  end
end

maze = (0..(height*2)).map { ['#']*(width*2+1) }
(0...height).each { |y|
  (0...width).each { |x|
    lwalls = walls[y][x]
    row = 2*y + 1
    col = 2*x + 1
    maze[row][col] = ' '
    maze[row-1][col] = ' ' unless lwalls[0]
    maze[row][col-1] = ' ' unless lwalls[3]
  }
}
maze[2*height-1][2*width] = ' '
%>

#define W <%= 2*width+1 %>
#define H <%= 2*height+1 %>

char maze[H][W] = {
  <% maze.each { |row| %>
  {
    <%= row.map { |c| "'#{c}'" }.join(',') %>
  },
  <% } %>
};

#define BUFFER_SIZE <%= random_number (16..128) %>

#else

#define W 15
#define H 7

char maze[H][W] = {
  {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
  {1,0,1,0,0,0,0,0,0,0,0,0,0,0,1},
  {1,0,1,1,1,1,1,1,1,1,1,1,1,0,1},
  {1,0,0,0,0,0,1,0,0,0,1,0,0,0,1},
  {1,1,1,1,1,0,1,0,1,0,1,0,1,0,1},
  {1,0,0,0,0,0,0,0,1,0,0,0,1,0,0},
  {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
};

#define BUFFER_SIZE 32

#endif

int x = 1, y = 1;
int old_x = 1, old_y = 1;

#include <stdio.h>
#include <string.h>

#include <unistd.h>
#include <sys/ptrace.h>
#include <sys/types.h>
#include <sys/wait.h>

void print_maze() {
  for (int j = 0; j < H; j++) {
    for (int i = 0; i < W; i++)
      printf("%c", (i==x && j==y) ? '.' : maze[j][i]);
    printf("\n");
  }
}

void left() {
  old_x = x--;
  if (maze[y][x] == ' ') {
    puts("Going left.");
    return;
  } else {
    x = old_x;
    puts("Can't do that, sorry.");
    return;
  }
}

void right() {
  old_x = x++;
  if (maze[y][x] == ' ') {
    puts("Going right.");
  } else {
    x = old_x;
    puts("Can't do that, sorry.");
  }
}

void up() {
  old_y = y--;
  if (maze[y][x] == ' ') {
    puts("Going up.");
  } else {
    y = old_y;
    puts("Can't do that, sorry.");
  }
}

void down() {
  old_y = y++;
  if (maze[y][x] == ' ') {
    puts("Going down.");
  } else {
    y = old_y;
    puts("Can't do that, sorry.");
  }
}

int get_input() {
  char buf[BUFFER_SIZE];
  printf("[l/r/u/d]? ");
  scanf("%s", buf);
  #ifdef ENABLE_NAVI
  if (buf[0]=='l') return 3;
  if (buf[0]=='r') return 1;
  if (buf[0]=='u') return 0;
  if (buf[0]=='d') return 2;
  #endif
  return -1;
}

int interact() {
  print_maze();
  return get_input();
}

int main(int argc, char **argv) {
  if (argc != 2) {
    puts("The first (and only) argument must be the flag.");
    return 1;
  }

  pid_t child = fork();

  if (child == -1) {
    perror("fork");
    return 1;
  }

  if (child == 0) {
    memset(argv[1], 0, strlen(argv[1]));

    while (1) {
      if (x == W - 1 || y == H - 1 || x == 0 || y == 0) {
        ptrace(PTRACE_TRACEME, 0, NULL, NULL);
        raise(SIGSTOP);
        break;
      }

      int dir = interact();
      switch (dir) {
      case 0:
        up();
        break;
      case 1:
        right();
        break;
      case 2:
        down();
        break;
      case 3:
        left();
        break;
      default:
        puts("I don't understand, sorry.");
      }
    }
  }
  else {
    int wstatus;
    waitpid(child, &wstatus, 0);

    if (WIFSTOPPED(wstatus)) {
      int c_x = ptrace(PTRACE_PEEKDATA, child, &x, NULL);
      int c_y = ptrace(PTRACE_PEEKDATA, child, &y, NULL);
      puts("Game over.");

      if (c_x == W - 1 || c_y == H - 1 || c_x == 0 || c_y == 0) {
        printf("Good work! Here's your reward: %s\n", argv[1]);
      } else {
        puts("No luck there.");
      }
    }
  }

  return 0;
}
