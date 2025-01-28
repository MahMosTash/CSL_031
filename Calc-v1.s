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

    # ostad
    
    # Print result message
    
    # Print result
    call numbers_to_string
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


    
