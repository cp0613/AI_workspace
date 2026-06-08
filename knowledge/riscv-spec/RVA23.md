<table border="1" cellpadding="3">
    <caption><a href="https://github.com/riscv/riscv-profiles">RISC-V Profiles</a> & <a href="https://github.com/riscv/riscv-profiles/blob/main/rva23-profile.adoc">RVA23 Profiles</a></caption>
    <tr>
        <th colspan="3" align="center">RVA</th>
        <th align="center">Extention</th>
        <th align="center">Describe</th>
    </tr>
    <tr>
        <td rowspan="95" align="center">RVA23</td>
        <td rowspan="44" align="center">RVA20U64</td>
        <td rowspan="31" align="center">Mandatory</td>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/rv64.adoc">RV64I</a></td>
        <td>Base Integer Instruction Set.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/m-st-ext.adoc">M</a></td>
        <td>Integer multiplication and division.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/a-st-ext.adoc">A</a></td>
        <td>Atomic instructions.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/f-st-ext.adoc">F</a></td>
        <td>Single-precision floating-point instructions.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/d-st-ext.adoc">D</a></td>
        <td>Double-precision floating-point instructions.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/c-st-ext.adoc">C</a></td>
        <td>Compressed Instructions.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/zicsr.adoc">Zicsr</a></td>
        <td>CSR instructions.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/counters.adoc#zicntr-extension-for-base-counters-and-timers">Zicntr</a></td>
        <td>Basic counters.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/counters.adoc#zihpm-extension-for-hardware-performance-counters">Zihpm</a></td>
        <td>Hardware performance counters.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/zihintpause.adoc">Zihintpause</a></td>
        <td>Pause instruction.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/b-st-ext.adoc#zba-address-generation">Zba</a></td>
        <td>Address computation.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/b-st-ext.adoc#zbb-basic-bit-manipulation">Zbb</a></td>
        <td>Basic bit manipulation.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/b-st-ext.adoc#zbs-single-bit-instructions">Zbs</a></td>
        <td>Single-bit instructions.</td>
    </tr>
    <tr>
        <td>Zic64b</td>
        <td>Cache blocks must be 64 bytes in size, naturally aligned in the address space.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/cmo.adoc">Zicbom</a></td>
        <td>Cache-Block Management Operations.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/cmo.adoc">Zicbop</a></td>
        <td>Cache-Block Prefetch Operations.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/cmo.adoc">Zicboz</a></td>
        <td>Cache-Block Zero Operations.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/zfh.adoc">Zfhmin</a></td>
        <td>Half-Precision Floating-point transfer and convert.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-crypto/blob/main/doc/scalar/riscv-crypto-scalar-zkt.adoc">Zkt</a></td>
        <td>Data-independent execution time.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/v-st-ext.adoc">V</a></td>
        <td>Vector Extension.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/v-st-ext.adoc#zvfhmin-vector-extension-for-minimal-half-precision-floating-point">Zvfhmin</a></td>
        <td>Vector FP16 conversion instructions.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/vector-crypto.adoc#zvbb---vector-basic-bit-manipulation">Zvbb</a></td>
        <td>Vector bit-manipulation instructions.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/vector-crypto.adoc#zvkt---vector-data-independent-execution-latency">Zvkt</a></td>
        <td>Vector data-independent execution time.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/zihintntl.adoc">Zihintntl</a></td>
        <td>Non-temporal locality hints.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/zicond.adoc">Zicond</a></td>
        <td>Conditional Zeroing instructions.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/zimop.adoc">Zimop</a></td>
        <td>Maybe Operations.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/zimop.adoc#zcmop-compressed-may-be-operations-extension-version-10">Zcmop</a></td>
        <td>Compressed Maybe Operations.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/zc.adoc">Zcb</a></td>
        <td>Additional 16b compressed instructions.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/zfa.adoc">Zfa</a></td>
        <td>Additional scalar FP instructions.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/zawrs.adoc">Zawrs</a></td>
        <td>Wait on reservation set.</td>
    </tr>
    <tr>
        <td>Supm</td>
        <td>Pointer masking, with the execution environment providing a means to select PMLEN=0 and PMLEN=7 at minimum.</td>
    </tr>
    <tr>
        <td rowspan="13" align="center">optional</td>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/vector-crypto.adoc#zvkng---nist-algorithm-suite-with-gcm">Zvkng</a></td>
        <td>Vector Crypto NIST Algorithms including GHASH.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/vector-crypto.adoc#zvksg---shangmi-algorithm-suite-with-gcm">Zvksg</a></td>
        <td>Byte and Halfword Atomic Memory Operations.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/zabha.adoc">Zabha</a></td>
        <td>Scalar Crypto NIST Algorithms.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/zacas.adoc">Zacas</a></td>
        <td>Compare-and-swap.</td>
    </tr>
    <tr>
        <td>Ziccamoc</td>
        <td>Main memory regions with both the cacheability and coherence PMAs must provide AMOCASQ level PMA support.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/vector-crypto.adoc#zvbc---vector-carryless-multiplication">Zvbc</a></td>
        <td>Vector carryless multiply.</td>
    </tr>
    <tr>
        <td>Zama16b</td>
        <td>Misaligned loads, stores, and AMOs to main memory regions that do not cross a naturally aligned 16-byte boundary are atomic.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/zfh.adoc">Zfh</a></td>
        <td>Scalar Half-Precision Floating-Point (FP16).</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/b-st-ext.adoc#zbc-carry-less-multiplication">Zbc</a></td>
        <td>Scalar carryless multiply.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/v-st-ext.adoc#zvfh-vector-extension-for-half-precision-floating-point">Zvfh</a></td>
        <td>Vector half-precision floating-point (FP16).</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/bfloat16.adoc#zfbfmin---scalar-bf16-converts">Zfbfmin</a></td>
        <td>Scalar BF16 FP conversions.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/bfloat16.adoc#zvfbfmin---vector-bf16-converts">Zvfbfmin</a></td>
        <td>Vector BF16 FP conversions.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/bfloat16.adoc#zvfbfwma---vector-bf16-widening-mul-add">Zvfbfwma</a></td>
        <td>Vector BF16 widening mul-add.</td>
    </tr>
    <tr>
        <td rowspan="41" align="center">RVA20S64</td>
        <td rowspan="24" align="center">Mandatory</td>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/zifencei.adoc">Zifencei</a></td>
        <td>Instruction-Fetch Fence.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/zifencei.adoc">Ss1p13</a></td>
        <td>Privileged Architecture version 1.13.</td>
    </tr>
    <tr>
        <td>Svbare</td>
        <td>The satp mode Bare must be supported.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/supervisor.adoc#sv39-page-based-39-bit-virtual-memory-system">Sv39</a></td>
        <td>Page-Based 39-bit Virtual-Memory System.</td>
    </tr>
    <tr>
        <td>Svade</td>
        <td>Page-fault exceptions are raised when a page is accessed when A bit is clear, or written when D bit is clear.</td>
    </tr>
    <tr>
        <td>Ssccptr</td>
        <td>Main memory regions with both the cacheability and coherence PMAs must support hardware page-table reads.</td>
    </tr>
    <tr>
        <td>Sstvecd</td>
        <td>stvec.MODE must be capable of holding the value 0 (Direct). When stvec.MODE=Direct, stvec.BASE must be capable of holding any valid four-byte-aligned address.</td>
    </tr>
    <tr>
        <td>Sstvala</td>
        <td>stval must be written with the faulting virtual address for load, store, and instruction page-fault, access-fault, and misaligned exceptions, and for breakpoint exceptions other than those caused by execution of the ebreak or c.ebreak instructions. For illegal-instruction exceptions, stval must be written with the faulting instruction.</td>
    </tr>
    <tr>
        <td>Sscounterenw</td>
        <td>For any hpmcounter that is not read-only zero, the corresponding bit in scounteren must be writable.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/supervisor.adoc#svpbmt-extension-for-page-based-memory-types-version-10">Svpbmt</a></td>
        <td>Page-Based Memory Types.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/supervisor.adoc#svinval-extension-for-fine-grained-address-translation-cache-invalidation-version-10">Svinval</a></td>
        <td>Fine-Grained Address-Translation Cache Invalidation.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/supervisor.adoc#svnapot-extension-for-napot-translation-contiguity-version-10">Svnapot</a></td>
        <td>NAPOT Translation Contiguity.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/sstc.adoc">Sstc</a></td>
        <td>supervisor-mode timer interrupts.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/sscofpmf.adoc">Sscofpmf</a></td>
        <td>Count Overflow and Mode-Based Filtering.</td>
    </tr>
    <tr>
        <td>Ssnpm</td>
        <td>Pointer masking, with senvcfg.PME and henvcfg.PME supporting, at minimum, settings PMLEN=0 and PMLEN=7.</td>
    </tr>
    <tr>
        <td>Ssu64xl</td>
        <td>sstatus.UXL must be capable of holding the value 2 (i.e., UXLEN=64 must be supported).</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/hypervisor.adoc">H</a></td>
        <td>The hypervisor extension.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/smstateen.adoc">Ssstateen</a></td>
        <td>Supervisor-mode view of the state-enable extension. The supervisor-mode (sstateen0-3) and hypervisor-mode (hstateen0-3) state-enable registers must be provided.</td>
    </tr>
    <tr>
        <td>Shcounterenw</td>
        <td>For any hpmcounter that is not read-only zero, the corresponding bit in hcounteren must be writable.</td>
    </tr>
    <tr>
        <td>Shvstvala</td>
        <td>vstval must be written in all cases described above for stval.</td>
    </tr>
    <tr>
        <td>Shtvala</td>
        <td>htval must be written with the faulting guest physical address in all circumstances permitted by the ISA.</td>
    </tr>
    <tr>
        <td>Shvstvecd</td>
        <td>vstvec.MODE must be capable of holding the value 0 (Direct). When vstvec.MODE=Direct, vstvec.BASE must be capable of holding any valid four-byte-aligned address.</td>
    </tr>
    <tr>
        <td>Shvsatpa</td>
        <td>All translation modes supported in satp must be supported in vsatp.</td>
    </tr>
    <tr>
        <td>Shgatpa</td>
        <td>For each supported virtual memory scheme SvNN supported in satp, the corresponding hgatp SvNNx4 mode must be supported. The hgatp mode Bare must also be supported.</td>
    </tr>
    <tr>
        <td rowspan="17" align="center">Optional</td>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/vector-crypto.adoc#zvkng---nist-algorithm-suite-with-gcm">Zvkng</a></td>
        <td>Vector Crypto NIST Algorithms including GHASH.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/vector-crypto.adoc#zvksg---shangmi-algorithm-suite-with-gcm">Zvksg</a></td>
        <td>Byte and Halfword Atomic Memory Operations.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/zacas.adoc">Zacas</a></td>
        <td>Compare-and-swap.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/vector-crypto.adoc#zvbc---vector-carryless-multiplication">Zvbc</a></td>
        <td>Vector carryless multiply.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/zfh.adoc">Zfh</a></td>
        <td>Scalar Half-Precision Floating-Point (FP16).</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/b-st-ext.adoc#zbc-carry-less-multiplication">Zbc</a></td>
        <td>Scalar carryless multiply.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/v-st-ext.adoc#zvfh-vector-extension-for-half-precision-floating-point">Zvfh</a></td>
        <td>Vector half-precision floating-point (FP16).</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/bfloat16.adoc#zfbfmin---scalar-bf16-converts">Zfbfmin</a></td>
        <td>Scalar BF16 FP conversions.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/bfloat16.adoc#zvfbfmin---vector-bf16-converts">Zvfbfmin</a></td>
        <td>Vector BF16 FP conversions.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/supervisor.adoc#sv48-page-based-48-bit-virtual-memory-system">Sv48</a></td>
        <td>Page-Based 48-bit Virtual-Memory System.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/supervisor.adoc#sv57-page-based-57-bit-virtual-memory-system">Sv57</a></td>
        <td>Page-Based 57-bit Virtual-Memory System.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/scalar-crypto.adoc#zkr---entropy-source-extension">Zkr</a></td>
        <td>Entropy CSR.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/supervisor.adoc#svadu-extension-for-hardware-updating-of-ad-bits-version-10">Svadu</a></td>
        <td>Hardware A/D bit updates.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-debug-spec/blob/main/Sdext.adoc">Sdext</a></td>
        <td>Debug triggers.</td>
    </tr>
    <tr>
        <td>Ssstrict</td>
        <td>No non-conforming extensions are present. Attempts to execute unimplemented opcodes or access unimplemented CSRs in the standard or reserved encoding spaces raises an illegal instruction exception that results in a contained trap to the supervisor-mode trap handler.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-isa-manual/blob/main/src/supervisor.adoc#svvptc-extension-for-eliding-memory-management-fences-on-making-ptes-valid-version-10">Svvptc</a></td>
        <td>Transitions from invalid to valid PTEs will be visible in bounded time without an explicit SFENCE.</td>
    </tr>
    <tr>
        <td><a href="https://github.com/riscv/riscv-j-extension/blob/master/zjpm-spec.pdf">Sspm</a></td>
        <td>Supervisor-mode pointer masking, with the supervisor execution environment providing a means to select PMLEN=0 and PMLEN=7 at minimum.</td>
    </tr>
</table>