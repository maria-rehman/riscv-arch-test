// ---------------------------------------------------------------------------/
// pmp32 NAPOT Umode
// Description : This test verifies the functionality and enforcement of
//               Physical Memory Protection (PMP) configurations in RISC-V
//               systems. It evaluates RWX permissions at different granularity
//               levels (byte, half-word, word) and across various
//               PMP configurations. The test adheres to the RISC-V Privileged
//               Specification and includes:
//               - Comprehensive RWX checks for multiple PMP regions.
//
// Notes       : - Ensure model_test.h is configured to match your PMP grain
//                 and PMP region count before running this test.
//               - Adjust PMP configurations for specific hardware if required.
//
// Test Cases  : 1. Full RWX permissions (Read, Write, Execute)
//               2. RX permissions (Read, Execute)
//               3. RW permissions (Read, Write)
//               4. R-only permissions (Read)
//               5. X-only permissions (Execute)
//
// Dependencies: model_test.h, arch_test.h
// ---------------------------------------------------------------------------

#include "model_test.h"
#include "arch_test.h"
RVTEST_ISA("RV32I_Zicsr")

# Test code region
.section .text.init
.globl rvtest_entry_point
rvtest_entry_point:
RVMODEL_BOOT
RVTEST_CODE_BEGIN

#ifndef RVMODEL_PMP_GRAIN
	#define RVMODEL_PMP_GRAIN 0
#endif

#ifndef RVMODEL_NUM_PMPS
	#define RVMODEL_NUM_PMPS 16
#endif

RVTEST_CASE(1,"//check ISA:=regex(.*32.*); check ISA:=regex(.*I.*S.*Zicsr.*); def rvtest_mtrap_routine=True; verify (PMP['implemented']); verify (PMP['pmp-grain'] == 0); def TEST_CASE_1=True; mac PMP_MACROS",PMP_NAPOT_S_U)

#ifdef TEST_CASE_1
RVTEST_SIGBASE( x13,signature_x13_1)
	.attribute unaligned_access, 0
	.attribute stack_align, 16
  	.align	3
  	.option norvc

#define NOP 	0x13									// Encoded NOP instruction for RV32

.macro VERIFICATION_RWX ADDRESS
    // Execution Access Check
    LA (a4, RETURN_INSTRUCTION)
    addi a4, a4, -4              						// Adjust return address
    jalr a4                      						// Jump to test address
    nop                          						// Trap skip
    nop

    // Store Access Check
    LA(a5, \ADDRESS)             						// Target address
    LI(a4, NOP)                  						// NOP value
    sb a4, 0(a5)                 						// Byte store
    nop
    nop
    sh a4, 0(a5)                 						// Half-word store
    nop
    nop
    sw a4, 0(a5)                 						// Word store
    nop
    nop

    // Load Access Check
    lb a4, 0(a5)                 						// Byte load
    nop
    nop
    RVTEST_SIGUPD(x13, a4)       						// Update signature
    lh a4, 0(a5)                 						// Half-word load
    nop
    nop
    RVTEST_SIGUPD(x13, a4)       						// Update signature
    lw a4, 0(a5)                 						// Word load
    nop
    nop
    RVTEST_SIGUPD(x13, a4)       						// Update signature
.endm

main:
	// Initialize PMP registers
	.set pmpcfgi, CSR_PMPCFG0
	.rept RVMODEL_NUM_PMPS/4
	csrw pmpcfgi , x0
	.set pmpcfgi, pmpcfgi+1
	.endr

	.set pmpaddri, CSR_PMPADDR0
	.rept RVMODEL_NUM_PMPS
	csrw pmpaddri, x0
	.set pmpaddri, pmpaddri+1
	.endr

// PMP configuration macros
#define PMP_REGION_GLOBAL	((PMP_L|PMP_R|PMP_W|PMP_X|PMP_TOR) << 24)
#define PMPREGIONRWX      	(PMP_R|PMP_W|PMP_X|PMP_NAPOT)
#define PMPREGIONRX      	(PMP_R|	  PMP_X|PMP_NAPOT)
#define PMPREGIONRW      	(PMP_R|PMP_W|	PMP_NAPOT)
#define PMPREGIONR      	(PMP_R|	  	PMP_NAPOT)
#define PMPREGIONX      	(		   PMP_X|PMP_NAPOT)

// Address configuration
#define PMPADDRESS15_GLOBAL		-1
#define PMPADDRESS14_GLOBAL		0x0
#define PMPADDRESS_TEST			TEST_FOR_EXECUTION
#define PMP_REGION_SIZE 		(1 << (RVMODEL_PMP_GRAIN - 1)) - 1
#define PMP_MASK				~(1 << (RVMODEL_PMP_GRAIN - 1))

	csrw satp, x0									// Disable MMU

	// Configure global regions
	LA(x4, PMPADDRESS15_GLOBAL)
	srl x4, x4, PMP_SHIFT
	csrw pmpaddr15, x4

	LA(x4, PMPADDRESS14_GLOBAL)
	srl x4, x4, PMP_SHIFT
	csrw pmpaddr14, x4

// Test Case 1: RWX Permissions
	LA(x4, PMPADDRESS_TEST)
	srl x4, x4, PMP_SHIFT
.if RVMODEL_PMP_GRAIN != 0
	li t0, PMP_MASK
	and x4, x4, t0
	li t0, PMP_REGION_SIZE
	or x4, x4, t0
.endif
	csrw pmpaddr13, x4
	LI(x4, PMP_REGION_GLOBAL | (PMPREGIONRWX << 8))
	csrw pmpcfg3, x4
	
	RVTEST_GOTO_LOWER_MODE	Umode
	VERIFICATION_RWX	TEST_FOR_EXECUTION

	RVTEST_GOTO_MMODE
	
// Test Case 2: RX Permissions
	LA(x4, PMPADDRESS_TEST)
	srl x4, x4, PMP_SHIFT
.if RVMODEL_PMP_GRAIN != 0
	li t0, PMP_MASK
	and x4, x4, t0
	li t0, PMP_REGION_SIZE
	or x4, x4, t0
.endif
	csrw pmpaddr12, x4
	LI(x4, PMP_REGION_GLOBAL | (PMPREGIONRX << 0))
	csrw pmpcfg3, x4
	
	RVTEST_GOTO_LOWER_MODE	Umode
	VERIFICATION_RWX	TEST_FOR_EXECUTION
	
	RVTEST_GOTO_MMODE
	

// Test Case 3: RW Permissions
	LA(x4, PMPADDRESS_TEST)
	srl x4, x4, PMP_SHIFT
.if RVMODEL_PMP_GRAIN != 0
	li t0, PMP_MASK
	and x4, x4, t0
	li t0, PMP_REGION_SIZE
	or x4, x4, t0
.endif
	csrw pmpaddr11, x4
	LI(x4, (PMPREGIONRW << 24))
	csrw pmpcfg2, x4
		
	RVTEST_GOTO_LOWER_MODE	Umode
	VERIFICATION_RWX	TEST_FOR_EXECUTION

	RVTEST_GOTO_MMODE

// Test Case 4: R-only Permissions
	LA(x4, PMPADDRESS_TEST)
	srl x4, x4, PMP_SHIFT
.if RVMODEL_PMP_GRAIN != 0
	li t0, PMP_MASK
	and x4, x4, t0
	li t0, PMP_REGION_SIZE
	or x4, x4, t0
.endif
	csrw pmpaddr10, x4
	LI(x4, (PMPREGIONR << 16))
	csrw pmpcfg2, x4
		
	RVTEST_GOTO_LOWER_MODE	Umode
	VERIFICATION_RWX	TEST_FOR_EXECUTION

	RVTEST_GOTO_MMODE

// Test Case 5: X-only Permissions
	LA(x4, PMPADDRESS_TEST)
	srl x4, x4, PMP_SHIFT
.if RVMODEL_PMP_GRAIN != 0
	li t0, PMP_MASK
	and x4, x4, t0
	li t0, PMP_REGION_SIZE
	or x4, x4, t0
.endif
	csrw pmpaddr9, x4
	LI(x4, (PMPREGIONX << 8))
	csrw pmpcfg2, x4
	
	RVTEST_GOTO_LOWER_MODE	Umode
	VERIFICATION_RWX	TEST_FOR_EXECUTION

	RVTEST_GOTO_MMODE

	li a4, 0xbeefcafe								// Final signature
    RVTEST_SIGUPD(x13, a4)
	j exit

.align 3
.align (RVMODEL_PMP_GRAIN+2)
TEST_FOR_EXECUTION:
	.rept (1<<RVMODEL_PMP_GRAIN)
	nop
	.endr
.if RVMODEL_PMP_GRAIN == 0
    nop
.endif

RETURN_INSTRUCTION:
	nop
	nop
	jr ra

exit:
#endif
RVTEST_CODE_END
RVMODEL_HALT

RVTEST_DATA_BEGIN
.align 4
rvtest_data:
.word 0xbabecafe
.word 0xbabecafe
.word 0xbabecafe
.word 0xbabecafe
RVTEST_DATA_END

RVMODEL_DATA_BEGIN
rvtest_sig_begin:
sig_begin_canary:
CANARY;
signature_x13_1:
    .fill 32*(XLEN/32),4,0xdeadbeef

#ifdef rvtest_mtrap_routine
tsig_begin_canary:
CANARY;
mtrap_sigptr:
    .fill 128*(XLEN/32),4,0xdeadbeef
tsig_end_canary:
CANARY;
#endif

#ifdef rvtest_gpr_save
gpr_save:
    .fill 32*(XLEN/32),4,0xdeadbeef
#endif

sig_end_canary:
CANARY;
rvtest_sig_end:
RVMODEL_DATA_END
