/* Small native shortcut for file managers which treat .desktop as text.
 * Built on the user's Linux/CPU using the existing compiler dependency.
 * No shell interpolation, elevated bits, sockets or networking.
 * Copyright Igor Krauch (github.com/igareck).
 */
#include <stdio.h>
#include <unistd.h>
#include "launcher_config.h"

int main(void)
{
    char *const arguments[] = {
        "/usr/bin/python3", IGARECK_HELPER, "--launch", IGARECK_ACTION, NULL
    };
    execv(arguments[0], arguments);
    perror("Igareck shortcut");
    return 127;
}
