#include <stdio.h>

int main(int argc, char **argv) {
  char buf[<%= random_number 32..256 %>];

  printf("Welcome! What's your name? ");
  fflush(stdout);
  scanf("%[^\n]%*c", buf);

  if (buf[0] >= 'A' && buf[0] <= 'Z')
    printf("Hello, %s!\n", buf);
  else
    puts("What sort of name doesn't start with a capital letter? :O");

  return 0;
}

void execute_me() {
  puts("Congrats, you have RIP control. Now you just need a shellcode.");
}
