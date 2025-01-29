.macro enter size
    stmg    %r6, %r15, 48(%r15)
    lay     %r15, -(160+\size)(%r15)
.endm

.macro leave size
    lay     %r15, (160+\size)(%r15)
    lmg     %r6, %r15, 48(%r15)
.endm

.macro ret
    br      %r14
.endm

.macro call func
    brasl   %r14, \func
.endm

.macro print_long    # Output is in r3
    enter   0
    larl    %r2, pif
    call    printf
    leave   0
.endm

.macro read_long    # Input is in r2
    enter   8
    larl    %r2, rif
    lay     %r3, 160(%r15)
    call    scanf
    lg      %r2, 160(%r15)
    leave   8
.endm

.macro read_string label    # Input is stored in the label
    enter   0
    larl    %r2, rsf
    larl    %r3, \label
    call    scanf
    leave   0
.endm

.macro print_string label    # Output is in the label
    enter   0
    larl    %r3, \label
    larl    %r2, psf
    call    printf
    leave   0
.endm

.macro read_char    # Input is in r2
    enter   8
    larl    %r2, rcf
    lay     %r3, 167(%r15)
    call    scanf
    lb      %r2, 167(%r15)
    leave   8
.endm

.macro print_char    # Output is in r3
    enter   0
    larl    %r2, pcf
    call    printf
    leave   0
.endm

.data
    .align 8
    rif:    .asciz  "%ld"
    .align 8
    pif:    .asciz  "%ld"
    .align 8
    rsf:    .asciz  "%s"
    .align 8
    psf:    .asciz  "%s"
    .align 8
    rcf:    .asciz  "%c"
    .align 8
    pcf:    .asciz  "%c"

    .align 8
    result_msg: .asciz "Result: "
    .align 8
    low_bits_msg: .asciz "Low  Bits: "
    .align 8
    high_bits_msg: .asciz "High Bits: "
    .align 8
    invalid_msg: .asciz "invalid input!\nCalculate only by your numbers"
    .align 8
    newline: .asciz "\n"

    .align 8
    buffer: .space 100  
    low_store: .quad 0
    high_store: .quad 0  
    sign: .quad 0

    NUM1LO: .quad 0
    NUM1HI: .quad 0
    NUM1SI: .quad 0
    NUM2LO: .quad 0
    NUM2HI: .quad 0
    NUM2SI: .quad 0

    RESLO: .quad 0
    RESHI: .quad 0
    RESSI: .quad 0

    REMLO: .quad 0
    REMHI: .quad 0

    INST: .quad 0

    remainder: .quad 0
    ar3: .quad 0
    ar2: .quad 0
    .align 8
    output: .space 100      
    ten: .quad 10        

    prompt: .asciz "Enter a decimal number: "
    

.text
.global main

str_to_128bit:
    enter 16
    
    xgr %r4, %r4
    xgr %r5, %r5
    xgr %r6, %r6 
    xgr %r7, %r7 
    lghi %r8, 10  
    lgr %r9, %r2   

    llgc %r4, 0(%r9)
    chi %r4, 45
    jne convert_loop
    aghi %r4, -44
    stgrl %r4, sign
    aghi %r9, 1
    
convert_loop:
    llgc %r4, 0(%r9)
    
    chi %r4, 0
    je convert_done
    chi %r4, 10
    je convert_done
    
    chi %r4, 48   
    jl invalid_input
    chi %r4, 57    
    jh invalid_input
    ahi %r4, -48   

    lgr %r1, %r7    
    lgr %r3, %r6    
    mlgr %r2, %r8   
    mlgr %r6, %r8  
    algr %r6, %r3  

    lgr %r1, %r7  
    algr %r7, %r4  
    
    clgr %r7, %r1
    jnl no_overflow
    aghi %r6, 1   
    
no_overflow:
    aghi %r9, 1

    j convert_loop
    
convert_done:
    lgr %r2, %r6
    lgr %r3, %r7

print_result:
    print_string low_bits_msg
    lgr %r3, %r7
    print_long
    print_string newline
    print_string high_bits_msg 
    lgr %r3, %r6
    print_long
    print_string newline

    stgrl %r7, low_store
    stgrl %r6, high_store
    leave 16
    ret

invalid_input:
    print_string invalid_msg
    print_string newline

    j convert_done

divide_by_10:
    enter 32
    lgrl %r2, high_store
    lgrl %r3, low_store
    
    lghi %r7, 64       
    xgr %r4, %r4       
    xgr %r8, %r8      
    xgr %r9, %r9        
    
high_loop:
    sllg %r4, %r4, 1     
    srlg %r5, %r2, -1(%r7) 
    lghi %r10, 1
    ngr %r5, %r10         
    algr %r4, %r5      
    
    
    clgfi %r4, 10
    jl no_sub_high
    aghi %r4, -10       
    lghi %r5, 1
    sllg %r5, %r5, -1(%r7)
    ogr %r8, %r5        
    
no_sub_high:
    brctg %r7, high_loop
    lghi %r7, 64       
low_loop:
    sllg %r4, %r4, 1    
    srlg %r5, %r3, -1(%r7) 
    lghi %r10, 1
    ngr %r5, %r10        
    algr %r4, %r5      
    
    
    clgfi %r4, 10
    jl no_sub_low
    aghi %r4, -10    
    
    lghi %r5, 1
    sllg %r5, %r5, -1(%r7)
    ogr %r9, %r5      
    
no_sub_low:
    brctg %r7, low_loop
    
    lgr %r2, %r8        
    lgr %r3, %r9       
    
    stgrl %r3, low_store
    stgrl %r2, high_store
    stgrl %r4, remainder
    
    leave 32
    ret


numbers_to_string:
    enter 48

    lgrl %r2, high_store
    lgrl %r3, low_store
    
    
    stg %r2, 160(%r15)  
    stg %r3, 168(%r15)  
    
    ogr %r2, %r2
    jnz not_zero
    ogr %r3, %r3
    jnz not_zero
    
    larl %r2, output
    mvi 0(%r2), 48
    mvi 1(%r2), 0
    j convert2_done
    
not_zero:
    lghi %r6, 0          
    larl %r7, output    
    
convert2_loop:
    lg %r2, 160(%r15)   
    lg %r3, 168(%r15)  
    stgrl %r2, high_store
    stgrl %r3, low_store

    call divide_by_10
    
    lgrl %r2, high_store
    lgrl %r3, low_store
    lgrl %r4, remainder
    
    stg %r2, 160(%r15)
    stg %r3, 168(%r15)
    
    aghi %r4, 48        
    stc %r4, 0(%r6,%r7)  
    aghi %r6, 1         
    
    
    lg %r2, 160(%r15)
    lg %r3, 168(%r15)
    ogr %r2, %r2
    jnz convert2_loop
    ogr %r3, %r3
    jnz convert2_loop
    
    
    larl %r2, output     
    lgr %r3, %r6        
    agr %r3, %r2
    aghi %r3, -1        
    
reverse_loop:
    clr %r2, %r3
    jnl reverse_done
    
    llgc %r4, 0(%r2)    
    llgc %r5, 0(%r3)   
    stc %r4, 0(%r3)     
    stc %r5, 0(%r2)     
    
    aghi %r2, 1          # Move left pointer
    aghi %r3, -1         # Move right pointer
    j reverse_loop
    
reverse_done:
    lgr %r2, %r7         # Get output buffer address
    agr %r2, %r6         # Add length
    mvi 0(%r2), 0        # Add null terminator
    
convert2_done:
    leave 48
    ret


# Function to read decimal string
read_decimal:
    enter 8

    larl %r2, buffer     # Get string address
    call str_to_128bit   # Convert to number
    leave 8
    ret

check_instruction:
    enter 8
    larl %r2, buffer     # Get string address
    llgc %r4, 0(%r2)
    stgrl %r4, INST

    # lgr %r3, %r4
    # print_char

    leave 8
    ret

main:
    enter 32

    # Read and convert number 1
    read_string buffer    # Read string into buffer

    # If input = 'exit' return
    call check_exit

    call read_decimal

    lgrl %r2, high_store
    lgrl %r3, low_store
    lgrl %r4, sign
    stgrl %r2, NUM1HI
    stgrl %r3, NUM1LO
    stgrl %r4, NUM1SI

    # read instruction
    read_string buffer    # Read string into buffer

    # If input = 'exit' return
    call check_exit

    call check_instruction
    
    # Read and convert number 2
    read_string buffer    # Read string into buffer

    # If input = 'exit' return
    call check_exit

    call read_decimal

    lgrl %r2, high_store
    lgrl %r3, low_store
    lgrl %r4, sign
    stgrl %r2, NUM2HI
    stgrl %r3, NUM2LO
    stgrl %r4, NUM2SI

    lgrl %r3, INST      # read instruction
    chi %r3, '+'
    jne not_equal1
    Call DOSUM
    not_equal1:
    chi %r3, '-'
    jne not_equal2
    lghi %r2,1         # -1 * NUM2SI
    lgrl %r4,NUM2SI
    xgr %r4,%r2
    stgrl %r4,NUM2SI
    Call DOSUM
    not_equal2:
    chi %r3, '*'
    jne not_equal3
    Call DOMUL
    not_equal3:
    chi %r3, '/'
    jne not_equal4
    # Call DODIV
    not_equal4:
    
    # Print result message
    
    # Print result
    lgrl %r2, RESHI
    lgrl %r3, RESLO
    lgrl %r4, RESSI
    stgrl %r2, high_store
    stgrl %r3, low_store
    stgrl %r4, sign

    call numbers_to_string
    lgrl %r3, sign
    chi %r3, 1
    jne print_unsigned
    aghi %r3, 44
    print_char
print_unsigned:
    print_string output
    
    # Print newline
    print_string newline
    leave 32
    j main

check_exit:
    enter 8

    larl %r2, buffer

    llgc    %r3, 0(%r2)      # حرف اول
    chi     %r3, 'e'
    jne     not_exit
    
    llgc    %r3, 1(%r2)      # حرف دوم
    chi     %r3, 'x'
    jne     not_exit
    
    llgc    %r3, 2(%r2)      # حرف سوم
    chi     %r3, 'i'
    jne     not_exit
    
    llgc    %r3, 3(%r2)      # حرف چهارم
    chi     %r3, 't'
    jne     not_exit
    
    leave 200
    xgr %r2, %r2
    ret

not_exit:
    leave 8
    ret

#-------------------------------------------sum and sub
DOSUM:
    enter 0
    j check_sum_AB_hi

check_sum_AB_hi:
    lgrl %r4,NUM1HI
    lgrl %r5,NUM2HI
    cgr %r4,%r5
    je check_sum_AB_lo
    jh check_sign_sum_A_g_B
    jl check_sign_sum_A_l_B

check_sum_AB_lo:
    lgrl %r4,NUM1LO
    lgrl %r5,NUM2LO
    cgr %r4,%r5
    je check_sign_sum_A_e_B
    jh check_sign_sum_A_g_B
    jl check_sign_sum_A_l_B

check_sign_sum_A_e_B:
    lgrl %r4,NUM1SI
    lgrl %r5,NUM2SI
    cgr %r4,%r5
    jne ZERO
    stgrl %r4,RESSI
    j SUM

check_sign_sum_A_g_B:
    lgrl %r4,NUM1SI
    lgrl %r5,NUM2SI
    cgr %r4,%r5

    stgrl %r4,RESSI
    cgr %r4,%r5
    je SUM

    stgrl %r4,RESSI
    cgr %r4,%r5
    jl SUB

    stgrl %r5,RESSI
    cgr %r4,%r5
    jh SUB


check_sign_sum_A_l_B:
    lgrl %r4,NUM1SI
    lgrl %r5,NUM2SI
    stgrl %r4,RESSI
    cgr %r4,%r5
    je SUM

    #convert A and B
    lgrl %r4,NUM1LO
    lgrl %r5,NUM2LO
    lgrl %r6,NUM1HI
    lgrl %r7,NUM2HI
    stgrl %r4,NUM2LO
    stgrl %r5,NUM1LO
    stgrl %r6,NUM2HI
    stgrl %r7,NUM1HI

    lgrl %r4,NUM1SI
    lgrl %r5,NUM2SI
    stgrl %r5,RESSI
    cgr %r4,%r5
    jl SUB

    stgrl %r4,RESSI
    cgr %r4,%r5
    jh SUB


SUM:
    lgrl %r4,NUM1LO
    lgrl %r5,NUM2LO
    lgrl %r6,NUM1HI
    lgrl %r7,NUM2HI
    agr %r4,%r5
    brc 4 ,CARRY
    agr %r6,%r7
    j PUTRESULT
CARRY:
    agr %r6,%r7
    agfi %r6, 1
    j PUTRESULT

SUB:
    lgrl %r4,NUM1LO
    lgrl %r5,NUM2LO
    lgrl %r6,NUM1HI
    lgrl %r7,NUM2HI
    sgr %r4,%r5
    brc 4 ,BORROW
    sgr %r6,%r7     
    j PUTRESULT
BORROW:
    sgr %r6,%r7
    agfi %r6, -1
    j PUTRESULT

ZERO:
    lghi %r4,0
    stgrl %r4,RESSI
    stgrl %r4,RESLO
    stgrl %r4,RESHI
    leave 0
    ret

PUTRESULT:
    stgrl %r4,RESLO
    stgrl %r6,RESHI
    leave 0
    ret    
#------------------------------------------------- mul
DOMUL:
    enter 0
    lgrl %r4,NUM1SI
    lgrl %r5,NUM2SI
    cgr %r4,%r5
    je POSMUL
    lghi %r4,1
    stgrl %r4,RESSI
    j MUL

POSMUL:
    lghi %r4,0
    stgrl %r4,RESSI
    j MUL

MUL:
    lgrl %r4,NUM1LO
    lgrl %r7,NUM2LO
    mlgr %r6,%r4  # low 64 bit in r6 and hi 64 bit in r7
    stgrl %r7,RESLO
    lgr %r8,%r6 

    lgrl %r4,NUM1HI
    lgrl %r7,NUM2LO
    mlgr %r6,%r4
    agr %r8,%r7

    lgrl %r4,NUM1LO
    lgrl %r7,NUM2HI
    mlgr %r6,%r4
    agr %r8,%r7
    stgrl %r8,RESHI
    leave 0
    ret
    
#---------------------------------------------- div
DODIV:
    enter 0
    lgrl %r4,NUM1SI
    lgrl %r5,NUM2SI
    cgr %r4,%r5
    je POSDIV
    lghi %r4,1
    stgrl %r4,RESSI
    j INITDIV

POSDIV:
    lghi %r4,0
    stgrl %r4,RESSI
    j INITDIV

INITDIV:
    lgrl %r4,NUM1LO
    lgrl %r5,NUM1HI
    lgrl %r6,NUM2LO
    lgrl %r7,NUM2HI

    lghi %r8,0
    stgrl %r8,RESHI
    stgrl %r8,RESLO
    stgrl %r8,REMHI 
    stgrl %r8,REMLO
                    
    lghi %r8,64
    j FOR64BITHI

FOR64BITHI:
    agfi %r8,-1
    cgfi %r8,0
    jl INITSECFOR

    lgrl %r9,REMLO
    lgrl %r10,REMHI
    lghi %r13,63
    srlg %r11,%r9, 0(%r13)
    lghi %r12,1
    sllg %r9, %r9, 0(%r12)
    sllg %r10, %r10, 0(%r12)
    ogr %r10,%r11

    srlg %r11,%r5, 0(%r8)
    ngr %r11 , %r12
    ogr %r9,%r11

    stgrl %r10,REMHI 
    stgrl %r9,REMLO

    stmg %r4,%r15,32(%r15)
    lay %r15, -160(%r15)

    brasl	%r14, CHECKREMHI

    cgfi %r4 , 0

    lay %r15, 160(%r15)
    lmg %r4,%r15,32(%r15)

    je FOR64BITHI

    lghi %r12,1
    sgr %r10,%r7
    sgr %r10,%r12
    sgr %r9,%r6
    brc 4 ,BORROWHI
    agr %r10,%r12
    BORROWHI:

    lghi %r11,1
    sllg %r11, %r11, 0(%r8)
    lgrl %r12,RESHI
    ogr %r12,%r11
    stgrl %r12,RESHI

    j FOR64BITHI

CHECKREMHI:
    lgrl %r7,NUM2HI
    lgrl %r10,REMHI
    cgr %r7,%r10
    je CHECKREMLO

    lghi %r4,0
    jh RETCHECKREM

    lghi %r4,1
    j RETCHECKREM



CHECKREMLO:
    lgrl %r6,NUM2LO
    lgrl %r9,REMLO
    cgr %r6,%r9

    lghi %r4,0
    jh RETCHECKREM

    lghi %r4,1
    j RETCHECKREM


RETCHECKREM:
    ret

INITSECFOR:
    lghi %r8,64
    j FOR64BITLO

FOR64BITLO:
    agfi %r8,-1
    cgfi %r8,0
    jl DONEDIV

    lgrl %r9,REMLO
    lgrl %r10,REMHI
    lghi %r13,63
    srlg %r11,%r9, 0(%r13)
    lghi %r12,1
    sllg %r9, %r9, 0(%r12)
    sllg %r10, %r10, 0(%r12)
    ogr %r10,%r11

    srlg %r11,%r4, 0(%r8)
    ngr %r11 , %r12
    ogr %r9,%r11

    stgrl %r10,REMHI 
    stgrl %r9,REMLO

    stmg %r4,%r15,32(%r15)
    lay %r15, -160(%r15)

    brasl	%r14, CHECKREMHI

    cgfi %r4 , 0

    lay %r15, 160(%r15)
    lmg %r4,%r15,32(%r15)

    je FOR64BITLO

    lghi %r12,1
    sgr %r10,%r7
    sgr %r10,%r12
    sgr %r9,%r6
    brc 4 ,BORROWHI
    agr %r10,%r12
    BORROWHI:

    lghi %r11,1
    sllg %r11, %r11, 0(%r8)
    lgrl %r12,RESLO
    ogr %r12,%r11
    stgrl %r12,RESLO

    j FOR64BITLO


DONEDIV:
    stgrl %r10,REMHI 
    stgrl %r9,REMLO
    leave 0
    ret
