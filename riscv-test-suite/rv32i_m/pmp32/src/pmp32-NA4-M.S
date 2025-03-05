// ---------------------------------------------------------------------------
// pmp 32 NA4 M-mode tests 
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
/*
Following are defined in the model_test.h. If you have different implementation for PMP, please change accordingly in that file.
*/

#ifndef RVMODEL_PMP_GRAIN
	#define RVMODEL_PMP_GRAIN 0
#endif

#ifndef RVMODEL_NUM_PMPS
	#define RVMODEL_NUM_PMPS 16
#endif

RVTEST_CASE(1,"//check ISA:=regex(.*32.*); check ISA:=regex(.*I.*Zicsr.*); def rvtest_mtrap_routine=True; verify (PMP['implemented']); verify (PMP['pmp-grain'] == 0); def TEST_CASE_1=True; mac PMP_MACROS",PMP_NA4_M)

#ifdef TEST_CASE_1
RVTEST_SIGBASE( x13,signature_x13_1)
	.attribute unaligned_access, 0
	.attribute stack_align, 16
  	.align 2
  	.option norvc

#define NOP (0x13)  // Encoded Instruction of nop (32-bit case)

/*
 * VERIFICATION_RWX Macro
 *
 * Description:
 * This macro performs comprehensive verification of Read, Write, and Execute (RWX) permissions for a given memory address.
 * It is designed to test the functionality and enforcement of PMP (Physical Memory Protection) configurations by checking access
 * permission at various granularity levels (byte, half-word, word, and double word) and for both load and store operations.
 *
 * Parameters:
 * - ADDRESS: The memory address to be tested for RWX access rights.
 *
 * Notes:
 * - The macro assumes proper PMP configuration is in place to validate the described behaviors.
 * - For double-word store and load operations, it adheres to the RISC-V Privileged Specification v1.12, ensuring the correct handling of boundary conditions.
 */

.macro VERIFICATION_RWX ADDRESS
    // Execution Access Check
    LA (a4, RETURN_INSTRUCTION)
    addi a4, a4, -4
    jalr a4
    nop
    nop

    // Store Access Check
    LA(a5, \ADDRESS)
    LI(a4, NOP)
    sb a4, 0(a5)
    nop
    sh a4, 0(a5)
    nop
    sw a4, 0(a5)
    nop

    // Load Access Check
    lb a4, 0(a5)
    RVTEST_SIGUPD(x13, a4)
    lh a4, 0(a5)
    RVTEST_SIGUPD(x13, a4)
    lw a4, 0(a5)
    RVTEST_SIGUPD(x13, a4)
.endm


main:
	// Clear all PMP registers
	.set pmpcfgi, CSR_PMPCFG0
	.rept RVMODEL_NUM_PMPS/4
	csrw pmpcfgi, x0
	.set pmpcfgi, pmpcfgi+1
	.endr

	.set pmpaddri, CSR_PMPADDR0
	.rept RVMODEL_NUM_PMPS
	csrw pmpaddri, x0
	.set pmpaddri, pmpaddri+1
	.endr

/*
	PMP configurations selection
	MACROS TO DECLARE THE VALUES TO BE STORED IN PMPCFG registers
*/

#define PMP_REGION_GLOBAL (((PMP_L|PMP_R|PMP_W|PMP_X|PMP_TOR)&0xFF) << PMP3_CFG_SHIFT)
#define PMPREGIONRWX ((PMP_L|PMP_R|PMP_W|PMP_X|PMP_NA4)&0xFF)
#define PMPREGIONRX ((PMP_L|PMP_R|PMP_X|PMP_NA4)&0xFF)
#define PMPREGIONRW ((PMP_L|PMP_R|PMP_W|PMP_NA4)&0xFF)
#define PMPREGIONR ((PMP_L|PMP_R|PMP_NA4)&0xFF)
#define PMPREGIONX ((PMP_L|PMP_X|PMP_NA4)&0xFF)

/*
	PMP address selection
	MACROS TO DECLARE THE VALUES TO BE STORED IN PMPADDR registers
*/
#define PMPADDRESS15_GLOBAL		-1														//All memory region
#define PMPADDRESS14_GLOBAL		0x0														//Base address
#define PMPADDRESS_TEST			TEST_FOR_EXECUTION 
//											Test Setup Section
	csrw satp, x0																		// Disable Address Translation

	LA(x4, PMPADDRESS15_GLOBAL)
	srl x4, x4, PMP_SHIFT
	csrw 	pmpaddr7, x4

	LA(x4, PMPADDRESS14_GLOBAL)
	srl x4, x4, PMP_SHIFT
	csrw 	pmpaddr6, x4

//											Verification Section
//Test Case: 1 -- RWX Permissions given to the PMP Region.

	LA(x4, PMPADDRESS_TEST)
	srl x4, x4, PMP_SHIFT
	csrw 	pmpaddr5, x4

	LI(x4, PMP_REGION_GLOBAL | ((PMPREGIONRWX) << PMP2_CFG_SHIFT))
	csrw pmpcfg1, x4

	VERIFICATION_RWX	TEST_FOR_EXECUTION


//Test Case: 2 -- RX Permissions given to the PMP Region.

	LA(x4, PMPADDRESS_TEST)
	srl x4, x4, PMP_SHIFT
	csrw 	pmpaddr4, x4

	LI(x4, PMP_REGION_GLOBAL | ((PMPREGIONRX) << PMP1_CFG_SHIFT))
	csrw pmpcfg1, x4

	VERIFICATION_RWX	TEST_FOR_EXECUTION


//Test Case: 3 -- RW Permissions given to the PMP Region.

	LA(x4, PMPADDRESS_TEST)
	srl x4, x4, PMP_SHIFT
	csrw 	pmpaddr3, x4

	LI(x4, PMP_REGION_GLOBAL | ((PMPREGIONRW) << PMP0_CFG_SHIFT))
	csrw pmpcfg1, x4

	VERIFICATION_RWX	TEST_FOR_EXECUTION


//Test Case: 4 -- R Permissions given to the PMP Region.

	LA(x4, PMPADDRESS_TEST)
	srl x4, x4, PMP_SHIFT
	csrw 	pmpaddr2, x4

	LI(x4, ((PMPREGIONR) << PMP3_CFG_SHIFT))
	csrw pmpcfg0, x4
	
	VERIFICATION_RWX	TEST_FOR_EXECUTION


//Test Case: 5 -- X Permissions given to the PMP Region.

	LA(x4, PMPADDRESS_TEST)
	srl x4, x4, PMP_SHIFT
	csrw 	pmpaddr1, x4

	LI(x4, ((PMPREGIONX) << PMP2_CFG_SHIFT))
	csrw pmpcfg0, x4

	VERIFICATION_RWX	TEST_FOR_EXECUTION


	li a4, 0xbeefcafe											//Clean Test exit verification signature.
    RVTEST_SIGUPD(x13, a4)       								// Signature update
	j exit														//Verification Complete, exit the test

/*
	Following section is selected based on the minimum PMP granularity set by the user.
	Please change in model_test.h to change it here.
*/

.align 2
TEST_FOR_EXECUTION:
	.rept (1<<RVMODEL_PMP_GRAIN)
	nop
	.endr

RETURN_INSTRUCTION:
nop
jr ra													// Get back to the point from where TEST_FOR_EXECUTION was called.

exit:
#endif
RVTEST_CODE_END
RVMODEL_HALT
RVTEST_DATA_BEGIN
.align 4
rvtest_data:
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
PMP_region_High:
RVMODEL_DATA_END
