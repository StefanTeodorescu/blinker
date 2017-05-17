// A reimplementation of 'Night Deamonic Heap' (pwn400) from Nuit du Hack Quals 2016.
// A decent writeup: https://github.com/sysdream/WriteUps/blob/master/ndhquals2016/NightDaemonicHeap.md

#include <vector>
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <unistd.h>

void prompt() {
  std::cout << ">";
  fflush(stdout);
}

void exit_from_game() {
  std::cout << "\tyour team has been successfully save in our DataBase" << std::endl;
  exit(0);
}

void print_help() {
  std::cout << "\tYes We Can Help" << std::endl;
  std::cout << "\tWelcome to the personnage creator" << std::endl;
  std::cout << "\tYou have to choose your team" << std::endl;
  std::cout << "\tcommands are : " << std::endl;
  std::cout << "\tnew <type> <name> (types are wizzard or barbarian)" << std::endl;
  std::cout << "\tdelete <name> (delete your dude)" << std::endl;
  std::cout << "\tchange <old_name> <new_name> (rename your dude)" << std::endl;
  std::cout << "\texit (to exit the game)" << std::endl;
  std::cout << "\tprint all (print your team)" << std::endl;
  std::cout << "\tTrust Me!" << std::endl;
}

<%
padding_longs = 14 + random_number(0..6)*2
%>
class Character {
public:
  struct {
    unsigned long len_name : 32; // @0x8
    unsigned long experience : 32; // @0xc
    unsigned long life : 32; // @0x10
    unsigned long magic : 32; // @0x14
    unsigned long strength : 32; //@0x18
    unsigned long smartness : 32; // @0x1c
  };

  unsigned long long padding[<%= padding_longs %>];
  char *name_ptr; // @0xf0 - (26 - padding_longs) * 8
  <% if padding_longs < 26 %>
  unsigned long long padding2[<%= 26 - padding_longs %>];
  <% end %>

  Character(char *name) {
    for (long long i = 0; i != <%= padding_longs %>; i++)
      padding[i] = i;

    experience = 0;
    int name_len = strlen(name);
    len_name = name_len + 1;
    char *name_buf = (char *)calloc((size_t)name_len, 1uLL);
    name_ptr = name_buf;
    strncpy((char *)name_buf + 1, name, name_len);
  }

  virtual void print() = 0;
  virtual void attack() = 0;
};

class Barbarian : public Character {
public:
  Barbarian(char *name) : Character(name) {
    life = 10;
    smartness = 2;
    strength = 10;
    name_ptr[0] = 'B';
    magic = 0;
  }

  virtual void print()
  {
    std::cout << "I am a barbarian so don't be jalous " << std::endl;
    std::cout << "My name is : " << name_ptr << std::endl;
    std::cout << "My stats : " << std::endl;
    std::cout << "experience: " << experience << std::endl;
    std::cout << "magic: " << magic << std::endl;
    std::cout << "life: " << life << std::endl;
    std::cout << "strength: " << strength << std::endl;
    std::cout << "smartness: " << smartness << std::endl;
  }

  virtual void attack()
  {
    std::cout << "I hit you in the face" << std::flush;
  }
};

class Wizzard : public Character {
public:
  Wizzard(char *name) : Character(name) {
    name_ptr[0] = 'W';
    strength = 2;
    smartness = 10;
    life = 5;
    magic = 10;
  }

  virtual void print()
  {
    std::cout << "I am a Wizzard so don't be a prick " << std::endl;
    std::cout << "My name is : " << name_ptr << std::endl;
    std::cout << "My stats : " << std::endl;
    std::cout << "experience: " << experience << std::endl;
    std::cout << "magic: " << magic << std::endl;
    std::cout << "life: " << life << std::endl;
    std::cout << "strength: " << strength << std::endl;
    std::cout << "smartness: " << smartness << std::endl;
  }

  virtual void attack()
  {
    std::cout << "I ll burn ya with all my magic!" << std::flush;
  }
};

Character *get_personnage(char *name, std::vector<Character *>& team, int character_count)
{
  Character *result = NULL;

  for (int i = 0; i < character_count; i++) {
    Character *character = team[i];

    if (!strncmp(name, character->name_ptr, character->len_name)) {
      result = character;
      break;
    }
  }

  return result;
}

#include "process_commands.cxx"

int main(int argc, char **argv) {
  int num_chars = 0;
  std::vector<Character *> team (20);
  char buf[4096];

  while (true) {
    prompt();
    memset(buf, 0, sizeof(buf));
    int len = read(0, buf, sizeof(buf)-1);
    if (!len)
      break;
    buf[len-1] = 0;
    process_commands(buf, &num_chars, team);
  }

  exit_from_game();
  return 0;
}
