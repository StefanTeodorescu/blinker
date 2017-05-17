#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <errno.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/select.h>
#include <netinet/in.h>
#include <unistd.h>
#include <fcntl.h>

#ifdef BLINKER_FRAMEWORK_PRESENT
#define PORT <%= BlinkerVars.listen_port %>
#else
#define PORT 60063
#endif

#define MAX_CLIENT 5

struct client {
  int sock;
  FILE *fd;
  char *name;
};

struct client clients[MAX_CLIENT];
int nclients = 0;

char last_msg[512];

void accept_on(int sock) {
  int new = accept(sock, NULL, NULL);

  if (new == -1 && errno != EAGAIN) {
    perror("accept");
    exit(1);
  }

  int flags = fcntl(new, F_GETFL, 0);

  if (flags == -1) {
    perror("fcntl");
    exit(1);
  }

  fcntl(new, F_SETFL, flags | O_NONBLOCK);

  if (flags == -1) {
    perror("fcntl");
    exit(1);
  }

  FILE *fd = fdopen(new, "r+");
  if (fd == NULL) {
    perror("fdopen");
    exit(1);
  }

  setbuf(fd, NULL);

  fprintf(fd, "Hello Anonymous! Use the /nick command to set a name others can recognize.\n");

  char online[1024];
  online[0] = 0;
  online[sizeof(online)-1] = 0;

  for (int i = 0; i < nclients; i++) {
    if (i > 0) strncat(online, ", ", sizeof(online) - strlen(online) - 1);
    strncat(online, clients[i].name, sizeof(online) - strlen(online) - 1);
  }

  fprintf(fd, "Online users: %s\n", online);
  fprintf(fd, "The last message was:\n");
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wformat-security"
  fprintf(fd, last_msg);
#pragma GCC diagnostic pop
  fflush(fd);

  clients[nclients].sock = new;
  clients[nclients].fd = fd;
  clients[nclients++].name = strdup("Anonymous");
}

int message_on(struct client *c) {
  char msg[256];
  char *r = fgets(msg, sizeof(msg), c->fd);

  if (r == NULL) {
    if (feof(c->fd)) {
      fclose(c->fd);
      *c = clients[--nclients];
      return 0;
    } else {
      perror("fgets");
      exit(1);
    }
  }

  int l = strlen(msg);
  if (r[l-1] == '\n') r[l-1] = 0;

  if (strncmp("/nick ", msg, 6) == 0) {
    free(c->name);
    c->name = strdup(msg+6);
  }
  else {
    snprintf(last_msg, sizeof(last_msg), "%s> %s\n", c->name, msg);

    for (int i = 0; i < nclients; i++) {
      fputs(last_msg, clients[i].fd);
      fflush(clients[i].fd);
    }
  }

  return 1;
}

void write_flag(FILE *f) {
  char flag[128];
  FILE *flagfile = fopen("flag", "r");
  fgets(flag, sizeof(flag), flagfile);
  fclose(flagfile);
  fprintf(f, "Congrats! The flag is: %s\n", flag);
}

int main(int argc, char **argv) {
  int sock = socket(AF_INET, SOCK_STREAM | SOCK_NONBLOCK, 0);

  if (sock == -1) {
    perror("failed to open socket");
    exit(1);
  }

  if (setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &(int){ 1 }, sizeof(int)) < 0) {
    perror("setsockopt(SO_REUSEADDR)");
    exit(1);
  }

  struct sockaddr_in local;
  memset(&local, 0, sizeof(local));
  local.sin_family = AF_INET;
  local.sin_port = htons(PORT);
  local.sin_addr.s_addr = htonl(INADDR_ANY);

  if (bind(sock, (struct sockaddr *)&local, sizeof(local)) == -1) {
    perror("failed to bind socket");
    exit(1);
  }

  if (listen(sock, 10) == -1) {
    perror("listen");
    exit(1);
  }

  fd_set rfds;
  int retval;

  while (1) {
    int max = 0, accept = 0;
    FD_ZERO(&rfds);

    if (nclients < MAX_CLIENT) {
      FD_SET(sock, &rfds);
      max = sock;
      accept = 1;
    }

    for (int i = 0; i < nclients; i++) {
      max = (max < clients[i].sock) ? clients[i].sock : max;
      FD_SET(clients[i].sock, &rfds);
    }

    retval = select(1 + max, &rfds, NULL, NULL, NULL);

    if (retval == -1)
      perror("select()");
    else if (retval) {
      for (int i = 0; i < nclients;)
        i += (FD_ISSET(clients[i].sock, &rfds)) ? message_on(&clients[i]) : 1;

      if (accept && FD_ISSET(sock, &rfds))
        accept_on(sock);
    }
  }

  return 0;
}
