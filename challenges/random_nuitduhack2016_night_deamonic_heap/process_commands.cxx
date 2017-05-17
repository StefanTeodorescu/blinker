void process_commands(char *cmd, int *character_count, std::vector<Character *>& team)
{
  if ( memcmp("new ", cmd, 4uLL) )
    {
      if ( !memcmp("delete ", cmd, 7uLL) )
        {
          int num_chars = *character_count;
          Character* character = get_personnage((char *)cmd + 7, team, num_chars);
          if ( character )
            {
              int i = 0;
              for (; i < num_chars && character != team[i]; i++) ;

              free(character->name_ptr);
              delete character;
              team[i] = team[--(*character_count)];
            } else {
            std::cout << "Character doesn't exist" << std::endl;
          }
          return;
        }
      if ( !memcmp("help", cmd, 4uLL) )
        {
          print_help();
          return;
        }
      if ( !memcmp("change ", cmd, 7uLL) )
        {
          signed int i = 7;
          char *p = cmd + 7;

          do {
            if (*p++ == ' ') {
              cmd[i] = 0;
              i += 1;
              break;
            }
            i++;
          } while (i != 4095);

          if (i == 4095)
            {
              std::cout << "what are you trying to do!!!" << std::endl;
              return;
            }

          int num_chars = *character_count;
          Character* character = get_personnage((char *)cmd + 7, team, num_chars);
          if ( character )
            {
              char *new_name = (char *)cmd + (unsigned int)i;
              if ( get_personnage(new_name, team, num_chars) ) {
                std::cout << "Character already exist!!!!!" << std::endl;
                return;
              }
              unsigned int new_len_name = strlen(new_name);
              unsigned int len_name = character->len_name;
              if ( len_name < new_len_name )
                {
                  char *new_buf = (char *)realloc(character->name_ptr, (signed int)new_len_name);
                  character->len_name = new_len_name;
                  character->name_ptr = new_buf;
                  len_name = new_len_name;
                }
              strncpy(character->name_ptr, new_name, character->len_name);
              std::cout << "name change successfully" << std::endl;
            }
          else {
            std::cout << "Character doesn't exist" << std::endl;
          }
          return;
        }
      else
        {
          if ( !memcmp("print all", cmd, 9uLL) )
            {
              std::cout << "Print character's list : " << std::endl;

              if ( *character_count )
                for (unsigned int i = 0; i < *character_count; i++)
                  team[i]->print();

              return;
            }
          else
            {
              std::cout << "\twhat do you mean, this is why i hate newbies" << std::endl;
              return;
            }
        }
    }
  else {
    if ( (unsigned int)*character_count > 19 )
      {
        puts("no don't do that");
        return;
      }
    if ( !memcmp("barbarian ", (char *)cmd + 4, 10uLL) )
      {
        cmd[13] = 'B';
        int num_chars = *character_count;
        if ( get_personnage((char *)cmd + 13, team, num_chars) )
          std::cout << "Character exist!" << std::endl;

        Barbarian *barbarian = new Barbarian(cmd+14);

        team[(*character_count)++] = barbarian;
      }
    if ( !memcmp("wizzard ", (char *)cmd + 4, 8uLL) )
      {
        cmd[11] = 'W';
        int num_chars = (unsigned int)*character_count;
        if ( get_personnage((char *)cmd + 11, team, num_chars) )
          std::cout << "Character exist!" << std::endl;

        Wizzard *wizzard = new Wizzard(cmd+12);

        team[(*character_count)++] = wizzard;
      }
  }
}
