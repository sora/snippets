/* lookup3: case 13 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#define rot(x,k) (((x)<<(k)) ^ ((x)>>(32-(k))))

#define final(a,b,c) \
{ \
	c ^= b; c -= rot(b,14); \
	a ^= c; a -= rot(c,11); \
	b ^= a; b -= rot(a,25); \
	c ^= b; c -= rot(b,16); \
	a ^= c; a -= rot(c,4);  \
	b ^= a; b -= rot(a,14); \
	c ^= b; c -= rot(b,24); \
}

void putBinary(unsigned int x)
{
	int i;
	for (i = 0; i < 32; i++, x <<= 1)
		putchar('0' + ((x & 0x80000000) != 0));
	putchar('\n');
}

int main (void) {
	void *key  = "abcdefghijkl";
	int length = strlen((char *)key);
	uint32_t a, b, c;
	const uint32_t *k = key;
	// const uint8_t *k8 = key; // debug

	a = b = c = 0xdeadbeef + length;
	printf("1: a=%X, b=%X, c=%X\n", a, b, c);
	printf("k: k0=%X, k1=%X, k2=%X\n", k[0], k[1], k[2]);
	// printf("k8[1]: %c\n", k8[1]);

	/* case 12: */
	c += k[2];
	b += k[1];
	a += k[0];

	// putBinary(c);
	printf("2: a=%X, b=%X, c=%X\n", a, b, c);
	final(a, b, c);
	printf("3: a=%X, b=%X, c=%X\n", a, b, c);
	printf("key=%s, length=%d\n", (char *)key, length);
	printf("c=%X\n", c);

	return 0;
}

