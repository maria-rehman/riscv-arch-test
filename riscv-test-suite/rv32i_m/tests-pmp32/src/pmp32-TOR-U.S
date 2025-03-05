// ---------------------------------------------------------------------------
// pmp32 U mode TOR
// Title        : Comprehensive PMP (Physical Memory Protection) Verification
//
// Description : This test verifies the functionality and enforcement of
//               Physical Memory Protection (PMP) configurations in RISC-V
//               systems. It evaluates RWX permissions at different granularity
//               levels (byte, half-word, word) and across various
//               PMP configurations. The test adheres to the RISC-V Privileged
//               Specification and includes:
//               - Comprehensive RWX checks for multiple PMP regions.
//
// Notes       : - Ensure `model_test.h` is configured to match your PMP grain
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

RVTEST_CASE(1,"//check ISA:=regex(.*32.*); check ISA:=regex(.*I.*S.*Zicsr.*); def rvtest_mtrap_routine=True; def rvtest_strap_routine=True; verify (PMP['implemented']); def TEST_CASE_1=True; mac PMP_MACROS",PMP_TOR_S_U)

#ifdef TEST_CASE_1
RVTEST_SIGBASE( x13,signature_x13_1)
    .attribute unaligned_access, 0
    .attribute stack_align, 16
    .align 3
    .option norvc

#define NOP 0x13  // 32-bit NOP encoding

/*
 * VERIFICATION_RWX Macro (32-bit adaptation)
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
    nop
    sh a4, 0(a5)
    nop
    nop
    sw a4, 0(a5)
    nop
    nop

    // Load Access Check
    lb a4, 0(a5)
    nop
    nop
    RVTEST_SIGUPD(x13, a4)
    lh a4, 0(a5)
    nop
    nop
    RVTEST_SIGUPD(x13, a4)
    lw a4, 0(a5)
    nop
    nop
    RVTEST_SIGUPD(x13, a4)
.endm

main:
    // Initialize PMP registers (32-bit style)
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

// PMP Configuration Macros (32-bit adjusted)
#define PMP_REGION_GLOBAL ((PMP_L|PMP_R|PMP_W|PMP_X|PMP_TOR) << 24)
#define PMPREGIONRWX      ((PMP_R|PMP_W|PMP_X|PMP_TOR) << 8)
#define PMPREGIONRX       ((PMP_R|PMP_X|PMP_TOR) << 8)
#define PMPREGIONRW       ((PMP_R|PMP_W|PMP_TOR) << 8)
#define PMPREGIONR        ((PMP_R|PMP_TOR) << 8)
#define PMPREGIONX        ((PMP_X|PMP_TOR) << 8)

// Address configuration
#define PMPADDRESS15_GLOBAL -1
#define PMPADDRESS14_GLOBAL 0x0
#define PMPADDRESS1         RETURN_INSTRUCTION
#define PMPADDRESS0         TEST_FOR_EXECUTION

    csrw satp, x0  // Disable MMU

    // Configure global regions
    LA(x4, PMPADDRESS15_GLOBAL)
    srl x4, x4, PMP_SHIFT
    csrw pmpaddr15, x4

    LA(x4, PMPADDRESS14_GLOBAL)
    srl x4, x4, PMP_SHIFT
    csrw pmpaddr14, x4

    LA(x4, PMPADDRESS1)
    srl x4, x4, PMP_SHIFT
    csrw pmpaddr1, x4

    LA(x4, PMPADDRESS0)
    srl x4, x4, PMP_SHIFT
    csrw pmpaddr0, x4

// Test Case 1: RWX Permissions
    LI(x4, PMP_REGION_GLOBAL)
    csrw pmpcfg3, x4

    LI(x4, PMPREGIONRWX)
    csrw pmpcfg0, x4

    RVTEST_GOTO_LOWER_MODE Umode
    VERIFICATION_RWX TEST_FOR_EXECUTION
    RVTEST_GOTO_MMODE

// Test Case 2: RX Permissions
    LI(x4, PMP_REGION_GLOBAL)
    csrw pmpcfg3, x4

    LI(x4, PMPREGIONRX)
    csrw pmpcfg0, x4

    RVTEST_GOTO_LOWER_MODE Umode
    VERIFICATION_RWX TEST_FOR_EXECUTION
    RVTEST_GOTO_MMODE

// Test Case 3: RW Permissions
    LI(x4, PMP_REGION_GLOBAL)
    csrw pmpcfg3, x4

    LI(x4, PMPREGIONRW)
    csrw pmpcfg0, x4

    RVTEST_GOTO_LOWER_MODE Umode
    VERIFICATION_RWX TEST_FOR_EXECUTION
    RVTEST_GOTO_MMODE

// Test Case 4: R-only Permissions
    LI(x4, PMP_REGION_GLOBAL)
    csrw pmpcfg3, x4

    LI(x4, PMPREGIONR)
    csrw pmpcfg0, x4

    RVTEST_GOTO_LOWER_MODE Umode
    VERIFICATION_RWX TEST_FOR_EXECUTION
    RVTEST_GOTO_MMODE

// Test Case 5: X-only Permissions
    LI(x4, PMP_REGION_GLOBAL)
    csrw pmpcfg3, x4

    LI(x4, PMPREGIONX)
    csrw pmpcfg0, x4

    RVTEST_GOTO_LOWER_MODE Umode
    VERIFICATION_RWX TEST_FOR_EXECUTION
    RVTEST_GOTO_MMODE

    li a4, 0xbeefcafe  // Final signature
    RVTEST_SIGUPD(x13, a4)
    j exit

.align 3
TEST_FOR_EXECUTION:
    .rept (1<<RVMODEL_PMP_GRAIN)
    nop
    .endr

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
