TITLE Chaotic Temperature Statistics     (Proj5_bairsamu.asm)
; Author: Samuel Baird
; Last Modified: 02/26/2026
; OSU email address: bairsamu@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number: 5                Due Date: 03/01/2026
; Description: Generates DAYS_MEASURED * TEMPS_PER_DAY random temperature readings
;              in the range [MIN_TEMP, MAX_TEMP], stores them in a flat array, then
;              finds the daily high and low for each day, computes the truncated
;              average of those daily highs and lows, and displays everything with
;              descriptive titles. All sub-tasks are broken into separate procedures
;              that communicate exclusively through stack-passed parameters.
;
; **EC: Temperatures are displayed column-by-column (each column = one day) rather
;       than the default row-per-day layout, so the table reads left-to-right by day.

INCLUDE Irvine32.inc

; -----------------------------------------------------------------------
; Global Constants  (may be used by name in any procedure)
; -----------------------------------------------------------------------
DAYS_MEASURED   EQU  14
TEMPS_PER_DAY   EQU  11
MIN_TEMP        EQU  20
MAX_TEMP        EQU  80
ARRAYSIZE       EQU  DAYS_MEASURED * TEMPS_PER_DAY   ; 154 total readings

; -----------------------------------------------------------------------
.data
; -----------------------------------------------------------------------

; -- Introduction strings --
intro1      BYTE  "Welcome to Chaotic Temperature Statistics, by Samuel Baird", 0
intro2      BYTE  "**EC: Temperature array is displayed column-by-column (one column per day).", 0
intro3      BYTE  "This program generates temperature readings -- one per time slot per day --", 0
intro4      BYTE  "for multiple days (amounts controlled by CONSTANTs). It then computes the", 0
intro5      BYTE  "daily high and low temperatures and their truncated averages, and displays", 0
intro6      BYTE  "all results neatly with descriptive titles.", 0

; -- Array / section title strings --
titleAll    BYTE  "The temperature readings are as follows (one column is one day):", 0
titleHighs  BYTE  "The highest temperature of each day was:", 0
titleLows   BYTE  "The lowest temperature of each day was:", 0
titleAvgH   BYTE  "The (truncated) average high temperature was: ", 0
titleAvgL   BYTE  "The (truncated) average low temperature was: ", 0

; -- Farewell --
farewell    BYTE  "Thanks for using Chaotic Temperature Statistics. Goodbye!", 0

; -- Arrays --
tempArray   DWORD  ARRAYSIZE DUP(?)          ; all temperature readings (row-major: row=day)
dailyHighs  DWORD  DAYS_MEASURED DUP(?)      ; max temp per day
dailyLows   DWORD  DAYS_MEASURED DUP(?)      ; min temp per day

; -- Averages --
averageHigh DWORD  ?
averageLow  DWORD  ?

; -- Formatting --
twoSpaces   BYTE  "  ", 0

; -----------------------------------------------------------------------
.code
; -----------------------------------------------------------------------

; =======================================================================
; Procedure: main
; Description: Entry point. Seeds the RNG, then orchestrates all
;              sub-procedure calls in order: greeting -> generate ->
;              find highs/lows -> calculate averages -> display all ->
;              farewell. No data-segment variables are referenced by
;              name except to obtain their OFFSETs / values for push.
; Receives:   nothing
; Returns:    nothing
; Pre-conditions:  Data segment arrays allocated.
; Post-conditions: All output printed; program exits cleanly.
; Registers changed: EAX, EDX (used directly in main body)
; =======================================================================
main PROC
    call  Randomize          ; seed the pseudo-random number generator once

    ; --- printGreeting(intro1..intro6) ---
    push  OFFSET intro6
    push  OFFSET intro5
    push  OFFSET intro4
    push  OFFSET intro3
    push  OFFSET intro2
    push  OFFSET intro1
    call  printGreeting

    ; --- generateTemperatures(tempArray) ---
    push  OFFSET tempArray
    call  generateTemperatures

    ; --- findDailyHighs(tempArray, dailyHighs) ---
    push  OFFSET dailyHighs
    push  OFFSET tempArray
    call  findDailyHighs

    ; --- findDailyLows(tempArray, dailyLows) ---
    push  OFFSET dailyLows
    push  OFFSET tempArray
    call  findDailyLows

    ; --- calcAverageLowHighTemps(dailyHighs, dailyLows, averageHigh, averageLow) ---
    push  OFFSET averageLow
    push  OFFSET averageHigh
    push  OFFSET dailyLows
    push  OFFSET dailyHighs
    call  calcAverageLowHighTemps

    ; --- displayTempArray: full grid (EC: column-per-day orientation)
    ;     rows = TEMPS_PER_DAY, columns = DAYS_MEASURED
    push  DAYS_MEASURED
    push  TEMPS_PER_DAY
    push  OFFSET tempArray
    push  OFFSET titleAll
    call  displayTempArray

    ; --- displayTempArray: daily highs (1 row x DAYS_MEASURED columns) ---
    push  DAYS_MEASURED
    push  1
    push  OFFSET dailyHighs
    push  OFFSET titleHighs
    call  displayTempArray

    ; --- displayTempArray: daily lows (1 row x DAYS_MEASURED columns) ---
    push  DAYS_MEASURED
    push  1
    push  OFFSET dailyLows
    push  OFFSET titleLows
    call  displayTempArray

    ; --- displayTempWithString: average high ---
    call  CrLf
    mov   eax, averageHigh
    push  eax
    push  OFFSET titleAvgH
    call  displayTempWithString

    ; --- displayTempWithString: average low ---
    call  CrLf
    mov   eax, averageLow
    push  eax
    push  OFFSET titleAvgL
    call  displayTempWithString

    ; --- Farewell ---
    call  CrLf
    mov   edx, OFFSET farewell
    call  WriteString
    call  CrLf

    Invoke ExitProcess, 0
main ENDP

; =======================================================================
; Procedure: printGreeting
; Description: Displays program title, programmer name, extra-credit
;              notice, and a multi-line description of program functionality.
; Receives:   [EBP+8]  = reference to intro1 (title / programmer)
;             [EBP+12] = reference to intro2 (EC notice)
;             [EBP+16] = reference to intro3
;             [EBP+20] = reference to intro4
;             [EBP+24] = reference to intro5
;             [EBP+28] = reference to intro6
; Returns:    nothing (output to console)
; Pre-conditions:  All 6 parameters reference null-terminated strings.
; Post-conditions: Six lines printed; followed by a blank line.
; Registers changed: EDX (saved/restored)
; =======================================================================
printGreeting PROC
    push  ebp
    mov   ebp, esp
    push  edx

    call  CrLf
    mov   edx, [ebp+8]
    call  WriteString
    call  CrLf

    mov   edx, [ebp+12]
    call  WriteString
    call  CrLf
    call  CrLf

    mov   edx, [ebp+16]
    call  WriteString
    call  CrLf

    mov   edx, [ebp+20]
    call  WriteString
    call  CrLf

    mov   edx, [ebp+24]
    call  WriteString
    call  CrLf

    mov   edx, [ebp+28]
    call  WriteString
    call  CrLf
    call  CrLf

    pop   edx
    pop   ebp
    ret   24                         ; 6 DWORD params = 24 bytes
printGreeting ENDP

; =======================================================================
; Procedure: generateTemperatures
; Description: Fills tempArray with ARRAYSIZE pseudo-random integers in
;              the inclusive range [MIN_TEMP, MAX_TEMP]. Readings are
;              stored in row-major order: rows = days, columns = readings.
; Receives:   [EBP+8] = reference to tempArray (output)
; Returns:    tempArray populated.
; Pre-conditions:  Randomize has been called. tempArray >= ARRAYSIZE DWORDs.
; Post-conditions: Every element of tempArray is in [MIN_TEMP, MAX_TEMP].
; Registers changed: EAX, ECX, EDI (saved/restored)
; Uses globals: MIN_TEMP, MAX_TEMP, ARRAYSIZE
; =======================================================================
generateTemperatures PROC
    push  ebp
    mov   ebp, esp
    push  eax
    push  ecx
    push  edi

    mov   edi, [ebp+8]               ; EDI -> tempArray (register indirect)
    mov   ecx, ARRAYSIZE

genLoop:
    ; RandomRange(n) returns [0, n-1]; add MIN_TEMP to shift the range.
    mov   eax, (MAX_TEMP - MIN_TEMP + 1)
    call  RandomRange                ; EAX in [0, MAX-MIN]
    add   eax, MIN_TEMP              ; EAX in [MIN_TEMP, MAX_TEMP]
    mov   [edi], eax                 ; store via register indirect
    add   edi, 4
    loop  genLoop

    pop   edi
    pop   ecx
    pop   eax
    pop   ebp
    ret   4
generateTemperatures ENDP

; =======================================================================
; Procedure: findDailyHighs
; Description: Iterates over each day's TEMPS_PER_DAY readings in
;              tempArray and writes the daily maximum to dailyHighs.
; Receives:   [EBP+8]  = reference to tempArray  (input)
;             [EBP+12] = reference to dailyHighs (output)
; Returns:    dailyHighs[i] = maximum of tempArray row i.
; Pre-conditions:  tempArray is fully populated.
; Post-conditions: dailyHighs populated; tempArray unchanged.
; Registers changed: EAX, EBX, ECX, EDX, ESI, EDI (saved/restored)
; Uses globals: DAYS_MEASURED, TEMPS_PER_DAY
; =======================================================================
findDailyHighs PROC
    push  ebp
    mov   ebp, esp
    push  eax
    push  ebx
    push  ecx
    push  edx
    push  esi
    push  edi

    mov   esi, [ebp+8]               ; ESI -> tempArray
    mov   edi, [ebp+12]              ; EDI -> dailyHighs
    mov   edx, DAYS_MEASURED

outerHighLoop:
    mov   ecx, TEMPS_PER_DAY
    mov   eax, [esi]                 ; seed max with first reading of the day
    add   esi, 4
    dec   ecx

innerHighLoop:
    mov   ebx, [esi]
    cmp   ebx, eax
    jle   notHigher
    mov   eax, ebx
notHigher:
    add   esi, 4
    loop  innerHighLoop

    mov   [edi], eax                 ; store daily maximum
    add   edi, 4
    dec   edx
    jnz   outerHighLoop

    pop   edi
    pop   esi
    pop   edx
    pop   ecx
    pop   ebx
    pop   eax
    pop   ebp
    ret   8
findDailyHighs ENDP

; =======================================================================
; Procedure: findDailyLows
; Description: Iterates over each day's TEMPS_PER_DAY readings in
;              tempArray and writes the daily minimum to dailyLows.
; Receives:   [EBP+8]  = reference to tempArray (input)
;             [EBP+12] = reference to dailyLows (output)
; Returns:    dailyLows[i] = minimum of tempArray row i.
; Pre-conditions:  tempArray is fully populated.
; Post-conditions: dailyLows populated; tempArray unchanged.
; Registers changed: EAX, EBX, ECX, EDX, ESI, EDI (saved/restored)
; Uses globals: DAYS_MEASURED, TEMPS_PER_DAY
; =======================================================================
findDailyLows PROC
    push  ebp
    mov   ebp, esp
    push  eax
    push  ebx
    push  ecx
    push  edx
    push  esi
    push  edi

    mov   esi, [ebp+8]               ; ESI -> tempArray
    mov   edi, [ebp+12]              ; EDI -> dailyLows
    mov   edx, DAYS_MEASURED

outerLowLoop:
    mov   ecx, TEMPS_PER_DAY
    mov   eax, [esi]                 ; seed min with first reading of the day
    add   esi, 4
    dec   ecx

innerLowLoop:
    mov   ebx, [esi]
    cmp   ebx, eax
    jge   notLower
    mov   eax, ebx
notLower:
    add   esi, 4
    loop  innerLowLoop

    mov   [edi], eax                 ; store daily minimum
    add   edi, 4
    dec   edx
    jnz   outerLowLoop

    pop   edi
    pop   esi
    pop   edx
    pop   ecx
    pop   ebx
    pop   eax
    pop   ebp
    ret   8
findDailyLows ENDP

; =======================================================================
; Procedure: calcAverageLowHighTemps
; Description: Sums each of the DAYS_MEASURED-element dailyHighs and
;              dailyLows arrays and computes a truncated integer average
;              for each, writing results through caller-supplied references.
; Receives:   [EBP+8]  = reference to dailyHighs  (input)
;             [EBP+12] = reference to dailyLows   (input)
;             [EBP+16] = reference to averageHigh (output)
;             [EBP+20] = reference to averageLow  (output)
; Returns:    *averageHigh and *averageLow updated.
; Pre-conditions:  dailyHighs and dailyLows are fully populated.
; Post-conditions: *averageHigh = floor(sum(dailyHighs) / DAYS_MEASURED)
;                  *averageLow  = floor(sum(dailyLows)  / DAYS_MEASURED)
; Registers changed: EAX, EBX, ECX, EDX, ESI, EDI (saved/restored)
; Uses globals: DAYS_MEASURED
; =======================================================================
calcAverageLowHighTemps PROC
    push  ebp
    mov   ebp, esp
    push  eax
    push  ebx
    push  ecx
    push  edx
    push  esi
    push  edi

    ; -- Average high --
    mov   esi, [ebp+8]               ; ESI -> dailyHighs
    mov   ecx, DAYS_MEASURED
    xor   eax, eax

sumHighLoop:
    add   eax, [esi]
    add   esi, 4
    loop  sumHighLoop

    xor   edx, edx
    mov   ebx, DAYS_MEASURED
    div   ebx                        ; EAX = truncated average high
    mov   edi, [ebp+16]
    mov   [edi], eax

    ; -- Average low --
    mov   esi, [ebp+12]              ; ESI -> dailyLows
    mov   ecx, DAYS_MEASURED
    xor   eax, eax

sumLowLoop:
    add   eax, [esi]
    add   esi, 4
    loop  sumLowLoop

    xor   edx, edx
    mov   ebx, DAYS_MEASURED
    div   ebx                        ; EAX = truncated average low
    mov   edi, [ebp+20]
    mov   [edi], eax

    pop   edi
    pop   esi
    pop   edx
    pop   ecx
    pop   ebx
    pop   eax
    pop   ebp
    ret   16
calcAverageLowHighTemps ENDP

; =======================================================================
; Procedure: displayTempArray
; Description: Displays a 2D array of DWORD temperatures preceded by a
;              descriptive title. Prints someRows rows, each with
;              someColumns values separated by two spaces. Works for any
;              valid row/column count including a single-row array.
;
;              EC usage: when called for the full temperature grid, main
;              passes rows = TEMPS_PER_DAY and columns = DAYS_MEASURED so
;              each printed row is one time slot across all days (i.e., each
;              column of output corresponds to one day). The data in tempArray
;              is stored row-major (row = day), so we must transpose on the fly:
;              element [day * TEMPS_PER_DAY + slot] is read by computing an
;              offset from the array base using base+offset addressing.
;              For the daily high/low arrays (single row, no transposition
;              needed), the procedure simply reads sequentially.
;
;              The procedure detects the transposed case when
;              someRows == TEMPS_PER_DAY AND someColumns == DAYS_MEASURED.
;              In that case it accesses element [col * TEMPS_PER_DAY + row]
;              instead of the sequential [row * someColumns + col] order.
;
; Receives:   [EBP+8]  = reference to someTitle  (input)
;             [EBP+12] = reference to someArray  (input)
;             [EBP+16] = someRows    (value, input)
;             [EBP+20] = someColumns (value, input)
; Returns:    nothing (output to console)
; Pre-conditions:  someArray holds at least someRows * someColumns DWORDs.
; Post-conditions: Array printed to console in requested layout.
; Registers changed: EAX, EBX, ECX, EDX, ESI (saved/restored)
; =======================================================================
displayTempArray PROC
    push  ebp
    mov   ebp, esp
    push  eax
    push  ebx
    push  ecx
    push  edx
    push  esi
    push  edi

    ; Print title
    call  CrLf
    mov   edx, [ebp+8]               ; someTitle
    call  WriteString
    call  CrLf

    ; Determine whether to transpose (EC path) or print sequentially.
    ; Transpose when: someRows == TEMPS_PER_DAY  AND  someColumns == DAYS_MEASURED
    mov   eax, [ebp+16]              ; someRows
    mov   ebx, [ebp+20]              ; someColumns
    cmp   eax, TEMPS_PER_DAY
    jne   normalPrint
    cmp   ebx, DAYS_MEASURED
    jne   normalPrint

    ; ----------------------------------------------------------------
    ; TRANSPOSED PRINT  (EC: column = day, row = time slot)
    ; For row r, col c: element index = c * TEMPS_PER_DAY + r
    ; ESI = base of array; EBX = outer row counter; ECX = inner col counter
    ; ----------------------------------------------------------------
    mov   esi, [ebp+12]              ; ESI -> base of someArray
    mov   ebx, TEMPS_PER_DAY        ; outer loop: time-slot rows

transRowLoop:
    mov   ecx, DAYS_MEASURED        ; inner loop: day columns
    mov   eax, TEMPS_PER_DAY
    sub   eax, ebx                  ; EAX = current row index r (0-based)
    push  eax                       ; save r on stack

transColLoop:
    ; current col index c = DAYS_MEASURED - ecx  (ECX counts down)
    mov   eax, DAYS_MEASURED
    sub   eax, ecx                  ; EAX = col index c
    ; element index = c * TEMPS_PER_DAY + r
    imul  eax, TEMPS_PER_DAY        ; EAX = c * TEMPS_PER_DAY
    mov   edi, [esp]                ; EDI = r  (peek at saved r)
    add   eax, edi                  ; EAX = c * TEMPS_PER_DAY + r
    shl   eax, 2                    ; byte offset = index * 4
    add   eax, esi                  ; EAX = &someArray[c*TEMPS_PER_DAY + r]
    mov   eax, [eax]                ; load element via base+offset
    call  WriteDec

    dec   ecx
    jz    transEndCol
    mov   edx, OFFSET twoSpaces
    call  WriteString
    jmp   transColLoop

transEndCol:
    pop   eax                       ; discard saved r
    call  CrLf
    dec   ebx
    jnz   transRowLoop

    jmp   doneDisplay

    ; ----------------------------------------------------------------
    ; NORMAL (SEQUENTIAL) PRINT  -- used for dailyHighs / dailyLows
    ; ----------------------------------------------------------------
normalPrint:
    mov   esi, [ebp+12]              ; ESI -> someArray (register indirect base)
    mov   ebx, [ebp+16]              ; EBX = someRows

normalRowLoop:
    mov   ecx, [ebp+20]              ; ECX = someColumns

normalColLoop:
    mov   eax, [esi]                 ; load element via register indirect
    call  WriteDec
    add   esi, 4

    dec   ecx
    jz    normalEndCol
    mov   edx, OFFSET twoSpaces
    call  WriteString
    jmp   normalColLoop

normalEndCol:
    call  CrLf
    dec   ebx
    jnz   normalRowLoop

doneDisplay:
    call  CrLf
    pop   edi
    pop   esi
    pop   edx
    pop   ecx
    pop   ebx
    pop   eax
    pop   ebp
    ret   16
displayTempArray ENDP

; =======================================================================
; Procedure: displayTempWithString
; Description: Prints a null-terminated title string immediately followed
;              by a decimal integer value on the same line, then a newline.
; Receives:   [EBP+8]  = reference to someTitle (input)
;             [EBP+12] = someValue (value, input)
; Returns:    nothing
; Pre-conditions:  someTitle references a null-terminated string.
; Post-conditions: Output line: "<title><value>" + newline.
; Registers changed: EAX, EDX (saved/restored)
; =======================================================================
displayTempWithString PROC
    push  ebp
    mov   ebp, esp
    push  eax
    push  edx

    mov   edx, [ebp+8]               ; someTitle
    call  WriteString
    mov   eax, [ebp+12]              ; someValue (by value)
    call  WriteDec
    call  CrLf

    pop   edx
    pop   eax
    pop   ebp
    ret   8
displayTempWithString ENDP

END main
