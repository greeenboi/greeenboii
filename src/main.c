#include <stdio.h>
#include "greeenboii.h"

int main(void) {
    // Initialize the Ruby interpreter.
    ruby_init();

    // Call the native extension initialization function.
    // This registers the Ruby module defined in the C extension.
    Init_greeenboii();

    // Your application logic can go here.
    printf("Greeenboii module successfully initialized!\n");

    // Finalize the Ruby interpreter.
    ruby_finalize();

    return 0;
}