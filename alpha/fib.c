#include <stdio.h>

extern unsigned fib(unsigned);

int main(void)
{
	unsigned i;

	for (i=0; i < 20; i++) {
		printf("%u\n", fib(i));
	}

	return 0;
}
