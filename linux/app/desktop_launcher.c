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
        "/usr/bin/python3", AntiDPI_HELPER, "--launch", AntiDPI_ACTION, NULL
    };
    execv(arguments[0], arguments);
    perror("AntiDPI shortcut");
    return 127;
}
