
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 60 19 10 f0 	movl   $0xf0101960,(%esp)
f0100055:	e8 c4 08 00 00       	call   f010091e <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 08 07 00 00       	call   f010078f <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 7c 19 10 f0 	movl   $0xf010197c,(%esp)
f0100092:	e8 87 08 00 00       	call   f010091e <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 8e 13 00 00       	call   f0101453 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 9e 04 00 00       	call   f0100568 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 97 19 10 f0 	movl   $0xf0101997,(%esp)
f01000d9:	e8 40 08 00 00       	call   f010091e <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 a3 06 00 00       	call   f0100799 <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 b2 19 10 f0 	movl   $0xf01019b2,(%esp)
f010012c:	e8 ed 07 00 00       	call   f010091e <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 ae 07 00 00       	call   f01008eb <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 ee 19 10 f0 	movl   $0xf01019ee,(%esp)
f0100144:	e8 d5 07 00 00       	call   f010091e <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 44 06 00 00       	call   f0100799 <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 ca 19 10 f0 	movl   $0xf01019ca,(%esp)
f0100176:	e8 a3 07 00 00       	call   f010091e <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 61 07 00 00       	call   f01008eb <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 ee 19 10 f0 	movl   $0xf01019ee,(%esp)
f0100191:	e8 88 07 00 00       	call   f010091e <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	00 00                	add    %al,(%eax)
	...

f01001a0 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba 84 00 00 00       	mov    $0x84,%edx
f01001a8:	ec                   	in     (%dx),%al
f01001a9:	ec                   	in     (%dx),%al
f01001aa:	ec                   	in     (%dx),%al
f01001ab:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f01001ac:	5d                   	pop    %ebp
f01001ad:	c3                   	ret    

f01001ae <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001ae:	55                   	push   %ebp
f01001af:	89 e5                	mov    %esp,%ebp
f01001b1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001b6:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001b7:	a8 01                	test   $0x1,%al
f01001b9:	74 08                	je     f01001c3 <serial_proc_data+0x15>
f01001bb:	b2 f8                	mov    $0xf8,%dl
f01001bd:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001be:	0f b6 c0             	movzbl %al,%eax
f01001c1:	eb 05                	jmp    f01001c8 <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001c3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001c8:	5d                   	pop    %ebp
f01001c9:	c3                   	ret    

f01001ca <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001ca:	55                   	push   %ebp
f01001cb:	89 e5                	mov    %esp,%ebp
f01001cd:	53                   	push   %ebx
f01001ce:	83 ec 04             	sub    $0x4,%esp
f01001d1:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001d3:	eb 29                	jmp    f01001fe <cons_intr+0x34>
		if (c == 0)
f01001d5:	85 d2                	test   %edx,%edx
f01001d7:	74 25                	je     f01001fe <cons_intr+0x34>
			continue;
		cons.buf[cons.wpos++] = c;
f01001d9:	a1 24 25 11 f0       	mov    0xf0112524,%eax
f01001de:	88 90 20 23 11 f0    	mov    %dl,-0xfeedce0(%eax)
f01001e4:	8d 50 01             	lea    0x1(%eax),%edx
		if (cons.wpos == CONSBUFSIZE)
f01001e7:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.wpos = 0;
f01001ed:	0f 94 c0             	sete   %al
f01001f0:	0f b6 c0             	movzbl %al,%eax
f01001f3:	83 e8 01             	sub    $0x1,%eax
f01001f6:	21 c2                	and    %eax,%edx
f01001f8:	89 15 24 25 11 f0    	mov    %edx,0xf0112524
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001fe:	ff d3                	call   *%ebx
f0100200:	89 c2                	mov    %eax,%edx
f0100202:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100205:	75 ce                	jne    f01001d5 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100207:	83 c4 04             	add    $0x4,%esp
f010020a:	5b                   	pop    %ebx
f010020b:	5d                   	pop    %ebp
f010020c:	c3                   	ret    

f010020d <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010020d:	55                   	push   %ebp
f010020e:	89 e5                	mov    %esp,%ebp
f0100210:	57                   	push   %edi
f0100211:	56                   	push   %esi
f0100212:	53                   	push   %ebx
f0100213:	83 ec 2c             	sub    $0x2c,%esp
f0100216:	89 c7                	mov    %eax,%edi
f0100218:	bb 01 32 00 00       	mov    $0x3201,%ebx
f010021d:	be fd 03 00 00       	mov    $0x3fd,%esi
f0100222:	eb 05                	jmp    f0100229 <cons_putc+0x1c>
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f0100224:	e8 77 ff ff ff       	call   f01001a0 <delay>
f0100229:	89 f2                	mov    %esi,%edx
f010022b:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f010022c:	a8 20                	test   $0x20,%al
f010022e:	75 05                	jne    f0100235 <cons_putc+0x28>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100230:	83 eb 01             	sub    $0x1,%ebx
f0100233:	75 ef                	jne    f0100224 <cons_putc+0x17>
f0100235:	89 fa                	mov    %edi,%edx
f0100237:	89 f8                	mov    %edi,%eax
f0100239:	88 55 e7             	mov    %dl,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010023c:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100241:	ee                   	out    %al,(%dx)
f0100242:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100247:	be 79 03 00 00       	mov    $0x379,%esi
f010024c:	eb 05                	jmp    f0100253 <cons_putc+0x46>
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
		delay();
f010024e:	e8 4d ff ff ff       	call   f01001a0 <delay>
f0100253:	89 f2                	mov    %esi,%edx
f0100255:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100256:	84 c0                	test   %al,%al
f0100258:	78 05                	js     f010025f <cons_putc+0x52>
f010025a:	83 eb 01             	sub    $0x1,%ebx
f010025d:	75 ef                	jne    f010024e <cons_putc+0x41>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010025f:	ba 78 03 00 00       	mov    $0x378,%edx
f0100264:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100268:	ee                   	out    %al,(%dx)
f0100269:	b2 7a                	mov    $0x7a,%dl
f010026b:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100270:	ee                   	out    %al,(%dx)
f0100271:	b8 08 00 00 00       	mov    $0x8,%eax
f0100276:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100277:	f7 c7 00 ff ff ff    	test   $0xffffff00,%edi
f010027d:	75 06                	jne    f0100285 <cons_putc+0x78>
		c |= 0x0700;
f010027f:	81 cf 00 07 00 00    	or     $0x700,%edi

	switch (c & 0xff) {
f0100285:	89 f8                	mov    %edi,%eax
f0100287:	25 ff 00 00 00       	and    $0xff,%eax
f010028c:	83 f8 09             	cmp    $0x9,%eax
f010028f:	74 78                	je     f0100309 <cons_putc+0xfc>
f0100291:	83 f8 09             	cmp    $0x9,%eax
f0100294:	7f 0c                	jg     f01002a2 <cons_putc+0x95>
f0100296:	83 f8 08             	cmp    $0x8,%eax
f0100299:	0f 85 9e 00 00 00    	jne    f010033d <cons_putc+0x130>
f010029f:	90                   	nop
f01002a0:	eb 10                	jmp    f01002b2 <cons_putc+0xa5>
f01002a2:	83 f8 0a             	cmp    $0xa,%eax
f01002a5:	74 3c                	je     f01002e3 <cons_putc+0xd6>
f01002a7:	83 f8 0d             	cmp    $0xd,%eax
f01002aa:	0f 85 8d 00 00 00    	jne    f010033d <cons_putc+0x130>
f01002b0:	eb 39                	jmp    f01002eb <cons_putc+0xde>
	case '\b':
		if (crt_pos > 0) {
f01002b2:	0f b7 05 34 25 11 f0 	movzwl 0xf0112534,%eax
f01002b9:	66 85 c0             	test   %ax,%ax
f01002bc:	0f 84 e5 00 00 00    	je     f01003a7 <cons_putc+0x19a>
			crt_pos--;
f01002c2:	83 e8 01             	sub    $0x1,%eax
f01002c5:	66 a3 34 25 11 f0    	mov    %ax,0xf0112534
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01002cb:	0f b7 c0             	movzwl %ax,%eax
f01002ce:	81 e7 00 ff ff ff    	and    $0xffffff00,%edi
f01002d4:	83 cf 20             	or     $0x20,%edi
f01002d7:	8b 15 30 25 11 f0    	mov    0xf0112530,%edx
f01002dd:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01002e1:	eb 77                	jmp    f010035a <cons_putc+0x14d>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01002e3:	66 83 05 34 25 11 f0 	addw   $0x50,0xf0112534
f01002ea:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01002eb:	0f b7 05 34 25 11 f0 	movzwl 0xf0112534,%eax
f01002f2:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01002f8:	c1 e8 16             	shr    $0x16,%eax
f01002fb:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01002fe:	c1 e0 04             	shl    $0x4,%eax
f0100301:	66 a3 34 25 11 f0    	mov    %ax,0xf0112534
f0100307:	eb 51                	jmp    f010035a <cons_putc+0x14d>
		break;
	case '\t':
		cons_putc(' ');
f0100309:	b8 20 00 00 00       	mov    $0x20,%eax
f010030e:	e8 fa fe ff ff       	call   f010020d <cons_putc>
		cons_putc(' ');
f0100313:	b8 20 00 00 00       	mov    $0x20,%eax
f0100318:	e8 f0 fe ff ff       	call   f010020d <cons_putc>
		cons_putc(' ');
f010031d:	b8 20 00 00 00       	mov    $0x20,%eax
f0100322:	e8 e6 fe ff ff       	call   f010020d <cons_putc>
		cons_putc(' ');
f0100327:	b8 20 00 00 00       	mov    $0x20,%eax
f010032c:	e8 dc fe ff ff       	call   f010020d <cons_putc>
		cons_putc(' ');
f0100331:	b8 20 00 00 00       	mov    $0x20,%eax
f0100336:	e8 d2 fe ff ff       	call   f010020d <cons_putc>
f010033b:	eb 1d                	jmp    f010035a <cons_putc+0x14d>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010033d:	0f b7 05 34 25 11 f0 	movzwl 0xf0112534,%eax
f0100344:	0f b7 c8             	movzwl %ax,%ecx
f0100347:	8b 15 30 25 11 f0    	mov    0xf0112530,%edx
f010034d:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f0100351:	83 c0 01             	add    $0x1,%eax
f0100354:	66 a3 34 25 11 f0    	mov    %ax,0xf0112534
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f010035a:	66 81 3d 34 25 11 f0 	cmpw   $0x7cf,0xf0112534
f0100361:	cf 07 
f0100363:	76 42                	jbe    f01003a7 <cons_putc+0x19a>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100365:	a1 30 25 11 f0       	mov    0xf0112530,%eax
f010036a:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100371:	00 
f0100372:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100378:	89 54 24 04          	mov    %edx,0x4(%esp)
f010037c:	89 04 24             	mov    %eax,(%esp)
f010037f:	e8 2d 11 00 00       	call   f01014b1 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100384:	8b 15 30 25 11 f0    	mov    0xf0112530,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010038a:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f010038f:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100395:	83 c0 01             	add    $0x1,%eax
f0100398:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f010039d:	75 f0                	jne    f010038f <cons_putc+0x182>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010039f:	66 83 2d 34 25 11 f0 	subw   $0x50,0xf0112534
f01003a6:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01003a7:	8b 0d 2c 25 11 f0    	mov    0xf011252c,%ecx
f01003ad:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003b2:	89 ca                	mov    %ecx,%edx
f01003b4:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003b5:	0f b7 1d 34 25 11 f0 	movzwl 0xf0112534,%ebx
f01003bc:	8d 71 01             	lea    0x1(%ecx),%esi
f01003bf:	89 d8                	mov    %ebx,%eax
f01003c1:	66 c1 e8 08          	shr    $0x8,%ax
f01003c5:	89 f2                	mov    %esi,%edx
f01003c7:	ee                   	out    %al,(%dx)
f01003c8:	b8 0f 00 00 00       	mov    $0xf,%eax
f01003cd:	89 ca                	mov    %ecx,%edx
f01003cf:	ee                   	out    %al,(%dx)
f01003d0:	89 d8                	mov    %ebx,%eax
f01003d2:	89 f2                	mov    %esi,%edx
f01003d4:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01003d5:	83 c4 2c             	add    $0x2c,%esp
f01003d8:	5b                   	pop    %ebx
f01003d9:	5e                   	pop    %esi
f01003da:	5f                   	pop    %edi
f01003db:	5d                   	pop    %ebp
f01003dc:	c3                   	ret    

f01003dd <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01003dd:	55                   	push   %ebp
f01003de:	89 e5                	mov    %esp,%ebp
f01003e0:	53                   	push   %ebx
f01003e1:	83 ec 14             	sub    $0x14,%esp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003e4:	ba 64 00 00 00       	mov    $0x64,%edx
f01003e9:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f01003ea:	a8 01                	test   $0x1,%al
f01003ec:	0f 84 ec 00 00 00    	je     f01004de <kbd_proc_data+0x101>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f01003f2:	a8 20                	test   $0x20,%al
f01003f4:	0f 85 eb 00 00 00    	jne    f01004e5 <kbd_proc_data+0x108>
f01003fa:	b2 60                	mov    $0x60,%dl
f01003fc:	ec                   	in     (%dx),%al
f01003fd:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01003ff:	3c e0                	cmp    $0xe0,%al
f0100401:	75 11                	jne    f0100414 <kbd_proc_data+0x37>
		// E0 escape character
		shift |= E0ESC;
f0100403:	83 0d 28 25 11 f0 40 	orl    $0x40,0xf0112528
		return 0;
f010040a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010040f:	e9 d6 00 00 00       	jmp    f01004ea <kbd_proc_data+0x10d>
	} else if (data & 0x80) {
f0100414:	84 c0                	test   %al,%al
f0100416:	79 34                	jns    f010044c <kbd_proc_data+0x6f>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100418:	8b 0d 28 25 11 f0    	mov    0xf0112528,%ecx
f010041e:	f6 c1 40             	test   $0x40,%cl
f0100421:	75 05                	jne    f0100428 <kbd_proc_data+0x4b>
f0100423:	89 c2                	mov    %eax,%edx
f0100425:	83 e2 7f             	and    $0x7f,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100428:	0f b6 d2             	movzbl %dl,%edx
f010042b:	0f b6 82 20 1a 10 f0 	movzbl -0xfefe5e0(%edx),%eax
f0100432:	83 c8 40             	or     $0x40,%eax
f0100435:	0f b6 c0             	movzbl %al,%eax
f0100438:	f7 d0                	not    %eax
f010043a:	21 c1                	and    %eax,%ecx
f010043c:	89 0d 28 25 11 f0    	mov    %ecx,0xf0112528
		return 0;
f0100442:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100447:	e9 9e 00 00 00       	jmp    f01004ea <kbd_proc_data+0x10d>
	} else if (shift & E0ESC) {
f010044c:	8b 0d 28 25 11 f0    	mov    0xf0112528,%ecx
f0100452:	f6 c1 40             	test   $0x40,%cl
f0100455:	74 0e                	je     f0100465 <kbd_proc_data+0x88>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100457:	89 c2                	mov    %eax,%edx
f0100459:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f010045c:	83 e1 bf             	and    $0xffffffbf,%ecx
f010045f:	89 0d 28 25 11 f0    	mov    %ecx,0xf0112528
	}

	shift |= shiftcode[data];
f0100465:	0f b6 c2             	movzbl %dl,%eax
f0100468:	0f b6 90 20 1a 10 f0 	movzbl -0xfefe5e0(%eax),%edx
f010046f:	0b 15 28 25 11 f0    	or     0xf0112528,%edx
	shift ^= togglecode[data];
f0100475:	0f b6 88 20 1b 10 f0 	movzbl -0xfefe4e0(%eax),%ecx
f010047c:	31 ca                	xor    %ecx,%edx
f010047e:	89 15 28 25 11 f0    	mov    %edx,0xf0112528

	c = charcode[shift & (CTL | SHIFT)][data];
f0100484:	89 d1                	mov    %edx,%ecx
f0100486:	83 e1 03             	and    $0x3,%ecx
f0100489:	8b 0c 8d 20 1c 10 f0 	mov    -0xfefe3e0(,%ecx,4),%ecx
f0100490:	0f b6 04 01          	movzbl (%ecx,%eax,1),%eax
f0100494:	0f b6 d8             	movzbl %al,%ebx
	if (shift & CAPSLOCK) {
f0100497:	f6 c2 08             	test   $0x8,%dl
f010049a:	74 1a                	je     f01004b6 <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f010049c:	89 d8                	mov    %ebx,%eax
f010049e:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01004a1:	83 f9 19             	cmp    $0x19,%ecx
f01004a4:	77 05                	ja     f01004ab <kbd_proc_data+0xce>
			c += 'A' - 'a';
f01004a6:	83 eb 20             	sub    $0x20,%ebx
f01004a9:	eb 0b                	jmp    f01004b6 <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f01004ab:	83 e8 41             	sub    $0x41,%eax
f01004ae:	83 f8 19             	cmp    $0x19,%eax
f01004b1:	77 03                	ja     f01004b6 <kbd_proc_data+0xd9>
			c += 'a' - 'A';
f01004b3:	83 c3 20             	add    $0x20,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01004b6:	f7 d2                	not    %edx
f01004b8:	f6 c2 06             	test   $0x6,%dl
f01004bb:	75 2d                	jne    f01004ea <kbd_proc_data+0x10d>
f01004bd:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01004c3:	75 25                	jne    f01004ea <kbd_proc_data+0x10d>
		cprintf("Rebooting!\n");
f01004c5:	c7 04 24 e4 19 10 f0 	movl   $0xf01019e4,(%esp)
f01004cc:	e8 4d 04 00 00       	call   f010091e <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01004d1:	ba 92 00 00 00       	mov    $0x92,%edx
f01004d6:	b8 03 00 00 00       	mov    $0x3,%eax
f01004db:	ee                   	out    %al,(%dx)
f01004dc:	eb 0c                	jmp    f01004ea <kbd_proc_data+0x10d>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f01004de:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f01004e3:	eb 05                	jmp    f01004ea <kbd_proc_data+0x10d>
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f01004e5:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01004ea:	89 d8                	mov    %ebx,%eax
f01004ec:	83 c4 14             	add    $0x14,%esp
f01004ef:	5b                   	pop    %ebx
f01004f0:	5d                   	pop    %ebp
f01004f1:	c3                   	ret    

f01004f2 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004f2:	80 3d 00 23 11 f0 00 	cmpb   $0x0,0xf0112300
f01004f9:	74 11                	je     f010050c <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004fb:	55                   	push   %ebp
f01004fc:	89 e5                	mov    %esp,%ebp
f01004fe:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100501:	b8 ae 01 10 f0       	mov    $0xf01001ae,%eax
f0100506:	e8 bf fc ff ff       	call   f01001ca <cons_intr>
}
f010050b:	c9                   	leave  
f010050c:	f3 c3                	repz ret 

f010050e <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010050e:	55                   	push   %ebp
f010050f:	89 e5                	mov    %esp,%ebp
f0100511:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100514:	b8 dd 03 10 f0       	mov    $0xf01003dd,%eax
f0100519:	e8 ac fc ff ff       	call   f01001ca <cons_intr>
}
f010051e:	c9                   	leave  
f010051f:	c3                   	ret    

f0100520 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100520:	55                   	push   %ebp
f0100521:	89 e5                	mov    %esp,%ebp
f0100523:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100526:	e8 c7 ff ff ff       	call   f01004f2 <serial_intr>
	kbd_intr();
f010052b:	e8 de ff ff ff       	call   f010050e <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100530:	8b 15 20 25 11 f0    	mov    0xf0112520,%edx
f0100536:	3b 15 24 25 11 f0    	cmp    0xf0112524,%edx
f010053c:	74 23                	je     f0100561 <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f010053e:	0f b6 82 20 23 11 f0 	movzbl -0xfeedce0(%edx),%eax
f0100545:	83 c2 01             	add    $0x1,%edx
f0100548:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010054e:	0f 94 c1             	sete   %cl
f0100551:	0f b6 c9             	movzbl %cl,%ecx
f0100554:	83 e9 01             	sub    $0x1,%ecx
f0100557:	21 ca                	and    %ecx,%edx
f0100559:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f010055f:	eb 05                	jmp    f0100566 <cons_getc+0x46>
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f0100561:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100566:	c9                   	leave  
f0100567:	c3                   	ret    

f0100568 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100568:	55                   	push   %ebp
f0100569:	89 e5                	mov    %esp,%ebp
f010056b:	57                   	push   %edi
f010056c:	56                   	push   %esi
f010056d:	53                   	push   %ebx
f010056e:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100571:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100578:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010057f:	5a a5 
	if (*cp != 0xA55A) {
f0100581:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100588:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010058c:	74 11                	je     f010059f <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010058e:	c7 05 2c 25 11 f0 b4 	movl   $0x3b4,0xf011252c
f0100595:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100598:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f010059d:	eb 16                	jmp    f01005b5 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010059f:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005a6:	c7 05 2c 25 11 f0 d4 	movl   $0x3d4,0xf011252c
f01005ad:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005b0:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005b5:	8b 0d 2c 25 11 f0    	mov    0xf011252c,%ecx
f01005bb:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005c0:	89 ca                	mov    %ecx,%edx
f01005c2:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005c3:	8d 59 01             	lea    0x1(%ecx),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005c6:	89 da                	mov    %ebx,%edx
f01005c8:	ec                   	in     (%dx),%al
f01005c9:	0f b6 f0             	movzbl %al,%esi
f01005cc:	c1 e6 08             	shl    $0x8,%esi
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005cf:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005d4:	89 ca                	mov    %ecx,%edx
f01005d6:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005d7:	89 da                	mov    %ebx,%edx
f01005d9:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005da:	89 3d 30 25 11 f0    	mov    %edi,0xf0112530

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005e0:	0f b6 d8             	movzbl %al,%ebx
f01005e3:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005e5:	66 89 35 34 25 11 f0 	mov    %si,0xf0112534
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005ec:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005f1:	b8 00 00 00 00       	mov    $0x0,%eax
f01005f6:	89 f2                	mov    %esi,%edx
f01005f8:	ee                   	out    %al,(%dx)
f01005f9:	b2 fb                	mov    $0xfb,%dl
f01005fb:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100600:	ee                   	out    %al,(%dx)
f0100601:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100606:	b8 0c 00 00 00       	mov    $0xc,%eax
f010060b:	89 da                	mov    %ebx,%edx
f010060d:	ee                   	out    %al,(%dx)
f010060e:	b2 f9                	mov    $0xf9,%dl
f0100610:	b8 00 00 00 00       	mov    $0x0,%eax
f0100615:	ee                   	out    %al,(%dx)
f0100616:	b2 fb                	mov    $0xfb,%dl
f0100618:	b8 03 00 00 00       	mov    $0x3,%eax
f010061d:	ee                   	out    %al,(%dx)
f010061e:	b2 fc                	mov    $0xfc,%dl
f0100620:	b8 00 00 00 00       	mov    $0x0,%eax
f0100625:	ee                   	out    %al,(%dx)
f0100626:	b2 f9                	mov    $0xf9,%dl
f0100628:	b8 01 00 00 00       	mov    $0x1,%eax
f010062d:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010062e:	b2 fd                	mov    $0xfd,%dl
f0100630:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100631:	3c ff                	cmp    $0xff,%al
f0100633:	0f 95 c1             	setne  %cl
f0100636:	88 0d 00 23 11 f0    	mov    %cl,0xf0112300
f010063c:	89 f2                	mov    %esi,%edx
f010063e:	ec                   	in     (%dx),%al
f010063f:	89 da                	mov    %ebx,%edx
f0100641:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100642:	84 c9                	test   %cl,%cl
f0100644:	75 0c                	jne    f0100652 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f0100646:	c7 04 24 f0 19 10 f0 	movl   $0xf01019f0,(%esp)
f010064d:	e8 cc 02 00 00       	call   f010091e <cprintf>
}
f0100652:	83 c4 1c             	add    $0x1c,%esp
f0100655:	5b                   	pop    %ebx
f0100656:	5e                   	pop    %esi
f0100657:	5f                   	pop    %edi
f0100658:	5d                   	pop    %ebp
f0100659:	c3                   	ret    

f010065a <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010065a:	55                   	push   %ebp
f010065b:	89 e5                	mov    %esp,%ebp
f010065d:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100660:	8b 45 08             	mov    0x8(%ebp),%eax
f0100663:	e8 a5 fb ff ff       	call   f010020d <cons_putc>
}
f0100668:	c9                   	leave  
f0100669:	c3                   	ret    

f010066a <getchar>:

int
getchar(void)
{
f010066a:	55                   	push   %ebp
f010066b:	89 e5                	mov    %esp,%ebp
f010066d:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100670:	e8 ab fe ff ff       	call   f0100520 <cons_getc>
f0100675:	85 c0                	test   %eax,%eax
f0100677:	74 f7                	je     f0100670 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100679:	c9                   	leave  
f010067a:	c3                   	ret    

f010067b <iscons>:

int
iscons(int fdnum)
{
f010067b:	55                   	push   %ebp
f010067c:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010067e:	b8 01 00 00 00       	mov    $0x1,%eax
f0100683:	5d                   	pop    %ebp
f0100684:	c3                   	ret    
	...

f0100690 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100690:	55                   	push   %ebp
f0100691:	89 e5                	mov    %esp,%ebp
f0100693:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100696:	c7 04 24 30 1c 10 f0 	movl   $0xf0101c30,(%esp)
f010069d:	e8 7c 02 00 00       	call   f010091e <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006a2:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006a9:	00 
f01006aa:	c7 04 24 bc 1c 10 f0 	movl   $0xf0101cbc,(%esp)
f01006b1:	e8 68 02 00 00       	call   f010091e <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006b6:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006bd:	00 
f01006be:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006c5:	f0 
f01006c6:	c7 04 24 e4 1c 10 f0 	movl   $0xf0101ce4,(%esp)
f01006cd:	e8 4c 02 00 00       	call   f010091e <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006d2:	c7 44 24 08 5d 19 10 	movl   $0x10195d,0x8(%esp)
f01006d9:	00 
f01006da:	c7 44 24 04 5d 19 10 	movl   $0xf010195d,0x4(%esp)
f01006e1:	f0 
f01006e2:	c7 04 24 08 1d 10 f0 	movl   $0xf0101d08,(%esp)
f01006e9:	e8 30 02 00 00       	call   f010091e <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ee:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f01006f5:	00 
f01006f6:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f01006fd:	f0 
f01006fe:	c7 04 24 2c 1d 10 f0 	movl   $0xf0101d2c,(%esp)
f0100705:	e8 14 02 00 00       	call   f010091e <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010070a:	c7 44 24 08 44 29 11 	movl   $0x112944,0x8(%esp)
f0100711:	00 
f0100712:	c7 44 24 04 44 29 11 	movl   $0xf0112944,0x4(%esp)
f0100719:	f0 
f010071a:	c7 04 24 50 1d 10 f0 	movl   $0xf0101d50,(%esp)
f0100721:	e8 f8 01 00 00       	call   f010091e <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100726:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f010072b:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100730:	c1 f8 0a             	sar    $0xa,%eax
f0100733:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100737:	c7 04 24 74 1d 10 f0 	movl   $0xf0101d74,(%esp)
f010073e:	e8 db 01 00 00       	call   f010091e <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100743:	b8 00 00 00 00       	mov    $0x0,%eax
f0100748:	c9                   	leave  
f0100749:	c3                   	ret    

f010074a <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010074a:	55                   	push   %ebp
f010074b:	89 e5                	mov    %esp,%ebp
f010074d:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100750:	c7 44 24 08 49 1c 10 	movl   $0xf0101c49,0x8(%esp)
f0100757:	f0 
f0100758:	c7 44 24 04 67 1c 10 	movl   $0xf0101c67,0x4(%esp)
f010075f:	f0 
f0100760:	c7 04 24 6c 1c 10 f0 	movl   $0xf0101c6c,(%esp)
f0100767:	e8 b2 01 00 00       	call   f010091e <cprintf>
f010076c:	c7 44 24 08 a0 1d 10 	movl   $0xf0101da0,0x8(%esp)
f0100773:	f0 
f0100774:	c7 44 24 04 75 1c 10 	movl   $0xf0101c75,0x4(%esp)
f010077b:	f0 
f010077c:	c7 04 24 6c 1c 10 f0 	movl   $0xf0101c6c,(%esp)
f0100783:	e8 96 01 00 00       	call   f010091e <cprintf>
	return 0;
}
f0100788:	b8 00 00 00 00       	mov    $0x0,%eax
f010078d:	c9                   	leave  
f010078e:	c3                   	ret    

f010078f <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010078f:	55                   	push   %ebp
f0100790:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f0100792:	b8 00 00 00 00       	mov    $0x0,%eax
f0100797:	5d                   	pop    %ebp
f0100798:	c3                   	ret    

f0100799 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100799:	55                   	push   %ebp
f010079a:	89 e5                	mov    %esp,%ebp
f010079c:	57                   	push   %edi
f010079d:	56                   	push   %esi
f010079e:	53                   	push   %ebx
f010079f:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007a2:	c7 04 24 c8 1d 10 f0 	movl   $0xf0101dc8,(%esp)
f01007a9:	e8 70 01 00 00       	call   f010091e <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007ae:	c7 04 24 ec 1d 10 f0 	movl   $0xf0101dec,(%esp)
f01007b5:	e8 64 01 00 00       	call   f010091e <cprintf>
	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
f01007ba:	8d 7d a8             	lea    -0x58(%ebp),%edi
	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");


	while (1) {
		buf = readline("K> ");
f01007bd:	c7 04 24 7e 1c 10 f0 	movl   $0xf0101c7e,(%esp)
f01007c4:	e8 37 0a 00 00       	call   f0101200 <readline>
f01007c9:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007cb:	85 c0                	test   %eax,%eax
f01007cd:	74 ee                	je     f01007bd <monitor+0x24>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007cf:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007d6:	be 00 00 00 00       	mov    $0x0,%esi
f01007db:	eb 06                	jmp    f01007e3 <monitor+0x4a>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007dd:	c6 03 00             	movb   $0x0,(%ebx)
f01007e0:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007e3:	0f b6 03             	movzbl (%ebx),%eax
f01007e6:	84 c0                	test   %al,%al
f01007e8:	74 63                	je     f010084d <monitor+0xb4>
f01007ea:	0f be c0             	movsbl %al,%eax
f01007ed:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007f1:	c7 04 24 82 1c 10 f0 	movl   $0xf0101c82,(%esp)
f01007f8:	e8 19 0c 00 00       	call   f0101416 <strchr>
f01007fd:	85 c0                	test   %eax,%eax
f01007ff:	75 dc                	jne    f01007dd <monitor+0x44>
			*buf++ = 0;
		if (*buf == 0)
f0100801:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100804:	74 47                	je     f010084d <monitor+0xb4>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100806:	83 fe 0f             	cmp    $0xf,%esi
f0100809:	75 16                	jne    f0100821 <monitor+0x88>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010080b:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100812:	00 
f0100813:	c7 04 24 87 1c 10 f0 	movl   $0xf0101c87,(%esp)
f010081a:	e8 ff 00 00 00       	call   f010091e <cprintf>
f010081f:	eb 9c                	jmp    f01007bd <monitor+0x24>
			return 0;
		}
		argv[argc++] = buf;
f0100821:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100825:	83 c6 01             	add    $0x1,%esi
f0100828:	eb 03                	jmp    f010082d <monitor+0x94>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010082a:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010082d:	0f b6 03             	movzbl (%ebx),%eax
f0100830:	84 c0                	test   %al,%al
f0100832:	74 af                	je     f01007e3 <monitor+0x4a>
f0100834:	0f be c0             	movsbl %al,%eax
f0100837:	89 44 24 04          	mov    %eax,0x4(%esp)
f010083b:	c7 04 24 82 1c 10 f0 	movl   $0xf0101c82,(%esp)
f0100842:	e8 cf 0b 00 00       	call   f0101416 <strchr>
f0100847:	85 c0                	test   %eax,%eax
f0100849:	74 df                	je     f010082a <monitor+0x91>
f010084b:	eb 96                	jmp    f01007e3 <monitor+0x4a>
			buf++;
	}
	argv[argc] = 0;
f010084d:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100854:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100855:	85 f6                	test   %esi,%esi
f0100857:	0f 84 60 ff ff ff    	je     f01007bd <monitor+0x24>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010085d:	c7 44 24 04 67 1c 10 	movl   $0xf0101c67,0x4(%esp)
f0100864:	f0 
f0100865:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100868:	89 04 24             	mov    %eax,(%esp)
f010086b:	e8 48 0b 00 00       	call   f01013b8 <strcmp>
f0100870:	85 c0                	test   %eax,%eax
f0100872:	74 1b                	je     f010088f <monitor+0xf6>
f0100874:	c7 44 24 04 75 1c 10 	movl   $0xf0101c75,0x4(%esp)
f010087b:	f0 
f010087c:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010087f:	89 04 24             	mov    %eax,(%esp)
f0100882:	e8 31 0b 00 00       	call   f01013b8 <strcmp>
f0100887:	85 c0                	test   %eax,%eax
f0100889:	75 2c                	jne    f01008b7 <monitor+0x11e>
f010088b:	b0 01                	mov    $0x1,%al
f010088d:	eb 05                	jmp    f0100894 <monitor+0xfb>
f010088f:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f0100894:	8d 14 00             	lea    (%eax,%eax,1),%edx
f0100897:	01 d0                	add    %edx,%eax
f0100899:	8b 55 08             	mov    0x8(%ebp),%edx
f010089c:	89 54 24 08          	mov    %edx,0x8(%esp)
f01008a0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01008a4:	89 34 24             	mov    %esi,(%esp)
f01008a7:	ff 14 85 1c 1e 10 f0 	call   *-0xfefe1e4(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008ae:	85 c0                	test   %eax,%eax
f01008b0:	78 1d                	js     f01008cf <monitor+0x136>
f01008b2:	e9 06 ff ff ff       	jmp    f01007bd <monitor+0x24>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008b7:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008ba:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008be:	c7 04 24 a4 1c 10 f0 	movl   $0xf0101ca4,(%esp)
f01008c5:	e8 54 00 00 00       	call   f010091e <cprintf>
f01008ca:	e9 ee fe ff ff       	jmp    f01007bd <monitor+0x24>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008cf:	83 c4 5c             	add    $0x5c,%esp
f01008d2:	5b                   	pop    %ebx
f01008d3:	5e                   	pop    %esi
f01008d4:	5f                   	pop    %edi
f01008d5:	5d                   	pop    %ebp
f01008d6:	c3                   	ret    
	...

f01008d8 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01008d8:	55                   	push   %ebp
f01008d9:	89 e5                	mov    %esp,%ebp
f01008db:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01008de:	8b 45 08             	mov    0x8(%ebp),%eax
f01008e1:	89 04 24             	mov    %eax,(%esp)
f01008e4:	e8 71 fd ff ff       	call   f010065a <cputchar>
	*cnt++;
}
f01008e9:	c9                   	leave  
f01008ea:	c3                   	ret    

f01008eb <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01008eb:	55                   	push   %ebp
f01008ec:	89 e5                	mov    %esp,%ebp
f01008ee:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01008f1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01008f8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01008fb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01008ff:	8b 45 08             	mov    0x8(%ebp),%eax
f0100902:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100906:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100909:	89 44 24 04          	mov    %eax,0x4(%esp)
f010090d:	c7 04 24 d8 08 10 f0 	movl   $0xf01008d8,(%esp)
f0100914:	e8 4c 04 00 00       	call   f0100d65 <vprintfmt>
	return cnt;
}
f0100919:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010091c:	c9                   	leave  
f010091d:	c3                   	ret    

f010091e <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010091e:	55                   	push   %ebp
f010091f:	89 e5                	mov    %esp,%ebp
f0100921:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100924:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100927:	89 44 24 04          	mov    %eax,0x4(%esp)
f010092b:	8b 45 08             	mov    0x8(%ebp),%eax
f010092e:	89 04 24             	mov    %eax,(%esp)
f0100931:	e8 b5 ff ff ff       	call   f01008eb <vcprintf>
	va_end(ap);

	return cnt;
}
f0100936:	c9                   	leave  
f0100937:	c3                   	ret    

f0100938 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100938:	55                   	push   %ebp
f0100939:	89 e5                	mov    %esp,%ebp
f010093b:	57                   	push   %edi
f010093c:	56                   	push   %esi
f010093d:	53                   	push   %ebx
f010093e:	83 ec 10             	sub    $0x10,%esp
f0100941:	89 c6                	mov    %eax,%esi
f0100943:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100946:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100949:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f010094c:	8b 1a                	mov    (%edx),%ebx
f010094e:	8b 09                	mov    (%ecx),%ecx
f0100950:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0100953:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f010095a:	eb 77                	jmp    f01009d3 <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f010095c:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010095f:	01 d8                	add    %ebx,%eax
f0100961:	b9 02 00 00 00       	mov    $0x2,%ecx
f0100966:	99                   	cltd   
f0100967:	f7 f9                	idiv   %ecx
f0100969:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010096b:	eb 01                	jmp    f010096e <stab_binsearch+0x36>
			m--;
f010096d:	49                   	dec    %ecx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010096e:	39 d9                	cmp    %ebx,%ecx
f0100970:	7c 1d                	jl     f010098f <stab_binsearch+0x57>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100972:	6b d1 0c             	imul   $0xc,%ecx,%edx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100975:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f010097a:	39 fa                	cmp    %edi,%edx
f010097c:	75 ef                	jne    f010096d <stab_binsearch+0x35>
f010097e:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100981:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100984:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0100988:	3b 55 0c             	cmp    0xc(%ebp),%edx
f010098b:	73 18                	jae    f01009a5 <stab_binsearch+0x6d>
f010098d:	eb 05                	jmp    f0100994 <stab_binsearch+0x5c>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f010098f:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0100992:	eb 3f                	jmp    f01009d3 <stab_binsearch+0x9b>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100994:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100997:	89 0a                	mov    %ecx,(%edx)
			l = true_m + 1;
f0100999:	8d 58 01             	lea    0x1(%eax),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010099c:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f01009a3:	eb 2e                	jmp    f01009d3 <stab_binsearch+0x9b>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01009a5:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01009a8:	73 15                	jae    f01009bf <stab_binsearch+0x87>
			*region_right = m - 1;
f01009aa:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01009ad:	49                   	dec    %ecx
f01009ae:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01009b1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01009b4:	89 08                	mov    %ecx,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009b6:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f01009bd:	eb 14                	jmp    f01009d3 <stab_binsearch+0x9b>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01009bf:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01009c2:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01009c5:	89 02                	mov    %eax,(%edx)
			l = m;
			addr++;
f01009c7:	ff 45 0c             	incl   0xc(%ebp)
f01009ca:	89 cb                	mov    %ecx,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01009cc:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01009d3:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01009d6:	7e 84                	jle    f010095c <stab_binsearch+0x24>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01009d8:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f01009dc:	75 0d                	jne    f01009eb <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f01009de:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01009e1:	8b 02                	mov    (%edx),%eax
f01009e3:	48                   	dec    %eax
f01009e4:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01009e7:	89 01                	mov    %eax,(%ecx)
f01009e9:	eb 22                	jmp    f0100a0d <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009eb:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01009ee:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f01009f0:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01009f3:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009f5:	eb 01                	jmp    f01009f8 <stab_binsearch+0xc0>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01009f7:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01009f8:	39 c1                	cmp    %eax,%ecx
f01009fa:	7d 0c                	jge    f0100a08 <stab_binsearch+0xd0>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f01009fc:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f01009ff:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a04:	39 fa                	cmp    %edi,%edx
f0100a06:	75 ef                	jne    f01009f7 <stab_binsearch+0xbf>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100a08:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100a0b:	89 02                	mov    %eax,(%edx)
	}
}
f0100a0d:	83 c4 10             	add    $0x10,%esp
f0100a10:	5b                   	pop    %ebx
f0100a11:	5e                   	pop    %esi
f0100a12:	5f                   	pop    %edi
f0100a13:	5d                   	pop    %ebp
f0100a14:	c3                   	ret    

f0100a15 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100a15:	55                   	push   %ebp
f0100a16:	89 e5                	mov    %esp,%ebp
f0100a18:	83 ec 38             	sub    $0x38,%esp
f0100a1b:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100a1e:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100a21:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100a24:	8b 75 08             	mov    0x8(%ebp),%esi
f0100a27:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100a2a:	c7 03 2c 1e 10 f0    	movl   $0xf0101e2c,(%ebx)
	info->eip_line = 0;
f0100a30:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100a37:	c7 43 08 2c 1e 10 f0 	movl   $0xf0101e2c,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100a3e:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100a45:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100a48:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100a4f:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100a55:	76 12                	jbe    f0100a69 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a57:	b8 86 74 10 f0       	mov    $0xf0107486,%eax
f0100a5c:	3d 69 5b 10 f0       	cmp    $0xf0105b69,%eax
f0100a61:	0f 86 6b 01 00 00    	jbe    f0100bd2 <debuginfo_eip+0x1bd>
f0100a67:	eb 1c                	jmp    f0100a85 <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100a69:	c7 44 24 08 36 1e 10 	movl   $0xf0101e36,0x8(%esp)
f0100a70:	f0 
f0100a71:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100a78:	00 
f0100a79:	c7 04 24 43 1e 10 f0 	movl   $0xf0101e43,(%esp)
f0100a80:	e8 73 f6 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100a85:	80 3d 85 74 10 f0 00 	cmpb   $0x0,0xf0107485
f0100a8c:	0f 85 47 01 00 00    	jne    f0100bd9 <debuginfo_eip+0x1c4>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100a92:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100a99:	b8 68 5b 10 f0       	mov    $0xf0105b68,%eax
f0100a9e:	2d 64 20 10 f0       	sub    $0xf0102064,%eax
f0100aa3:	c1 f8 02             	sar    $0x2,%eax
f0100aa6:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100aac:	83 e8 01             	sub    $0x1,%eax
f0100aaf:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100ab2:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100ab6:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100abd:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100ac0:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100ac3:	b8 64 20 10 f0       	mov    $0xf0102064,%eax
f0100ac8:	e8 6b fe ff ff       	call   f0100938 <stab_binsearch>
	if (lfile == 0)
f0100acd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ad0:	85 c0                	test   %eax,%eax
f0100ad2:	0f 84 08 01 00 00    	je     f0100be0 <debuginfo_eip+0x1cb>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100ad8:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100adb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ade:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100ae1:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100ae5:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100aec:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100aef:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100af2:	b8 64 20 10 f0       	mov    $0xf0102064,%eax
f0100af7:	e8 3c fe ff ff       	call   f0100938 <stab_binsearch>

	if (lfun <= rfun) {
f0100afc:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100aff:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0100b02:	7f 2e                	jg     f0100b32 <debuginfo_eip+0x11d>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100b04:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100b07:	8d 90 64 20 10 f0    	lea    -0xfefdf9c(%eax),%edx
f0100b0d:	8b 80 64 20 10 f0    	mov    -0xfefdf9c(%eax),%eax
f0100b13:	b9 86 74 10 f0       	mov    $0xf0107486,%ecx
f0100b18:	81 e9 69 5b 10 f0    	sub    $0xf0105b69,%ecx
f0100b1e:	39 c8                	cmp    %ecx,%eax
f0100b20:	73 08                	jae    f0100b2a <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100b22:	05 69 5b 10 f0       	add    $0xf0105b69,%eax
f0100b27:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100b2a:	8b 42 08             	mov    0x8(%edx),%eax
f0100b2d:	89 43 10             	mov    %eax,0x10(%ebx)
f0100b30:	eb 06                	jmp    f0100b38 <debuginfo_eip+0x123>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100b32:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100b35:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100b38:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100b3f:	00 
f0100b40:	8b 43 08             	mov    0x8(%ebx),%eax
f0100b43:	89 04 24             	mov    %eax,(%esp)
f0100b46:	e8 ec 08 00 00       	call   f0101437 <strfind>
f0100b4b:	2b 43 08             	sub    0x8(%ebx),%eax
f0100b4e:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b51:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0100b54:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100b57:	05 64 20 10 f0       	add    $0xf0102064,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b5c:	eb 06                	jmp    f0100b64 <debuginfo_eip+0x14f>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100b5e:	83 ef 01             	sub    $0x1,%edi
f0100b61:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100b64:	39 cf                	cmp    %ecx,%edi
f0100b66:	7c 33                	jl     f0100b9b <debuginfo_eip+0x186>
	       && stabs[lline].n_type != N_SOL
f0100b68:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0100b6c:	80 fa 84             	cmp    $0x84,%dl
f0100b6f:	74 0b                	je     f0100b7c <debuginfo_eip+0x167>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100b71:	80 fa 64             	cmp    $0x64,%dl
f0100b74:	75 e8                	jne    f0100b5e <debuginfo_eip+0x149>
f0100b76:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100b7a:	74 e2                	je     f0100b5e <debuginfo_eip+0x149>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100b7c:	6b ff 0c             	imul   $0xc,%edi,%edi
f0100b7f:	8b 87 64 20 10 f0    	mov    -0xfefdf9c(%edi),%eax
f0100b85:	ba 86 74 10 f0       	mov    $0xf0107486,%edx
f0100b8a:	81 ea 69 5b 10 f0    	sub    $0xf0105b69,%edx
f0100b90:	39 d0                	cmp    %edx,%eax
f0100b92:	73 07                	jae    f0100b9b <debuginfo_eip+0x186>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100b94:	05 69 5b 10 f0       	add    $0xf0105b69,%eax
f0100b99:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100b9b:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100b9e:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100ba1:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100ba6:	39 f1                	cmp    %esi,%ecx
f0100ba8:	7d 42                	jge    f0100bec <debuginfo_eip+0x1d7>
		for (lline = lfun + 1;
f0100baa:	8d 51 01             	lea    0x1(%ecx),%edx
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0100bad:	6b c1 0c             	imul   $0xc,%ecx,%eax
f0100bb0:	05 64 20 10 f0       	add    $0xf0102064,%eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100bb5:	eb 07                	jmp    f0100bbe <debuginfo_eip+0x1a9>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0100bb7:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100bbb:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100bbe:	39 f2                	cmp    %esi,%edx
f0100bc0:	74 25                	je     f0100be7 <debuginfo_eip+0x1d2>
f0100bc2:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100bc5:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0100bc9:	74 ec                	je     f0100bb7 <debuginfo_eip+0x1a2>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100bcb:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bd0:	eb 1a                	jmp    f0100bec <debuginfo_eip+0x1d7>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100bd2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bd7:	eb 13                	jmp    f0100bec <debuginfo_eip+0x1d7>
f0100bd9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100bde:	eb 0c                	jmp    f0100bec <debuginfo_eip+0x1d7>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0100be0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100be5:	eb 05                	jmp    f0100bec <debuginfo_eip+0x1d7>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100be7:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100bec:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100bef:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100bf2:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100bf5:	89 ec                	mov    %ebp,%esp
f0100bf7:	5d                   	pop    %ebp
f0100bf8:	c3                   	ret    
f0100bf9:	00 00                	add    %al,(%eax)
f0100bfb:	00 00                	add    %al,(%eax)
f0100bfd:	00 00                	add    %al,(%eax)
	...

f0100c00 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100c00:	55                   	push   %ebp
f0100c01:	89 e5                	mov    %esp,%ebp
f0100c03:	57                   	push   %edi
f0100c04:	56                   	push   %esi
f0100c05:	53                   	push   %ebx
f0100c06:	83 ec 4c             	sub    $0x4c,%esp
f0100c09:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100c0c:	89 d7                	mov    %edx,%edi
f0100c0e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100c11:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0100c14:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100c17:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0100c1a:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100c1d:	85 db                	test   %ebx,%ebx
f0100c1f:	75 08                	jne    f0100c29 <printnum+0x29>
f0100c21:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100c24:	39 5d 10             	cmp    %ebx,0x10(%ebp)
f0100c27:	77 6c                	ja     f0100c95 <printnum+0x95>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100c29:	8b 5d 18             	mov    0x18(%ebp),%ebx
f0100c2c:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f0100c30:	83 ee 01             	sub    $0x1,%esi
f0100c33:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100c37:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100c3a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100c3e:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100c42:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100c46:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100c49:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100c4c:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100c53:	00 
f0100c54:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100c57:	89 1c 24             	mov    %ebx,(%esp)
f0100c5a:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100c5d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100c61:	e8 1a 0a 00 00       	call   f0101680 <__udivdi3>
f0100c66:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100c69:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100c6c:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100c70:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100c74:	89 04 24             	mov    %eax,(%esp)
f0100c77:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100c7b:	89 fa                	mov    %edi,%edx
f0100c7d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100c80:	e8 7b ff ff ff       	call   f0100c00 <printnum>
f0100c85:	eb 1b                	jmp    f0100ca2 <printnum+0xa2>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100c87:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100c8b:	8b 45 18             	mov    0x18(%ebp),%eax
f0100c8e:	89 04 24             	mov    %eax,(%esp)
f0100c91:	ff d3                	call   *%ebx
f0100c93:	eb 03                	jmp    f0100c98 <printnum+0x98>
f0100c95:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100c98:	83 ee 01             	sub    $0x1,%esi
f0100c9b:	85 f6                	test   %esi,%esi
f0100c9d:	7f e8                	jg     f0100c87 <printnum+0x87>
f0100c9f:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100ca2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100ca6:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100caa:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100cad:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100cb1:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100cb8:	00 
f0100cb9:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100cbc:	89 1c 24             	mov    %ebx,(%esp)
f0100cbf:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100cc2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100cc6:	e8 15 0b 00 00       	call   f01017e0 <__umoddi3>
f0100ccb:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100ccf:	0f be 80 51 1e 10 f0 	movsbl -0xfefe1af(%eax),%eax
f0100cd6:	89 04 24             	mov    %eax,(%esp)
f0100cd9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100cdc:	ff d0                	call   *%eax
}
f0100cde:	83 c4 4c             	add    $0x4c,%esp
f0100ce1:	5b                   	pop    %ebx
f0100ce2:	5e                   	pop    %esi
f0100ce3:	5f                   	pop    %edi
f0100ce4:	5d                   	pop    %ebp
f0100ce5:	c3                   	ret    

f0100ce6 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100ce6:	55                   	push   %ebp
f0100ce7:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100ce9:	83 fa 01             	cmp    $0x1,%edx
f0100cec:	7e 0e                	jle    f0100cfc <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100cee:	8b 10                	mov    (%eax),%edx
f0100cf0:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100cf3:	89 08                	mov    %ecx,(%eax)
f0100cf5:	8b 02                	mov    (%edx),%eax
f0100cf7:	8b 52 04             	mov    0x4(%edx),%edx
f0100cfa:	eb 22                	jmp    f0100d1e <getuint+0x38>
	else if (lflag)
f0100cfc:	85 d2                	test   %edx,%edx
f0100cfe:	74 10                	je     f0100d10 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100d00:	8b 10                	mov    (%eax),%edx
f0100d02:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d05:	89 08                	mov    %ecx,(%eax)
f0100d07:	8b 02                	mov    (%edx),%eax
f0100d09:	ba 00 00 00 00       	mov    $0x0,%edx
f0100d0e:	eb 0e                	jmp    f0100d1e <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100d10:	8b 10                	mov    (%eax),%edx
f0100d12:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100d15:	89 08                	mov    %ecx,(%eax)
f0100d17:	8b 02                	mov    (%edx),%eax
f0100d19:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100d1e:	5d                   	pop    %ebp
f0100d1f:	c3                   	ret    

f0100d20 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100d20:	55                   	push   %ebp
f0100d21:	89 e5                	mov    %esp,%ebp
f0100d23:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100d26:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100d2a:	8b 10                	mov    (%eax),%edx
f0100d2c:	3b 50 04             	cmp    0x4(%eax),%edx
f0100d2f:	73 0a                	jae    f0100d3b <sprintputch+0x1b>
		*b->buf++ = ch;
f0100d31:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100d34:	88 0a                	mov    %cl,(%edx)
f0100d36:	83 c2 01             	add    $0x1,%edx
f0100d39:	89 10                	mov    %edx,(%eax)
}
f0100d3b:	5d                   	pop    %ebp
f0100d3c:	c3                   	ret    

f0100d3d <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100d3d:	55                   	push   %ebp
f0100d3e:	89 e5                	mov    %esp,%ebp
f0100d40:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100d43:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100d46:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100d4a:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d4d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d51:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d54:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d58:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d5b:	89 04 24             	mov    %eax,(%esp)
f0100d5e:	e8 02 00 00 00       	call   f0100d65 <vprintfmt>
	va_end(ap);
}
f0100d63:	c9                   	leave  
f0100d64:	c3                   	ret    

f0100d65 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100d65:	55                   	push   %ebp
f0100d66:	89 e5                	mov    %esp,%ebp
f0100d68:	57                   	push   %edi
f0100d69:	56                   	push   %esi
f0100d6a:	53                   	push   %ebx
f0100d6b:	83 ec 4c             	sub    $0x4c,%esp
f0100d6e:	8b 75 08             	mov    0x8(%ebp),%esi
f0100d71:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100d74:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100d77:	eb 11                	jmp    f0100d8a <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100d79:	85 c0                	test   %eax,%eax
f0100d7b:	0f 84 f4 03 00 00    	je     f0101175 <vprintfmt+0x410>
				return;
			putch(ch, putdat);
f0100d81:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100d85:	89 04 24             	mov    %eax,(%esp)
f0100d88:	ff d6                	call   *%esi
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100d8a:	0f b6 07             	movzbl (%edi),%eax
f0100d8d:	83 c7 01             	add    $0x1,%edi
f0100d90:	83 f8 25             	cmp    $0x25,%eax
f0100d93:	75 e4                	jne    f0100d79 <vprintfmt+0x14>
f0100d95:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
f0100d99:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f0100da0:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0100da7:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f0100dae:	ba 00 00 00 00       	mov    $0x0,%edx
f0100db3:	eb 2b                	jmp    f0100de0 <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100db5:	8b 7d e0             	mov    -0x20(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100db8:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
f0100dbc:	eb 22                	jmp    f0100de0 <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100dbe:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100dc1:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
f0100dc5:	eb 19                	jmp    f0100de0 <vprintfmt+0x7b>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100dc7:	8b 7d e0             	mov    -0x20(%ebp),%edi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0100dca:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100dd1:	eb 0d                	jmp    f0100de0 <vprintfmt+0x7b>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100dd3:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100dd6:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100dd9:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100de0:	0f b6 07             	movzbl (%edi),%eax
f0100de3:	8d 4f 01             	lea    0x1(%edi),%ecx
f0100de6:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100de9:	0f b6 0f             	movzbl (%edi),%ecx
f0100dec:	83 e9 23             	sub    $0x23,%ecx
f0100def:	80 f9 55             	cmp    $0x55,%cl
f0100df2:	0f 87 5c 03 00 00    	ja     f0101154 <vprintfmt+0x3ef>
f0100df8:	0f b6 c9             	movzbl %cl,%ecx
f0100dfb:	ff 24 8d e0 1e 10 f0 	jmp    *-0xfefe120(,%ecx,4)
f0100e02:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100e05:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0100e0c:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100e0f:	ba 00 00 00 00       	mov    $0x0,%edx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100e14:	8d 14 92             	lea    (%edx,%edx,4),%edx
f0100e17:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f0100e1b:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
f0100e1e:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0100e21:	83 f9 09             	cmp    $0x9,%ecx
f0100e24:	77 2f                	ja     f0100e55 <vprintfmt+0xf0>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100e26:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0100e29:	eb e9                	jmp    f0100e14 <vprintfmt+0xaf>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100e2b:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e2e:	8d 48 04             	lea    0x4(%eax),%ecx
f0100e31:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100e34:	8b 00                	mov    (%eax),%eax
f0100e36:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e39:	8b 7d e0             	mov    -0x20(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100e3c:	eb 1d                	jmp    f0100e5b <vprintfmt+0xf6>

		case '.':
			if (width < 0)
f0100e3e:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100e42:	78 83                	js     f0100dc7 <vprintfmt+0x62>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e44:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100e47:	eb 97                	jmp    f0100de0 <vprintfmt+0x7b>
f0100e49:	8b 7d e0             	mov    -0x20(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100e4c:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
f0100e53:	eb 8b                	jmp    f0100de0 <vprintfmt+0x7b>
f0100e55:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0100e58:	8b 55 e0             	mov    -0x20(%ebp),%edx

		process_precision:
			if (width < 0)
f0100e5b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100e5f:	0f 89 7b ff ff ff    	jns    f0100de0 <vprintfmt+0x7b>
f0100e65:	e9 69 ff ff ff       	jmp    f0100dd3 <vprintfmt+0x6e>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100e6a:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e6d:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100e70:	e9 6b ff ff ff       	jmp    f0100de0 <vprintfmt+0x7b>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100e75:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e78:	8d 50 04             	lea    0x4(%eax),%edx
f0100e7b:	89 55 14             	mov    %edx,0x14(%ebp)
f0100e7e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100e82:	8b 00                	mov    (%eax),%eax
f0100e84:	89 04 24             	mov    %eax,(%esp)
f0100e87:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e89:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100e8c:	e9 f9 fe ff ff       	jmp    f0100d8a <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100e91:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e94:	8d 50 04             	lea    0x4(%eax),%edx
f0100e97:	89 55 14             	mov    %edx,0x14(%ebp)
f0100e9a:	8b 00                	mov    (%eax),%eax
f0100e9c:	89 c2                	mov    %eax,%edx
f0100e9e:	c1 fa 1f             	sar    $0x1f,%edx
f0100ea1:	31 d0                	xor    %edx,%eax
f0100ea3:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100ea5:	83 f8 06             	cmp    $0x6,%eax
f0100ea8:	7f 0b                	jg     f0100eb5 <vprintfmt+0x150>
f0100eaa:	8b 14 85 38 20 10 f0 	mov    -0xfefdfc8(,%eax,4),%edx
f0100eb1:	85 d2                	test   %edx,%edx
f0100eb3:	75 20                	jne    f0100ed5 <vprintfmt+0x170>
				printfmt(putch, putdat, "error %d", err);
f0100eb5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100eb9:	c7 44 24 08 69 1e 10 	movl   $0xf0101e69,0x8(%esp)
f0100ec0:	f0 
f0100ec1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100ec5:	89 34 24             	mov    %esi,(%esp)
f0100ec8:	e8 70 fe ff ff       	call   f0100d3d <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ecd:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100ed0:	e9 b5 fe ff ff       	jmp    f0100d8a <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f0100ed5:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100ed9:	c7 44 24 08 72 1e 10 	movl   $0xf0101e72,0x8(%esp)
f0100ee0:	f0 
f0100ee1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100ee5:	89 34 24             	mov    %esi,(%esp)
f0100ee8:	e8 50 fe ff ff       	call   f0100d3d <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eed:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100ef0:	e9 95 fe ff ff       	jmp    f0100d8a <vprintfmt+0x25>
f0100ef5:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100ef8:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0100efb:	89 7d cc             	mov    %edi,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100efe:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f01:	8d 50 04             	lea    0x4(%eax),%edx
f0100f04:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f07:	8b 38                	mov    (%eax),%edi
f0100f09:	85 ff                	test   %edi,%edi
f0100f0b:	75 05                	jne    f0100f12 <vprintfmt+0x1ad>
				p = "(null)";
f0100f0d:	bf 62 1e 10 f0       	mov    $0xf0101e62,%edi
			if (width > 0 && padc != '-')
f0100f12:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
f0100f16:	0f 84 99 00 00 00    	je     f0100fb5 <vprintfmt+0x250>
f0100f1c:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0100f20:	0f 8e 9d 00 00 00    	jle    f0100fc3 <vprintfmt+0x25e>
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f26:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100f2a:	89 3c 24             	mov    %edi,(%esp)
f0100f2d:	e8 b6 03 00 00       	call   f01012e8 <strnlen>
f0100f32:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0100f35:	29 c2                	sub    %eax,%edx
f0100f37:	89 55 d8             	mov    %edx,-0x28(%ebp)
					putch(padc, putdat);
f0100f3a:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
f0100f3e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100f41:	89 7d c8             	mov    %edi,-0x38(%ebp)
f0100f44:	89 d7                	mov    %edx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f46:	eb 0f                	jmp    f0100f57 <vprintfmt+0x1f2>
					putch(padc, putdat);
f0100f48:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f4c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100f4f:	89 04 24             	mov    %eax,(%esp)
f0100f52:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100f54:	83 ef 01             	sub    $0x1,%edi
f0100f57:	85 ff                	test   %edi,%edi
f0100f59:	7f ed                	jg     f0100f48 <vprintfmt+0x1e3>
f0100f5b:	8b 7d c8             	mov    -0x38(%ebp),%edi

// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
f0100f5e:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100f61:	c1 f8 1f             	sar    $0x1f,%eax
f0100f64:	f7 d0                	not    %eax
f0100f66:	23 45 d8             	and    -0x28(%ebp),%eax
f0100f69:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100f6c:	29 c2                	sub    %eax,%edx
f0100f6e:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0100f71:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0100f74:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0100f77:	89 d3                	mov    %edx,%ebx
f0100f79:	eb 54                	jmp    f0100fcf <vprintfmt+0x26a>
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100f7b:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0100f7f:	74 20                	je     f0100fa1 <vprintfmt+0x23c>
f0100f81:	0f be d2             	movsbl %dl,%edx
f0100f84:	83 ea 20             	sub    $0x20,%edx
f0100f87:	83 fa 5e             	cmp    $0x5e,%edx
f0100f8a:	76 15                	jbe    f0100fa1 <vprintfmt+0x23c>
					putch('?', putdat);
f0100f8c:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100f8f:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100f93:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0100f9a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100f9d:	ff d0                	call   *%eax
f0100f9f:	eb 0f                	jmp    f0100fb0 <vprintfmt+0x24b>
				else
					putch(ch, putdat);
f0100fa1:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100fa4:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100fa8:	89 04 24             	mov    %eax,(%esp)
f0100fab:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100fae:	ff d1                	call   *%ecx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100fb0:	83 eb 01             	sub    $0x1,%ebx
f0100fb3:	eb 1a                	jmp    f0100fcf <vprintfmt+0x26a>
f0100fb5:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0100fb8:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0100fbb:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0100fbe:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100fc1:	eb 0c                	jmp    f0100fcf <vprintfmt+0x26a>
f0100fc3:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0100fc6:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0100fc9:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0100fcc:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100fcf:	0f b6 17             	movzbl (%edi),%edx
f0100fd2:	0f be c2             	movsbl %dl,%eax
f0100fd5:	83 c7 01             	add    $0x1,%edi
f0100fd8:	85 c0                	test   %eax,%eax
f0100fda:	74 29                	je     f0101005 <vprintfmt+0x2a0>
f0100fdc:	85 f6                	test   %esi,%esi
f0100fde:	78 9b                	js     f0100f7b <vprintfmt+0x216>
f0100fe0:	83 ee 01             	sub    $0x1,%esi
f0100fe3:	79 96                	jns    f0100f7b <vprintfmt+0x216>
f0100fe5:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0100fe8:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100feb:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100fee:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0100ff1:	eb 1a                	jmp    f010100d <vprintfmt+0x2a8>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0100ff3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100ff7:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0100ffe:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101000:	83 ef 01             	sub    $0x1,%edi
f0101003:	eb 08                	jmp    f010100d <vprintfmt+0x2a8>
f0101005:	89 df                	mov    %ebx,%edi
f0101007:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010100a:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f010100d:	85 ff                	test   %edi,%edi
f010100f:	7f e2                	jg     f0100ff3 <vprintfmt+0x28e>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101011:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101014:	e9 71 fd ff ff       	jmp    f0100d8a <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101019:	83 fa 01             	cmp    $0x1,%edx
f010101c:	7e 16                	jle    f0101034 <vprintfmt+0x2cf>
		return va_arg(*ap, long long);
f010101e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101021:	8d 50 08             	lea    0x8(%eax),%edx
f0101024:	89 55 14             	mov    %edx,0x14(%ebp)
f0101027:	8b 10                	mov    (%eax),%edx
f0101029:	8b 48 04             	mov    0x4(%eax),%ecx
f010102c:	89 55 d0             	mov    %edx,-0x30(%ebp)
f010102f:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0101032:	eb 32                	jmp    f0101066 <vprintfmt+0x301>
	else if (lflag)
f0101034:	85 d2                	test   %edx,%edx
f0101036:	74 18                	je     f0101050 <vprintfmt+0x2eb>
		return va_arg(*ap, long);
f0101038:	8b 45 14             	mov    0x14(%ebp),%eax
f010103b:	8d 50 04             	lea    0x4(%eax),%edx
f010103e:	89 55 14             	mov    %edx,0x14(%ebp)
f0101041:	8b 00                	mov    (%eax),%eax
f0101043:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101046:	89 c1                	mov    %eax,%ecx
f0101048:	c1 f9 1f             	sar    $0x1f,%ecx
f010104b:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f010104e:	eb 16                	jmp    f0101066 <vprintfmt+0x301>
	else
		return va_arg(*ap, int);
f0101050:	8b 45 14             	mov    0x14(%ebp),%eax
f0101053:	8d 50 04             	lea    0x4(%eax),%edx
f0101056:	89 55 14             	mov    %edx,0x14(%ebp)
f0101059:	8b 00                	mov    (%eax),%eax
f010105b:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010105e:	89 c7                	mov    %eax,%edi
f0101060:	c1 ff 1f             	sar    $0x1f,%edi
f0101063:	89 7d d4             	mov    %edi,-0x2c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101066:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101069:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010106c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101071:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0101075:	0f 89 9d 00 00 00    	jns    f0101118 <vprintfmt+0x3b3>
				putch('-', putdat);
f010107b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010107f:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0101086:	ff d6                	call   *%esi
				num = -(long long) num;
f0101088:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010108b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010108e:	f7 d8                	neg    %eax
f0101090:	83 d2 00             	adc    $0x0,%edx
f0101093:	f7 da                	neg    %edx
			}
			base = 10;
f0101095:	b9 0a 00 00 00       	mov    $0xa,%ecx
f010109a:	eb 7c                	jmp    f0101118 <vprintfmt+0x3b3>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f010109c:	8d 45 14             	lea    0x14(%ebp),%eax
f010109f:	e8 42 fc ff ff       	call   f0100ce6 <getuint>
			base = 10;
f01010a4:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01010a9:	eb 6d                	jmp    f0101118 <vprintfmt+0x3b3>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f01010ab:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010af:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f01010b6:	ff d6                	call   *%esi
			putch('X', putdat);
f01010b8:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010bc:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f01010c3:	ff d6                	call   *%esi
			putch('X', putdat);
f01010c5:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010c9:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f01010d0:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01010d2:	8b 7d e0             	mov    -0x20(%ebp),%edi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f01010d5:	e9 b0 fc ff ff       	jmp    f0100d8a <vprintfmt+0x25>

		// pointer
		case 'p':
			putch('0', putdat);
f01010da:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010de:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01010e5:	ff d6                	call   *%esi
			putch('x', putdat);
f01010e7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010eb:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01010f2:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01010f4:	8b 45 14             	mov    0x14(%ebp),%eax
f01010f7:	8d 50 04             	lea    0x4(%eax),%edx
f01010fa:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01010fd:	8b 00                	mov    (%eax),%eax
f01010ff:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0101104:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101109:	eb 0d                	jmp    f0101118 <vprintfmt+0x3b3>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f010110b:	8d 45 14             	lea    0x14(%ebp),%eax
f010110e:	e8 d3 fb ff ff       	call   f0100ce6 <getuint>
			base = 16;
f0101113:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101118:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
f010111c:	89 7c 24 10          	mov    %edi,0x10(%esp)
f0101120:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0101123:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101127:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010112b:	89 04 24             	mov    %eax,(%esp)
f010112e:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101132:	89 da                	mov    %ebx,%edx
f0101134:	89 f0                	mov    %esi,%eax
f0101136:	e8 c5 fa ff ff       	call   f0100c00 <printnum>
			break;
f010113b:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010113e:	e9 47 fc ff ff       	jmp    f0100d8a <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101143:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101147:	89 04 24             	mov    %eax,(%esp)
f010114a:	ff d6                	call   *%esi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010114c:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f010114f:	e9 36 fc ff ff       	jmp    f0100d8a <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101154:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101158:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f010115f:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101161:	eb 03                	jmp    f0101166 <vprintfmt+0x401>
f0101163:	83 ef 01             	sub    $0x1,%edi
f0101166:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f010116a:	75 f7                	jne    f0101163 <vprintfmt+0x3fe>
f010116c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101170:	e9 15 fc ff ff       	jmp    f0100d8a <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f0101175:	83 c4 4c             	add    $0x4c,%esp
f0101178:	5b                   	pop    %ebx
f0101179:	5e                   	pop    %esi
f010117a:	5f                   	pop    %edi
f010117b:	5d                   	pop    %ebp
f010117c:	c3                   	ret    

f010117d <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010117d:	55                   	push   %ebp
f010117e:	89 e5                	mov    %esp,%ebp
f0101180:	83 ec 28             	sub    $0x28,%esp
f0101183:	8b 45 08             	mov    0x8(%ebp),%eax
f0101186:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101189:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010118c:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101190:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101193:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010119a:	85 d2                	test   %edx,%edx
f010119c:	7e 30                	jle    f01011ce <vsnprintf+0x51>
f010119e:	85 c0                	test   %eax,%eax
f01011a0:	74 2c                	je     f01011ce <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01011a2:	8b 45 14             	mov    0x14(%ebp),%eax
f01011a5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01011a9:	8b 45 10             	mov    0x10(%ebp),%eax
f01011ac:	89 44 24 08          	mov    %eax,0x8(%esp)
f01011b0:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01011b3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01011b7:	c7 04 24 20 0d 10 f0 	movl   $0xf0100d20,(%esp)
f01011be:	e8 a2 fb ff ff       	call   f0100d65 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01011c3:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01011c6:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01011c9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01011cc:	eb 05                	jmp    f01011d3 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01011ce:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01011d3:	c9                   	leave  
f01011d4:	c3                   	ret    

f01011d5 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01011d5:	55                   	push   %ebp
f01011d6:	89 e5                	mov    %esp,%ebp
f01011d8:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01011db:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01011de:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01011e2:	8b 45 10             	mov    0x10(%ebp),%eax
f01011e5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01011e9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011ec:	89 44 24 04          	mov    %eax,0x4(%esp)
f01011f0:	8b 45 08             	mov    0x8(%ebp),%eax
f01011f3:	89 04 24             	mov    %eax,(%esp)
f01011f6:	e8 82 ff ff ff       	call   f010117d <vsnprintf>
	va_end(ap);

	return rc;
}
f01011fb:	c9                   	leave  
f01011fc:	c3                   	ret    
f01011fd:	00 00                	add    %al,(%eax)
	...

f0101200 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101200:	55                   	push   %ebp
f0101201:	89 e5                	mov    %esp,%ebp
f0101203:	57                   	push   %edi
f0101204:	56                   	push   %esi
f0101205:	53                   	push   %ebx
f0101206:	83 ec 1c             	sub    $0x1c,%esp
f0101209:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010120c:	85 c0                	test   %eax,%eax
f010120e:	74 10                	je     f0101220 <readline+0x20>
		cprintf("%s", prompt);
f0101210:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101214:	c7 04 24 72 1e 10 f0 	movl   $0xf0101e72,(%esp)
f010121b:	e8 fe f6 ff ff       	call   f010091e <cprintf>

	i = 0;
	echoing = iscons(0);
f0101220:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101227:	e8 4f f4 ff ff       	call   f010067b <iscons>
f010122c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010122e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101233:	e8 32 f4 ff ff       	call   f010066a <getchar>
f0101238:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010123a:	85 c0                	test   %eax,%eax
f010123c:	79 17                	jns    f0101255 <readline+0x55>
			cprintf("read error: %e\n", c);
f010123e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101242:	c7 04 24 54 20 10 f0 	movl   $0xf0102054,(%esp)
f0101249:	e8 d0 f6 ff ff       	call   f010091e <cprintf>
			return NULL;
f010124e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101253:	eb 6d                	jmp    f01012c2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101255:	83 f8 7f             	cmp    $0x7f,%eax
f0101258:	74 05                	je     f010125f <readline+0x5f>
f010125a:	83 f8 08             	cmp    $0x8,%eax
f010125d:	75 19                	jne    f0101278 <readline+0x78>
f010125f:	85 f6                	test   %esi,%esi
f0101261:	7e 15                	jle    f0101278 <readline+0x78>
			if (echoing)
f0101263:	85 ff                	test   %edi,%edi
f0101265:	74 0c                	je     f0101273 <readline+0x73>
				cputchar('\b');
f0101267:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010126e:	e8 e7 f3 ff ff       	call   f010065a <cputchar>
			i--;
f0101273:	83 ee 01             	sub    $0x1,%esi
f0101276:	eb bb                	jmp    f0101233 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101278:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010127e:	7f 1c                	jg     f010129c <readline+0x9c>
f0101280:	83 fb 1f             	cmp    $0x1f,%ebx
f0101283:	7e 17                	jle    f010129c <readline+0x9c>
			if (echoing)
f0101285:	85 ff                	test   %edi,%edi
f0101287:	74 08                	je     f0101291 <readline+0x91>
				cputchar(c);
f0101289:	89 1c 24             	mov    %ebx,(%esp)
f010128c:	e8 c9 f3 ff ff       	call   f010065a <cputchar>
			buf[i++] = c;
f0101291:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f0101297:	83 c6 01             	add    $0x1,%esi
f010129a:	eb 97                	jmp    f0101233 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010129c:	83 fb 0d             	cmp    $0xd,%ebx
f010129f:	74 05                	je     f01012a6 <readline+0xa6>
f01012a1:	83 fb 0a             	cmp    $0xa,%ebx
f01012a4:	75 8d                	jne    f0101233 <readline+0x33>
			if (echoing)
f01012a6:	85 ff                	test   %edi,%edi
f01012a8:	74 0c                	je     f01012b6 <readline+0xb6>
				cputchar('\n');
f01012aa:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01012b1:	e8 a4 f3 ff ff       	call   f010065a <cputchar>
			buf[i] = 0;
f01012b6:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f01012bd:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f01012c2:	83 c4 1c             	add    $0x1c,%esp
f01012c5:	5b                   	pop    %ebx
f01012c6:	5e                   	pop    %esi
f01012c7:	5f                   	pop    %edi
f01012c8:	5d                   	pop    %ebp
f01012c9:	c3                   	ret    
f01012ca:	00 00                	add    %al,(%eax)
f01012cc:	00 00                	add    %al,(%eax)
	...

f01012d0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01012d0:	55                   	push   %ebp
f01012d1:	89 e5                	mov    %esp,%ebp
f01012d3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01012d6:	b8 00 00 00 00       	mov    $0x0,%eax
f01012db:	eb 03                	jmp    f01012e0 <strlen+0x10>
		n++;
f01012dd:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01012e0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01012e4:	75 f7                	jne    f01012dd <strlen+0xd>
		n++;
	return n;
}
f01012e6:	5d                   	pop    %ebp
f01012e7:	c3                   	ret    

f01012e8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01012e8:	55                   	push   %ebp
f01012e9:	89 e5                	mov    %esp,%ebp
f01012eb:	8b 4d 08             	mov    0x8(%ebp),%ecx
		n++;
	return n;
}

int
strnlen(const char *s, size_t size)
f01012ee:	8b 55 0c             	mov    0xc(%ebp),%edx
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01012f1:	b8 00 00 00 00       	mov    $0x0,%eax
f01012f6:	eb 03                	jmp    f01012fb <strnlen+0x13>
		n++;
f01012f8:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01012fb:	39 d0                	cmp    %edx,%eax
f01012fd:	74 06                	je     f0101305 <strnlen+0x1d>
f01012ff:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0101303:	75 f3                	jne    f01012f8 <strnlen+0x10>
		n++;
	return n;
}
f0101305:	5d                   	pop    %ebp
f0101306:	c3                   	ret    

f0101307 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101307:	55                   	push   %ebp
f0101308:	89 e5                	mov    %esp,%ebp
f010130a:	53                   	push   %ebx
f010130b:	8b 45 08             	mov    0x8(%ebp),%eax
f010130e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101311:	89 c2                	mov    %eax,%edx
f0101313:	0f b6 19             	movzbl (%ecx),%ebx
f0101316:	88 1a                	mov    %bl,(%edx)
f0101318:	83 c2 01             	add    $0x1,%edx
f010131b:	83 c1 01             	add    $0x1,%ecx
f010131e:	84 db                	test   %bl,%bl
f0101320:	75 f1                	jne    f0101313 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101322:	5b                   	pop    %ebx
f0101323:	5d                   	pop    %ebp
f0101324:	c3                   	ret    

f0101325 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101325:	55                   	push   %ebp
f0101326:	89 e5                	mov    %esp,%ebp
f0101328:	53                   	push   %ebx
f0101329:	83 ec 08             	sub    $0x8,%esp
f010132c:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010132f:	89 1c 24             	mov    %ebx,(%esp)
f0101332:	e8 99 ff ff ff       	call   f01012d0 <strlen>
	strcpy(dst + len, src);
f0101337:	8b 55 0c             	mov    0xc(%ebp),%edx
f010133a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010133e:	01 d8                	add    %ebx,%eax
f0101340:	89 04 24             	mov    %eax,(%esp)
f0101343:	e8 bf ff ff ff       	call   f0101307 <strcpy>
	return dst;
}
f0101348:	89 d8                	mov    %ebx,%eax
f010134a:	83 c4 08             	add    $0x8,%esp
f010134d:	5b                   	pop    %ebx
f010134e:	5d                   	pop    %ebp
f010134f:	c3                   	ret    

f0101350 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101350:	55                   	push   %ebp
f0101351:	89 e5                	mov    %esp,%ebp
f0101353:	56                   	push   %esi
f0101354:	53                   	push   %ebx
f0101355:	8b 75 08             	mov    0x8(%ebp),%esi
f0101358:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010135b:	89 f3                	mov    %esi,%ebx
f010135d:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101360:	89 f2                	mov    %esi,%edx
f0101362:	eb 0e                	jmp    f0101372 <strncpy+0x22>
		*dst++ = *src;
f0101364:	0f b6 01             	movzbl (%ecx),%eax
f0101367:	88 02                	mov    %al,(%edx)
f0101369:	83 c2 01             	add    $0x1,%edx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010136c:	80 39 01             	cmpb   $0x1,(%ecx)
f010136f:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101372:	39 da                	cmp    %ebx,%edx
f0101374:	75 ee                	jne    f0101364 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101376:	89 f0                	mov    %esi,%eax
f0101378:	5b                   	pop    %ebx
f0101379:	5e                   	pop    %esi
f010137a:	5d                   	pop    %ebp
f010137b:	c3                   	ret    

f010137c <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010137c:	55                   	push   %ebp
f010137d:	89 e5                	mov    %esp,%ebp
f010137f:	56                   	push   %esi
f0101380:	53                   	push   %ebx
f0101381:	8b 75 08             	mov    0x8(%ebp),%esi
f0101384:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101387:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010138a:	89 f0                	mov    %esi,%eax
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f010138c:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101390:	85 c9                	test   %ecx,%ecx
f0101392:	75 0a                	jne    f010139e <strlcpy+0x22>
f0101394:	eb 1c                	jmp    f01013b2 <strlcpy+0x36>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101396:	88 08                	mov    %cl,(%eax)
f0101398:	83 c0 01             	add    $0x1,%eax
f010139b:	83 c2 01             	add    $0x1,%edx
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f010139e:	39 d8                	cmp    %ebx,%eax
f01013a0:	74 0b                	je     f01013ad <strlcpy+0x31>
f01013a2:	0f b6 0a             	movzbl (%edx),%ecx
f01013a5:	84 c9                	test   %cl,%cl
f01013a7:	75 ed                	jne    f0101396 <strlcpy+0x1a>
f01013a9:	89 c2                	mov    %eax,%edx
f01013ab:	eb 02                	jmp    f01013af <strlcpy+0x33>
f01013ad:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f01013af:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f01013b2:	29 f0                	sub    %esi,%eax
}
f01013b4:	5b                   	pop    %ebx
f01013b5:	5e                   	pop    %esi
f01013b6:	5d                   	pop    %ebp
f01013b7:	c3                   	ret    

f01013b8 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01013b8:	55                   	push   %ebp
f01013b9:	89 e5                	mov    %esp,%ebp
f01013bb:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01013be:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01013c1:	eb 06                	jmp    f01013c9 <strcmp+0x11>
		p++, q++;
f01013c3:	83 c1 01             	add    $0x1,%ecx
f01013c6:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01013c9:	0f b6 01             	movzbl (%ecx),%eax
f01013cc:	84 c0                	test   %al,%al
f01013ce:	74 04                	je     f01013d4 <strcmp+0x1c>
f01013d0:	3a 02                	cmp    (%edx),%al
f01013d2:	74 ef                	je     f01013c3 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01013d4:	0f b6 c0             	movzbl %al,%eax
f01013d7:	0f b6 12             	movzbl (%edx),%edx
f01013da:	29 d0                	sub    %edx,%eax
}
f01013dc:	5d                   	pop    %ebp
f01013dd:	c3                   	ret    

f01013de <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01013de:	55                   	push   %ebp
f01013df:	89 e5                	mov    %esp,%ebp
f01013e1:	53                   	push   %ebx
f01013e2:	8b 45 08             	mov    0x8(%ebp),%eax
f01013e5:	8b 55 0c             	mov    0xc(%ebp),%edx
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
strncmp(const char *p, const char *q, size_t n)
f01013e8:	89 c3                	mov    %eax,%ebx
f01013ea:	03 5d 10             	add    0x10(%ebp),%ebx
{
	while (n > 0 && *p && *p == *q)
f01013ed:	eb 06                	jmp    f01013f5 <strncmp+0x17>
		n--, p++, q++;
f01013ef:	83 c0 01             	add    $0x1,%eax
f01013f2:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01013f5:	39 d8                	cmp    %ebx,%eax
f01013f7:	74 15                	je     f010140e <strncmp+0x30>
f01013f9:	0f b6 08             	movzbl (%eax),%ecx
f01013fc:	84 c9                	test   %cl,%cl
f01013fe:	74 04                	je     f0101404 <strncmp+0x26>
f0101400:	3a 0a                	cmp    (%edx),%cl
f0101402:	74 eb                	je     f01013ef <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101404:	0f b6 00             	movzbl (%eax),%eax
f0101407:	0f b6 12             	movzbl (%edx),%edx
f010140a:	29 d0                	sub    %edx,%eax
f010140c:	eb 05                	jmp    f0101413 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010140e:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101413:	5b                   	pop    %ebx
f0101414:	5d                   	pop    %ebp
f0101415:	c3                   	ret    

f0101416 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101416:	55                   	push   %ebp
f0101417:	89 e5                	mov    %esp,%ebp
f0101419:	8b 45 08             	mov    0x8(%ebp),%eax
f010141c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101420:	eb 07                	jmp    f0101429 <strchr+0x13>
		if (*s == c)
f0101422:	38 ca                	cmp    %cl,%dl
f0101424:	74 0f                	je     f0101435 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101426:	83 c0 01             	add    $0x1,%eax
f0101429:	0f b6 10             	movzbl (%eax),%edx
f010142c:	84 d2                	test   %dl,%dl
f010142e:	75 f2                	jne    f0101422 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101430:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101435:	5d                   	pop    %ebp
f0101436:	c3                   	ret    

f0101437 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101437:	55                   	push   %ebp
f0101438:	89 e5                	mov    %esp,%ebp
f010143a:	8b 45 08             	mov    0x8(%ebp),%eax
f010143d:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101441:	eb 07                	jmp    f010144a <strfind+0x13>
		if (*s == c)
f0101443:	38 ca                	cmp    %cl,%dl
f0101445:	74 0a                	je     f0101451 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0101447:	83 c0 01             	add    $0x1,%eax
f010144a:	0f b6 10             	movzbl (%eax),%edx
f010144d:	84 d2                	test   %dl,%dl
f010144f:	75 f2                	jne    f0101443 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0101451:	5d                   	pop    %ebp
f0101452:	c3                   	ret    

f0101453 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101453:	55                   	push   %ebp
f0101454:	89 e5                	mov    %esp,%ebp
f0101456:	83 ec 0c             	sub    $0xc,%esp
f0101459:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010145c:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010145f:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0101462:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101465:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101468:	85 c9                	test   %ecx,%ecx
f010146a:	74 36                	je     f01014a2 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010146c:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101472:	75 28                	jne    f010149c <memset+0x49>
f0101474:	f6 c1 03             	test   $0x3,%cl
f0101477:	75 23                	jne    f010149c <memset+0x49>
		c &= 0xFF;
f0101479:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010147d:	89 d3                	mov    %edx,%ebx
f010147f:	c1 e3 08             	shl    $0x8,%ebx
f0101482:	89 d6                	mov    %edx,%esi
f0101484:	c1 e6 18             	shl    $0x18,%esi
f0101487:	89 d0                	mov    %edx,%eax
f0101489:	c1 e0 10             	shl    $0x10,%eax
f010148c:	09 f0                	or     %esi,%eax
f010148e:	09 c2                	or     %eax,%edx
f0101490:	89 d0                	mov    %edx,%eax
f0101492:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0101494:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0101497:	fc                   	cld    
f0101498:	f3 ab                	rep stos %eax,%es:(%edi)
f010149a:	eb 06                	jmp    f01014a2 <memset+0x4f>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010149c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010149f:	fc                   	cld    
f01014a0:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01014a2:	89 f8                	mov    %edi,%eax
f01014a4:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01014a7:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01014aa:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01014ad:	89 ec                	mov    %ebp,%esp
f01014af:	5d                   	pop    %ebp
f01014b0:	c3                   	ret    

f01014b1 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01014b1:	55                   	push   %ebp
f01014b2:	89 e5                	mov    %esp,%ebp
f01014b4:	83 ec 08             	sub    $0x8,%esp
f01014b7:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01014ba:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01014bd:	8b 45 08             	mov    0x8(%ebp),%eax
f01014c0:	8b 75 0c             	mov    0xc(%ebp),%esi
f01014c3:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01014c6:	39 c6                	cmp    %eax,%esi
f01014c8:	73 36                	jae    f0101500 <memmove+0x4f>
f01014ca:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01014cd:	39 d0                	cmp    %edx,%eax
f01014cf:	73 2f                	jae    f0101500 <memmove+0x4f>
		s += n;
		d += n;
f01014d1:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01014d4:	f6 c2 03             	test   $0x3,%dl
f01014d7:	75 1b                	jne    f01014f4 <memmove+0x43>
f01014d9:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01014df:	75 13                	jne    f01014f4 <memmove+0x43>
f01014e1:	f6 c1 03             	test   $0x3,%cl
f01014e4:	75 0e                	jne    f01014f4 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01014e6:	83 ef 04             	sub    $0x4,%edi
f01014e9:	8d 72 fc             	lea    -0x4(%edx),%esi
f01014ec:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01014ef:	fd                   	std    
f01014f0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01014f2:	eb 09                	jmp    f01014fd <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01014f4:	83 ef 01             	sub    $0x1,%edi
f01014f7:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01014fa:	fd                   	std    
f01014fb:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01014fd:	fc                   	cld    
f01014fe:	eb 20                	jmp    f0101520 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101500:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101506:	75 13                	jne    f010151b <memmove+0x6a>
f0101508:	a8 03                	test   $0x3,%al
f010150a:	75 0f                	jne    f010151b <memmove+0x6a>
f010150c:	f6 c1 03             	test   $0x3,%cl
f010150f:	75 0a                	jne    f010151b <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101511:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0101514:	89 c7                	mov    %eax,%edi
f0101516:	fc                   	cld    
f0101517:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101519:	eb 05                	jmp    f0101520 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010151b:	89 c7                	mov    %eax,%edi
f010151d:	fc                   	cld    
f010151e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101520:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0101523:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101526:	89 ec                	mov    %ebp,%esp
f0101528:	5d                   	pop    %ebp
f0101529:	c3                   	ret    

f010152a <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010152a:	55                   	push   %ebp
f010152b:	89 e5                	mov    %esp,%ebp
f010152d:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101530:	8b 45 10             	mov    0x10(%ebp),%eax
f0101533:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101537:	8b 45 0c             	mov    0xc(%ebp),%eax
f010153a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010153e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101541:	89 04 24             	mov    %eax,(%esp)
f0101544:	e8 68 ff ff ff       	call   f01014b1 <memmove>
}
f0101549:	c9                   	leave  
f010154a:	c3                   	ret    

f010154b <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010154b:	55                   	push   %ebp
f010154c:	89 e5                	mov    %esp,%ebp
f010154e:	56                   	push   %esi
f010154f:	53                   	push   %ebx
f0101550:	8b 55 08             	mov    0x8(%ebp),%edx
{
	return memmove(dst, src, n);
}

int
memcmp(const void *v1, const void *v2, size_t n)
f0101553:	89 d6                	mov    %edx,%esi
f0101555:	03 75 10             	add    0x10(%ebp),%esi
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;
f0101558:	8b 4d 0c             	mov    0xc(%ebp),%ecx

	while (n-- > 0) {
f010155b:	eb 1a                	jmp    f0101577 <memcmp+0x2c>
		if (*s1 != *s2)
f010155d:	0f b6 02             	movzbl (%edx),%eax
f0101560:	0f b6 19             	movzbl (%ecx),%ebx
f0101563:	38 d8                	cmp    %bl,%al
f0101565:	74 0a                	je     f0101571 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101567:	0f b6 c0             	movzbl %al,%eax
f010156a:	0f b6 db             	movzbl %bl,%ebx
f010156d:	29 d8                	sub    %ebx,%eax
f010156f:	eb 0f                	jmp    f0101580 <memcmp+0x35>
		s1++, s2++;
f0101571:	83 c2 01             	add    $0x1,%edx
f0101574:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101577:	39 f2                	cmp    %esi,%edx
f0101579:	75 e2                	jne    f010155d <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010157b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101580:	5b                   	pop    %ebx
f0101581:	5e                   	pop    %esi
f0101582:	5d                   	pop    %ebp
f0101583:	c3                   	ret    

f0101584 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101584:	55                   	push   %ebp
f0101585:	89 e5                	mov    %esp,%ebp
f0101587:	8b 45 08             	mov    0x8(%ebp),%eax
f010158a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010158d:	89 c2                	mov    %eax,%edx
f010158f:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101592:	eb 07                	jmp    f010159b <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101594:	38 08                	cmp    %cl,(%eax)
f0101596:	74 07                	je     f010159f <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101598:	83 c0 01             	add    $0x1,%eax
f010159b:	39 d0                	cmp    %edx,%eax
f010159d:	72 f5                	jb     f0101594 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010159f:	5d                   	pop    %ebp
f01015a0:	c3                   	ret    

f01015a1 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01015a1:	55                   	push   %ebp
f01015a2:	89 e5                	mov    %esp,%ebp
f01015a4:	57                   	push   %edi
f01015a5:	56                   	push   %esi
f01015a6:	53                   	push   %ebx
f01015a7:	83 ec 04             	sub    $0x4,%esp
f01015aa:	8b 55 08             	mov    0x8(%ebp),%edx
f01015ad:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01015b0:	eb 03                	jmp    f01015b5 <strtol+0x14>
		s++;
f01015b2:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01015b5:	0f b6 02             	movzbl (%edx),%eax
f01015b8:	3c 09                	cmp    $0x9,%al
f01015ba:	74 f6                	je     f01015b2 <strtol+0x11>
f01015bc:	3c 20                	cmp    $0x20,%al
f01015be:	74 f2                	je     f01015b2 <strtol+0x11>
		s++;

	// plus/minus sign
	if (*s == '+')
f01015c0:	3c 2b                	cmp    $0x2b,%al
f01015c2:	75 0a                	jne    f01015ce <strtol+0x2d>
		s++;
f01015c4:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01015c7:	bf 00 00 00 00       	mov    $0x0,%edi
f01015cc:	eb 10                	jmp    f01015de <strtol+0x3d>
f01015ce:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01015d3:	3c 2d                	cmp    $0x2d,%al
f01015d5:	75 07                	jne    f01015de <strtol+0x3d>
		s++, neg = 1;
f01015d7:	8d 52 01             	lea    0x1(%edx),%edx
f01015da:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01015de:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01015e4:	75 15                	jne    f01015fb <strtol+0x5a>
f01015e6:	80 3a 30             	cmpb   $0x30,(%edx)
f01015e9:	75 10                	jne    f01015fb <strtol+0x5a>
f01015eb:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01015ef:	75 0a                	jne    f01015fb <strtol+0x5a>
		s += 2, base = 16;
f01015f1:	83 c2 02             	add    $0x2,%edx
f01015f4:	bb 10 00 00 00       	mov    $0x10,%ebx
f01015f9:	eb 10                	jmp    f010160b <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f01015fb:	85 db                	test   %ebx,%ebx
f01015fd:	75 0c                	jne    f010160b <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01015ff:	b3 0a                	mov    $0xa,%bl
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101601:	80 3a 30             	cmpb   $0x30,(%edx)
f0101604:	75 05                	jne    f010160b <strtol+0x6a>
		s++, base = 8;
f0101606:	83 c2 01             	add    $0x1,%edx
f0101609:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f010160b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101610:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101613:	0f b6 0a             	movzbl (%edx),%ecx
f0101616:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0101619:	89 f3                	mov    %esi,%ebx
f010161b:	80 fb 09             	cmp    $0x9,%bl
f010161e:	77 08                	ja     f0101628 <strtol+0x87>
			dig = *s - '0';
f0101620:	0f be c9             	movsbl %cl,%ecx
f0101623:	83 e9 30             	sub    $0x30,%ecx
f0101626:	eb 22                	jmp    f010164a <strtol+0xa9>
		else if (*s >= 'a' && *s <= 'z')
f0101628:	8d 71 9f             	lea    -0x61(%ecx),%esi
f010162b:	89 f3                	mov    %esi,%ebx
f010162d:	80 fb 19             	cmp    $0x19,%bl
f0101630:	77 08                	ja     f010163a <strtol+0x99>
			dig = *s - 'a' + 10;
f0101632:	0f be c9             	movsbl %cl,%ecx
f0101635:	83 e9 57             	sub    $0x57,%ecx
f0101638:	eb 10                	jmp    f010164a <strtol+0xa9>
		else if (*s >= 'A' && *s <= 'Z')
f010163a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f010163d:	89 f3                	mov    %esi,%ebx
f010163f:	80 fb 19             	cmp    $0x19,%bl
f0101642:	77 16                	ja     f010165a <strtol+0xb9>
			dig = *s - 'A' + 10;
f0101644:	0f be c9             	movsbl %cl,%ecx
f0101647:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f010164a:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f010164d:	7d 0f                	jge    f010165e <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f010164f:	83 c2 01             	add    $0x1,%edx
f0101652:	0f af 45 f0          	imul   -0x10(%ebp),%eax
f0101656:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0101658:	eb b9                	jmp    f0101613 <strtol+0x72>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f010165a:	89 c1                	mov    %eax,%ecx
f010165c:	eb 02                	jmp    f0101660 <strtol+0xbf>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f010165e:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0101660:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101664:	74 05                	je     f010166b <strtol+0xca>
		*endptr = (char *) s;
f0101666:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101669:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f010166b:	85 ff                	test   %edi,%edi
f010166d:	74 04                	je     f0101673 <strtol+0xd2>
f010166f:	89 c8                	mov    %ecx,%eax
f0101671:	f7 d8                	neg    %eax
}
f0101673:	83 c4 04             	add    $0x4,%esp
f0101676:	5b                   	pop    %ebx
f0101677:	5e                   	pop    %esi
f0101678:	5f                   	pop    %edi
f0101679:	5d                   	pop    %ebp
f010167a:	c3                   	ret    
f010167b:	00 00                	add    %al,(%eax)
f010167d:	00 00                	add    %al,(%eax)
	...

f0101680 <__udivdi3>:
f0101680:	83 ec 1c             	sub    $0x1c,%esp
f0101683:	8b 44 24 2c          	mov    0x2c(%esp),%eax
f0101687:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f010168b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f010168f:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0101693:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101697:	8b 74 24 24          	mov    0x24(%esp),%esi
f010169b:	85 c0                	test   %eax,%eax
f010169d:	89 7c 24 14          	mov    %edi,0x14(%esp)
f01016a1:	89 cf                	mov    %ecx,%edi
f01016a3:	89 6c 24 04          	mov    %ebp,0x4(%esp)
f01016a7:	75 37                	jne    f01016e0 <__udivdi3+0x60>
f01016a9:	39 f1                	cmp    %esi,%ecx
f01016ab:	77 73                	ja     f0101720 <__udivdi3+0xa0>
f01016ad:	85 c9                	test   %ecx,%ecx
f01016af:	75 0b                	jne    f01016bc <__udivdi3+0x3c>
f01016b1:	b8 01 00 00 00       	mov    $0x1,%eax
f01016b6:	31 d2                	xor    %edx,%edx
f01016b8:	f7 f1                	div    %ecx
f01016ba:	89 c1                	mov    %eax,%ecx
f01016bc:	89 f0                	mov    %esi,%eax
f01016be:	31 d2                	xor    %edx,%edx
f01016c0:	f7 f1                	div    %ecx
f01016c2:	89 c6                	mov    %eax,%esi
f01016c4:	89 e8                	mov    %ebp,%eax
f01016c6:	f7 f1                	div    %ecx
f01016c8:	89 f2                	mov    %esi,%edx
f01016ca:	8b 74 24 10          	mov    0x10(%esp),%esi
f01016ce:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01016d2:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01016d6:	83 c4 1c             	add    $0x1c,%esp
f01016d9:	c3                   	ret    
f01016da:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01016e0:	39 f0                	cmp    %esi,%eax
f01016e2:	77 24                	ja     f0101708 <__udivdi3+0x88>
f01016e4:	0f bd e8             	bsr    %eax,%ebp
f01016e7:	83 f5 1f             	xor    $0x1f,%ebp
f01016ea:	75 4c                	jne    f0101738 <__udivdi3+0xb8>
f01016ec:	31 d2                	xor    %edx,%edx
f01016ee:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
f01016f2:	0f 86 b0 00 00 00    	jbe    f01017a8 <__udivdi3+0x128>
f01016f8:	39 f0                	cmp    %esi,%eax
f01016fa:	0f 82 a8 00 00 00    	jb     f01017a8 <__udivdi3+0x128>
f0101700:	31 c0                	xor    %eax,%eax
f0101702:	eb c6                	jmp    f01016ca <__udivdi3+0x4a>
f0101704:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101708:	31 d2                	xor    %edx,%edx
f010170a:	31 c0                	xor    %eax,%eax
f010170c:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101710:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101714:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101718:	83 c4 1c             	add    $0x1c,%esp
f010171b:	c3                   	ret    
f010171c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101720:	89 e8                	mov    %ebp,%eax
f0101722:	89 f2                	mov    %esi,%edx
f0101724:	f7 f1                	div    %ecx
f0101726:	31 d2                	xor    %edx,%edx
f0101728:	8b 74 24 10          	mov    0x10(%esp),%esi
f010172c:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101730:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101734:	83 c4 1c             	add    $0x1c,%esp
f0101737:	c3                   	ret    
f0101738:	89 e9                	mov    %ebp,%ecx
f010173a:	89 fa                	mov    %edi,%edx
f010173c:	d3 e0                	shl    %cl,%eax
f010173e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101742:	b8 20 00 00 00       	mov    $0x20,%eax
f0101747:	29 e8                	sub    %ebp,%eax
f0101749:	89 c1                	mov    %eax,%ecx
f010174b:	d3 ea                	shr    %cl,%edx
f010174d:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0101751:	09 ca                	or     %ecx,%edx
f0101753:	89 e9                	mov    %ebp,%ecx
f0101755:	d3 e7                	shl    %cl,%edi
f0101757:	89 c1                	mov    %eax,%ecx
f0101759:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010175d:	89 f2                	mov    %esi,%edx
f010175f:	d3 ea                	shr    %cl,%edx
f0101761:	89 e9                	mov    %ebp,%ecx
f0101763:	89 14 24             	mov    %edx,(%esp)
f0101766:	8b 54 24 04          	mov    0x4(%esp),%edx
f010176a:	d3 e6                	shl    %cl,%esi
f010176c:	89 c1                	mov    %eax,%ecx
f010176e:	d3 ea                	shr    %cl,%edx
f0101770:	89 d0                	mov    %edx,%eax
f0101772:	09 f0                	or     %esi,%eax
f0101774:	8b 34 24             	mov    (%esp),%esi
f0101777:	89 f2                	mov    %esi,%edx
f0101779:	f7 74 24 0c          	divl   0xc(%esp)
f010177d:	89 d6                	mov    %edx,%esi
f010177f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101783:	f7 e7                	mul    %edi
f0101785:	39 d6                	cmp    %edx,%esi
f0101787:	72 2f                	jb     f01017b8 <__udivdi3+0x138>
f0101789:	8b 7c 24 04          	mov    0x4(%esp),%edi
f010178d:	89 e9                	mov    %ebp,%ecx
f010178f:	d3 e7                	shl    %cl,%edi
f0101791:	39 c7                	cmp    %eax,%edi
f0101793:	73 04                	jae    f0101799 <__udivdi3+0x119>
f0101795:	39 d6                	cmp    %edx,%esi
f0101797:	74 1f                	je     f01017b8 <__udivdi3+0x138>
f0101799:	8b 44 24 08          	mov    0x8(%esp),%eax
f010179d:	31 d2                	xor    %edx,%edx
f010179f:	e9 26 ff ff ff       	jmp    f01016ca <__udivdi3+0x4a>
f01017a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01017a8:	b8 01 00 00 00       	mov    $0x1,%eax
f01017ad:	e9 18 ff ff ff       	jmp    f01016ca <__udivdi3+0x4a>
f01017b2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01017b8:	8b 44 24 08          	mov    0x8(%esp),%eax
f01017bc:	31 d2                	xor    %edx,%edx
f01017be:	83 e8 01             	sub    $0x1,%eax
f01017c1:	8b 74 24 10          	mov    0x10(%esp),%esi
f01017c5:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01017c9:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01017cd:	83 c4 1c             	add    $0x1c,%esp
f01017d0:	c3                   	ret    
	...

f01017e0 <__umoddi3>:
f01017e0:	83 ec 1c             	sub    $0x1c,%esp
f01017e3:	8b 54 24 2c          	mov    0x2c(%esp),%edx
f01017e7:	8b 44 24 20          	mov    0x20(%esp),%eax
f01017eb:	89 74 24 10          	mov    %esi,0x10(%esp)
f01017ef:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f01017f3:	8b 74 24 24          	mov    0x24(%esp),%esi
f01017f7:	85 d2                	test   %edx,%edx
f01017f9:	89 7c 24 14          	mov    %edi,0x14(%esp)
f01017fd:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101801:	89 cf                	mov    %ecx,%edi
f0101803:	89 c5                	mov    %eax,%ebp
f0101805:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101809:	89 34 24             	mov    %esi,(%esp)
f010180c:	75 22                	jne    f0101830 <__umoddi3+0x50>
f010180e:	39 f1                	cmp    %esi,%ecx
f0101810:	76 56                	jbe    f0101868 <__umoddi3+0x88>
f0101812:	89 f2                	mov    %esi,%edx
f0101814:	f7 f1                	div    %ecx
f0101816:	89 d0                	mov    %edx,%eax
f0101818:	31 d2                	xor    %edx,%edx
f010181a:	8b 74 24 10          	mov    0x10(%esp),%esi
f010181e:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101822:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101826:	83 c4 1c             	add    $0x1c,%esp
f0101829:	c3                   	ret    
f010182a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101830:	39 f2                	cmp    %esi,%edx
f0101832:	77 54                	ja     f0101888 <__umoddi3+0xa8>
f0101834:	0f bd c2             	bsr    %edx,%eax
f0101837:	83 f0 1f             	xor    $0x1f,%eax
f010183a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010183e:	75 60                	jne    f01018a0 <__umoddi3+0xc0>
f0101840:	39 e9                	cmp    %ebp,%ecx
f0101842:	0f 87 08 01 00 00    	ja     f0101950 <__umoddi3+0x170>
f0101848:	29 cd                	sub    %ecx,%ebp
f010184a:	19 d6                	sbb    %edx,%esi
f010184c:	89 34 24             	mov    %esi,(%esp)
f010184f:	8b 14 24             	mov    (%esp),%edx
f0101852:	89 e8                	mov    %ebp,%eax
f0101854:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101858:	8b 7c 24 14          	mov    0x14(%esp),%edi
f010185c:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101860:	83 c4 1c             	add    $0x1c,%esp
f0101863:	c3                   	ret    
f0101864:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101868:	85 c9                	test   %ecx,%ecx
f010186a:	75 0b                	jne    f0101877 <__umoddi3+0x97>
f010186c:	b8 01 00 00 00       	mov    $0x1,%eax
f0101871:	31 d2                	xor    %edx,%edx
f0101873:	f7 f1                	div    %ecx
f0101875:	89 c1                	mov    %eax,%ecx
f0101877:	89 f0                	mov    %esi,%eax
f0101879:	31 d2                	xor    %edx,%edx
f010187b:	f7 f1                	div    %ecx
f010187d:	89 e8                	mov    %ebp,%eax
f010187f:	f7 f1                	div    %ecx
f0101881:	eb 93                	jmp    f0101816 <__umoddi3+0x36>
f0101883:	90                   	nop
f0101884:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101888:	89 f2                	mov    %esi,%edx
f010188a:	8b 74 24 10          	mov    0x10(%esp),%esi
f010188e:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101892:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101896:	83 c4 1c             	add    $0x1c,%esp
f0101899:	c3                   	ret    
f010189a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01018a0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01018a5:	bd 20 00 00 00       	mov    $0x20,%ebp
f01018aa:	89 f8                	mov    %edi,%eax
f01018ac:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f01018b0:	d3 e2                	shl    %cl,%edx
f01018b2:	89 e9                	mov    %ebp,%ecx
f01018b4:	d3 e8                	shr    %cl,%eax
f01018b6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01018bb:	09 d0                	or     %edx,%eax
f01018bd:	89 f2                	mov    %esi,%edx
f01018bf:	89 04 24             	mov    %eax,(%esp)
f01018c2:	8b 44 24 08          	mov    0x8(%esp),%eax
f01018c6:	d3 e7                	shl    %cl,%edi
f01018c8:	89 e9                	mov    %ebp,%ecx
f01018ca:	d3 ea                	shr    %cl,%edx
f01018cc:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01018d1:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01018d5:	d3 e6                	shl    %cl,%esi
f01018d7:	89 e9                	mov    %ebp,%ecx
f01018d9:	d3 e8                	shr    %cl,%eax
f01018db:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01018e0:	09 f0                	or     %esi,%eax
f01018e2:	8b 74 24 08          	mov    0x8(%esp),%esi
f01018e6:	f7 34 24             	divl   (%esp)
f01018e9:	d3 e6                	shl    %cl,%esi
f01018eb:	89 74 24 08          	mov    %esi,0x8(%esp)
f01018ef:	89 d6                	mov    %edx,%esi
f01018f1:	f7 e7                	mul    %edi
f01018f3:	39 d6                	cmp    %edx,%esi
f01018f5:	89 c7                	mov    %eax,%edi
f01018f7:	89 d1                	mov    %edx,%ecx
f01018f9:	72 41                	jb     f010193c <__umoddi3+0x15c>
f01018fb:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01018ff:	72 37                	jb     f0101938 <__umoddi3+0x158>
f0101901:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101905:	29 f8                	sub    %edi,%eax
f0101907:	19 ce                	sbb    %ecx,%esi
f0101909:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010190e:	89 f2                	mov    %esi,%edx
f0101910:	d3 e8                	shr    %cl,%eax
f0101912:	89 e9                	mov    %ebp,%ecx
f0101914:	d3 e2                	shl    %cl,%edx
f0101916:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010191b:	09 d0                	or     %edx,%eax
f010191d:	89 f2                	mov    %esi,%edx
f010191f:	d3 ea                	shr    %cl,%edx
f0101921:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101925:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101929:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010192d:	83 c4 1c             	add    $0x1c,%esp
f0101930:	c3                   	ret    
f0101931:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101938:	39 d6                	cmp    %edx,%esi
f010193a:	75 c5                	jne    f0101901 <__umoddi3+0x121>
f010193c:	89 d1                	mov    %edx,%ecx
f010193e:	89 c7                	mov    %eax,%edi
f0101940:	2b 7c 24 0c          	sub    0xc(%esp),%edi
f0101944:	1b 0c 24             	sbb    (%esp),%ecx
f0101947:	eb b8                	jmp    f0101901 <__umoddi3+0x121>
f0101949:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101950:	39 f2                	cmp    %esi,%edx
f0101952:	0f 82 f0 fe ff ff    	jb     f0101848 <__umoddi3+0x68>
f0101958:	e9 f2 fe ff ff       	jmp    f010184f <__umoddi3+0x6f>
