#include <stdio.h>
#include <string.h>

<%

len = 32
flag_hex = random_hex len
declare_flag "flag{#{flag_hex}}"

real_checks = (0...len).to_a.map { |i| Hash[ :byte_index => i, :real => true] }.shuffle
red_checks = ((0...len).to_a.map { |i| Hash[ :byte_index => i, :real => false] } * 4).shuffle

checks = [real_checks.first] + (real_checks[1..-1] + red_checks).shuffle

real_indices = checks.each_with_index.select { |c, i| c[:real] }.map { |c, i| i }
real_map = real_indices.each_with_index.map { |check_index, among_reals| [checks[check_index][:byte_index], among_reals] }.to_h
red_indices = checks.each_with_index.select { |c, i| !c[:real] }.map { |c, i| i }

yes_jump = checks.map { |check|
  if check[:real]
    next_check = real_indices[real_map[check[:byte_index]] + 1]
    if next_check
      "check_#{next_check}"
    else
      "check_good"
    end
  else
    "check_#{red_indices.sample}"
  end
}

checks = checks.each_with_index.map { |check, check_i|
  x = rand(0..255)

  Hash[ :label => "check_#{check_i}",
        :byte_index => check[:byte_index],
        :xor => x,
        :compare => (flag_hex[check[:byte_index]]&.ord || 0) ^ x,
        :no => "check_#{red_indices.shift||"wrong"}",
        :yes => yes_jump[check_i] ]
}

%>

int main(int argc, char **argv) {
  char buf[40];

  printf("Password: ");
  fgets(buf, sizeof(buf), stdin);

  if (strncmp(buf, "flag{", 5))
    goto check_wrong;

  if (strlen(buf) != 39)
    goto check_wrong;

  if (buf[38] != '\n')
    goto check_wrong;

  if (buf[37] != '}')
    goto check_wrong;

<%
  checks.each { |check|
%>
  <%= check[:label] %>:
  if ((buf[5+<%= check[:byte_index] %>] ^ <%= check[:xor] %>) == <%= check[:compare] %>)
    goto <%= check[:yes] %>;
  else
    goto <%= check[:no] %>;
<%
  }
%>
  check_good:
  puts("Good work!");
  return 0;
  check_wrong:
  puts("Wrong!");
  return 0;
}
