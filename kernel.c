#include <stddef.h>
#include <stdint.h>


#if defined(__linux__)
#error "Use o cross-compiler i686-elf-gcc, não o gcc do Linux."
#endif

#if !defined(__i386__)
#error "Este kernel precisa ser compilado para i386/i686."
#endif

void kernel_main(void)
{
}