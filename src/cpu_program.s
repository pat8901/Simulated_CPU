   .section .data
#==========================================================
#
#   Simulator Memory, 16bit address, 64K max
#
#==========================================================
smem:
    .rept 65536/2
    .byte 0x29,0x10
    .endr
#==========================================================
#
#   Simulator registers, 16 32-bit registers
#   Initialized to zero on "boot"
#
#==========================================================
regs:
    .long 0
    .long 1
    .rept 14
    .long 0
    .endr
#==========================================================
#
#   Operation dispatch table, one/op-code, 256 max
#
#   Rd=Destination Register (0-15)
#   Rs=Source Register (0-15)
#   Memory has a 16-bit address space, high-order
#   bits of any indirect operation discarded
#
#==========================================================
optbl:
    .long   snop        #00 Robot init
    .long   snop        #01 Read Sensors
    .long   snop        #02 Robot Speed, Rr,Rl
    .long   snop        #03 Robot Speed Imm

   .long    ldr    #04 ld Rd,Rs
   .long    ldi    #05 immediate to register
   .long    ldm    #06 memory address to register
   .long    ldmr    #07 memory addr + register to register
   .long    snop    #08
   
   .long    snop    #09
   .long    snop    #0A
   .long    snop    #0B

   .long    andr    #0C and Rd,Rs
   .long    andi    #0D immediate to register
   .long    andm    #0E memory address to register
   .long    andmr    #0F memory addr + register to register
   .long    snop    #10

   .long    orr     #11 or Rd,Rs
   .long    ori    #12 immediate to register
   .long    orm    #13 memory address to register
   .long    ormr    #14 memory addr + register to register
   .long    snop    #15

   .long    eorr    #16 eor Rd,Rs
   .long    eori    #17 immediate to register
   .long    eorm    #18 memory address to register
   .long    eormr    #19 memory addr + register to register
   .long    snop    #1A
   
   .long    snop    #1B
   
   .long    sjmp    #1C
   .long    jmpgtrr    #1D
   .long    jmpltrr    #1E
   .long    jmpeqrr    #1F
   .long    jmpezrr    #20
   .long    snop    #21
   .long    snop    #22
   .long    snop    #23
   .long    snop    #24
   .long    snop    #25

   .long    addr    #26 add Rd,Rs
   .long    addi    #27 immediate to register
   .long    addm    #28 memory adrress to register
   .long    addmr   #29 memory addr + register to register
   .long    snop    #2A

    .rept 256-((.-optbl)/4)
    .long   snop
    .endr
#==========================================================
#
#   Misc. data follows
#
#==========================================================
# Control String for op-codes not yet implemented
nostr: .string "Not Implemented: %d\n"
# Temporary storage for simulated IP
ipsv:    .long    0
#**********************************************************
#
#   Simulator CPU: Fetch, Decode, Execute
#
#**********************************************************
    .globl _start
    .section .text
_start:
    movl     $0,%edi         	 #Our simulated ip
fetch:
    movb     smem(,%edi,1),%al	 #Fetch opcode
    andl     $0xff,%eax      	 #Clear high-order bytes
    movl     optbl(,%eax,4),%eax #Decode: get address of routine
    incl     %edi            	 #Bump ip to second instruction byte
    call     *%eax           	 #Execute the instruction
                     		 #Instructions must leave ip
                     		 #pointing to next opcode
    jmp fetch            	 #It's a cpu, do forever!
#===================================================================
#
#          Instruction Execution Routines
#
#===================================================================
#-------------------------------------------------------------------
#
#          ldr -- ld Rd,Rs Move 32 bits from source-dest register
#
#-------------------------------------------------------------------
ldr:
     movb     smem(,%edi,1),%al  #Get Rd,Rs in temp reg
     andl     $0xff,%eax         #Clear high bits
     movl     %eax,%ebx          #Make copy for source
     sarl     $4,%eax            #Isolate Rd index in %eax
     andl     $0x0f,%ebx         #Isolate Rs index in %ebx
     movl     regs(,%ebx,4),%ebx #Get data from Rs
     movl     %ebx,regs(,%eax,4) #Store into Rd
     addl     $1,%edi            #Adjust Instruction Pointer
     ret                         #Return to fetch
#------------------------------------------------------------------
#
#	 andr -- and Rd,Rs
#
#-----------------------------------------------------------------
andr:
      movb    smem(,%edi,1),%al  #Get Rd,Rs in temp reg
      andl    $0xff,%eax         #Clear high bits
      movl    %eax,%ebx          #Make copy for source
      sarl    $4,%eax            #Isolate Rd index in %eax
      andl    $0x0f,%ebx         #Isolate Rs index in %ebx
      movl    regs(,%ebx,4),%ebx #Get data from Rs
      andl    %ebx,regs(,%eax,4) #Store into Rd
      addl    $1,%edi            #Adjust Instruction Pointer
      ret                        #Return to fetch
#------------------------------------------------------------------
#
#	 orr -- or Rd,Rs
#
#-----------------------------------------------------------------
orr:
      movb    smem(,%edi,1),%al  #Get Rd,Rs in temp reg
      andl    $0xff,%eax         #Clear high bits
      movl    %eax,%ebx          #Make copy for source
      sarl    $4,%eax            #Isolate Rd index in %eax
      andl    $0x0f,%ebx         #Isolate Rs index in %ebx
      movl    regs(,%ebx,4),%ebx #Get data from Rs
      orl     %ebx,regs(,%eax,4) #Store into Rd
      addl   $1,%edi             #Adjust Instruction Pointer
      ret                        #Return to fetch
#------------------------------------------------------------------
#
#	 eorr -- xor Rd,Rs
#
#-----------------------------------------------------------------
eorr:
      movb    smem(,%edi,1),%al  #Get Rd,Rs in temp reg
      andl    $0xff,%eax         #Clear high bits
      movl    %eax,%ebx          #Make copy for source
      sarl    $4,%eax            #Isolate Rd index in %eax
      andl    $0x0f,%ebx         #Isolate Rs index in %ebx
      movl    regs(,%ebx,4),%ebx #Get data from Rs
      xorl    %ebx,regs(,%eax,4) #Store into Rd
      addl    $1,%edi            #Adjust Instruction Pointer
      ret                        #Return to fetch
#------------------------------------------------------------------
#
#	 addr -- add Rd,Rs
#
#-----------------------------------------------------------------
addr:
      movb    smem(,%edi,1),%al  #Get Rd,Rs in temp reg
      andl    $0xff,%eax         #Clear high bits
      movl    %eax,%ebx          #Make copy for source
      sarl    $4,%eax            #Isolate Rd index in %eax
      andl    $0x0f,%ebx         #Isolate Rs index in %ebx
      movl    regs(,%ebx,4),%ebx #Get data from Rs
      addl    %ebx,regs(,%eax,4) #Store into Rd
      addl    $1,%edi            #Adjust Instruction Pointer
      ret                        #Return to fetch
#-------------------------------------------------------------------
#
#          ldi -- load immediate
#
#-------------------------------------------------------------------
ldi:
    movb    smem(,%edi,1),%al   #Get Rd,Rs in temp reg
    andl    $0xff,%eax          #Clear high bits
    sarl    $4,%eax             #Isolate Rd index in %eax
    movl    smem+1(,%edi,1),%ebx
    movl    %ebx,regs(,%eax,4)  #Store into Rd
    addl    $5,%edi             #Adjust Instruction Pointer
    ret                         #Return to fetch
#-------------------------------------------------------------------
#
#          andi -- ld Rd,Rs Move 32 bits from source-dest register
#
#-------------------------------------------------------------------
andi:
    movb    smem(,%edi,1),%al   #Get Rd,Rs in temp reg
    andl    $0xff,%eax          #Clear high bits
    sarl    $4,%eax             #Isolate Rd index in %eax
    movl    smem+1(,%edi,1),%ebx
    andl    %ebx,regs(,%eax,4)
    addl    $5,%edi
    ret
#-------------------------------------------------------------------
#
#          ori -- ld Rd,Rs Move 32 bits from source-dest register
#
#-------------------------------------------------------------------
ori:
    movb    smem(,%edi,1),%al   #Get Rd,Rs in temp reg
    andl    $0xff,%eax          #Clear high bits
    sarl    $4,%eax             #Isolate Rd index in %eax
    movl    smem+1(,%edi,1),%ebx
    orl    %ebx,regs(,%eax,4)
    addl    $5,%edi
    ret
#-------------------------------------------------------------------
#
#          eori -- ld Rd,Rs Move 32 bits from source-dest register
#
#-------------------------------------------------------------------
eori:
    movb    smem(,%edi,1),%al   #Get Rd,Rs in temp reg
    andl    $0xff,%eax          #Clear high bits
    sarl    $4,%eax             #Isolate Rd index in %eax
    movl    smem+1(,%edi,1),%ebx
    xorl    %ebx,regs(,%eax,4)
    addl    $5,%edi
    ret
#-------------------------------------------------------------------
#
#          addi -- ld Rd,Rs Move 32 bits from source-dest register
#
#-------------------------------------------------------------------
addi:
    movb    smem(,%edi,1),%al   #Get Rd,Rs in temp reg
    andl    $0xff,%eax          #Clear high bits
    sarl    $4,%eax             #Isolate Rd index in %eax
    movl    smem+1(,%edi,1),%ebx
    addl    %ebx,regs(,%eax,4)
    addl    $5,%edi
    ret
#-------------------------------------------------------------------
#
#          ldm -- load to memory
#
#-------------------------------------------------------------------
ldm:
    movb    smem(,%edi,1),%al   #Get Rd,Rs in temp reg
    andl    $0xff,%eax          #Clear high bits
    sarl    $4,%eax             #Isolate Rd index in %eax
    movw    smem+1(,%edi,1),%bx
    andl    $0xffff,%ebx
    movl    smem(,%ebx,1),%ebx
    movl    %ebx,regs(,%eax,4)
    addl    $3,%edi
    ret
#-------------------------------------------------------------------
#
#          andm -- ld Rd,Rs Move 32 bits from source-dest register
#
#-------------------------------------------------------------------
andm:
    movb    smem(,%edi,1),%al   #Get Rd,Rs in temp reg
    andl    $0xff,%eax          #Clear high bits
    sarl    $4,%eax             #Isolate Rd index in %eax
    movw    smem+1(,%edi,1),%bx
    andl    $0xffff,%ebx
    movl    smem(,%ebx,1),%ebx
    andl    %ebx,regs(,%eax,4)
    addl    $3,%edi
    ret
#-------------------------------------------------------------------
#
#          orm -- ld Rd,Rs Move 32 bits from source-dest register
#
#-------------------------------------------------------------------
orm:
    movb    smem(,%edi,1),%al   #Get Rd,Rs in temp reg
    andl    $0xff,%eax          #Clear high bits
    sarl    $4,%eax             #Isolate Rd index in %eax
    movw    smem+1(,%edi,1),%bx
    andl    $0xffff,%ebx
    movl    smem(,%ebx,1),%ebx
    orl    %ebx,regs(,%eax,4)
    addl    $3,%edi
    ret
#-------------------------------------------------------------------
#
#          eorm -- ld Rd,Rs Move 32 bits from source-dest register
#
#-------------------------------------------------------------------
eorm:
    movb    smem(,%edi,1),%al   #Get Rd,Rs in temp reg
    andl    $0xff,%eax          #Clear high bits
    sarl    $4,%eax             #Isolate Rd index in %eax
    movw    smem+1(,%edi,1),%bx
    andl    $0xffff,%ebx
    movl    smem(,%ebx,1),%ebx
    xorl    %ebx,regs(,%eax,4)
    addl    $3,%edi
    ret
#-------------------------------------------------------------------
#
#          addm -- ld Rd,Rs Move 32 bits from source-dest register
#
#-------------------------------------------------------------------
addm:
    movb    smem(,%edi,1),%al   #Get Rd,Rs in temp reg
    andl    $0xff,%eax          #Clear high bits
    sarl    $4,%eax             #Isolate Rd index in %eax
    movw    smem+1(,%edi,1),%bx
    andl    $0xffff,%ebx
    movl    smem(,%ebx,1),%ebx
    addl    %ebx,regs(,%eax,4)
    addl    $3,%edi
    ret
#-------------------------------------------------------------------
#
#          ldmr -- load memory indexed
#
#-------------------------------------------------------------------
ldmr:
    movb    smem(,%edi,1),%al
    andl    $0xff,%eax
    movl    %eax,%ebx
    sarl    $4,%eax
    andl    $0x0f,%ebx
    movl    regs(,%ebx,4),%ebx
    addw    smem+1(,%edi,1),%bx
    andl    $0xffff,%ebx
    movl    smem(,%ebx,1),%ebx
    movl    %ebx,regs(,%eax,4)
    addl    $3,%edi
    ret
#-------------------------------------------------------------------
#
#          andmr -- ld Rd,Rs Move 32 bits from source-dest register
#
#-------------------------------------------------------------------
andmr:
    movb    smem(,%edi,1),%al
    andl    $0xff,%eax
    movl    %eax,%ebx
    sarl    $4,%eax
    andl    $0x0f,%ebx
    movl    regs(,%ebx,4),%ebx
    addw    smem+1(,%edi,1),%bx
    andl    $0xffff,%ebx
    movl    smem(,%ebx,1),%ebx
    andl    %ebx,regs(,%eax,4)
    addl    $3,%edi
    ret
#-------------------------------------------------------------------
#
#          ormr -- ld Rd,Rs Move 32 bits from source-dest register
#
#-------------------------------------------------------------------
ormr:
    movb    smem(,%edi,1),%al
    andl    $0xff,%eax
    movl    %eax,%ebx
    sarl    $4,%eax
    andl    $0x0f,%ebx
    movl    regs(,%ebx,4),%ebx
    addw    smem+1(,%edi,1),%bx
    andl    $0xffff,%ebx
    movl    smem(,%ebx,1),%ebx
    orl    %ebx,regs(,%eax,4)
    addl    $3,%edi
    ret
#-------------------------------------------------------------------
#
#          eormr -- ld Rd,Rs Move 32 bits from source-dest register
#
#-------------------------------------------------------------------
eormr:
    movb    smem(,%edi,1),%al
    andl    $0xff,%eax
    movl    %eax,%ebx
    sarl    $4,%eax
    andl    $0x0f,%ebx
    movl    regs(,%ebx,4),%ebx
    addw    smem+1(,%edi,1),%bx
    andl    $0xffff,%ebx
    movl    smem(,%ebx,1),%ebx
    xorl    %ebx,regs(,%eax,4)
    addl    $3,%edi
    ret
#-------------------------------------------------------------------
#
#          addmr -- ld Rd,Rs Move 32 bits from source-dest register
#
#-------------------------------------------------------------------
addmr:
    movb    smem(,%edi,1),%al
    andl    $0xff,%eax
    movl    %eax,%ebx
    sarl    $4,%eax
    andl    $0x0f,%ebx
    movl    regs(,%ebx,4),%ebx
    addw    smem+1(,%edi,1),%bx
    andl    $0xffff,%ebx
    movl    smem(,%ebx,1),%ebx
    addl    %ebx,regs(,%eax,4)
    addl    $3,%edi
    ret
#-------------------------------------------------------------------
#
#          sjmp -- jump to memaddr
#
#-------------------------------------------------------------------
sjmp:
    movw    smem+1(,%edi,1),%ax
    andl    $0xffff,%eax
    movl    %eax,%edi
    ret
#-------------------------------------------------------------------
#
#          jmpgtrr -- jump to memaddr if Rd > Rs
#
#-------------------------------------------------------------------
jmpgtrr:
        movb    smem(,%edi,1),%al
        andl    $0xff,%eax
        movl    %eax,%ebx
        sarl    $4,%eax             #index of Rd
        andl    $0xff,%ebx          #index of Rs
        
        movl    regs(,%eax,4),%eax  #content of Rd
        movl    regs(,%ebx,4),%ebx  #content of Rs
        cmpl    %ebx,%eax
        jle     jmpgtrrxit
        
        movw    smem+1(,%edi,1),%ax
        andl    $0xffff,%eax
        movl    %eax,%edi
        ret
        
jmpgtrrxit:
          addl  $3,%edi
          ret
#-------------------------------------------------------------------
#
#          jmplttrr -- jump to memaddr if Rd < Rs
#
#-------------------------------------------------------------------
jmpltrr:
        movb    smem(,%edi,1),%al
        andl    $0xff,%eax
        movl    %eax,%ebx
        sarl    $4,%eax             #index of Rd
        andl    $0xff,%ebx          #index of Rs
        
        movl    regs(,%eax,4),%eax  #content of Rd
        movl    regs(,%ebx,4),%ebx  #content of Rs
        cmpl    %ebx,%eax
        jge     jmpltrrxit
        
        movw    smem+1(,%edi,1),%ax
        andl    $0xffff,%eax
        movl    %eax,%edi
        ret
        
jmpltrrxit:
          addl  $3,%edi
          ret
#-------------------------------------------------------------------
#
#          jmpeqrr -- jump to memaddr if Rd = Rs
#
#-------------------------------------------------------------------
jmpeqrr:
        movb    smem(,%edi,1),%al
        andl    $0xff,%eax
        movl    %eax,%ebx
        sarl    $4,%eax             #index of Rd
        andl    $0xff,%ebx          #index of Rs
        
        movl    regs(,%eax,4),%eax  #content of Rd
        movl    regs(,%ebx,4),%ebx  #content of Rs
        cmpl    %ebx,%eax
        je     jmpeqrrxit
        
        movw    smem+1(,%edi,1),%ax
        andl    $0xffff,%eax
        movl    %eax,%edi
        ret
        
jmpeqrrxit:
          addl  $3,%edi
          ret
#-------------------------------------------------------------------
#
#          jmpezrr -- jump to memaddr if Rd = 0
#
#-------------------------------------------------------------------
jmpezrr:
        movb    smem(,%edi,1),%al
        andl    $0xff,%eax
        sarl    $4,%eax             #index of Rd
        
        movl    regs(,%eax,4),%eax  #content of Rd
        cmpl    $0,%eax             #compare to see if zero
        je     jmpezrrxit           #jump to jmpezrrxit
        
        movw    smem+1(,%edi,1),%ax
        andl    $0xffff,%eax
        movl    %eax,%edi
        ret
        
jmpezrrxit:
          addl  $3,%edi
          ret
#------------------------------------------------------------------
#
#   snop -- Simulator No Operation
#
#------------------------------------------------------------------
snop:
     pushl    $0    #Print its own op-code
     jmp notimp
rinit:              #Robot init
rsens:              #Read Sensors
rspeed:             #Robot Speed
     pushl    $1
     jmp notimp
#------------------------------------------------------------------
#
#   Notimp: Default operation for operations not implemented
#   Should never happen in actual program, represents an
#   error. Treat as no-op for now.
#
#------------------------------------------------------------------
notimp:
     movl     %edi,ipsv     #In case printf changes ip
     push     $nostr        #Pointer to control string
call printf
addl $8,%esp
movl ipsv,%edi #Restore simulator ip
addl $1,%edi   #Bump ip to next op code
ret

