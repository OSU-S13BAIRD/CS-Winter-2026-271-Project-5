TITLE Chaotic Temperature Statistics     (Proj5_bairsamu.asm)
; Author: Samuel Baird
; Last Modified: 03/02/2026
; OSU email address: bairsamu@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number: 5                Due Date: 03/01/2026
; Description: Generates DAYS_MEASURED * TEMPS_PER_DAY random temperature readings
;              on a diurnal cycle (low at start/end of day, high at midday) in the
;              range [MIN_TEMP, MAX_TEMP], stores them in a flat array, then finds
;              the daily high and low for each day, computes the truncated average
;              of those daily highs and lows, and displays everything with
;              descriptive titles. The program loops until the user chooses to quit.
;              All sub-tasks are broken into separate procedures that communicate
;              exclusively through stack-passed parameters.
;
; **EC1: Temperatures are displayed column-by-column (each column = one day) rather
;        than the default row-per-day layout.
; **EC2: Temperatures are generated on a diurnal cycle -- low at day start/end,
;        peaking near midday -- with random variation. Days chain together so the
;        next day starts where the previous day ended.

INCLUDE Irvine32.inc

; -----------------------------------------------------------------------
; Global Constants
; -----------------------------------------------------------------------
DAYS_MEASURED   EQU  14
TEMPS_PER_DAY   EQU  11
MIN_TEMP        EQU  20
MAX_TEMP        EQU  80
ARRAYSIZE       EQU  DAYS_MEASURED * TEMPS_PER_DAY   ; 154 total readings

; Diurnal cycle constants
TEMP_RANGE      EQU  (MAX_TEMP - MIN_TEMP)           ; 60
MID_SLOT        EQU  (TEMPS_PER_DAY / 2)             ; slot index of daily peak (5)
MAX_DELTA       EQU  6                               ; max random step per slot

; -----------------------------------------------------------------------
.data
; -----------------------------------------------------------------------

; -- Introduction strings --
intro1      BYTE  "Welcome to Chaotic Temperature Statistics, by Samuel Baird", 0
intro2      BYTE  "**EC: Temperature array is displayed column-by-column (each column = one day).", 0
intro3      BYTE  "**EC: Temperatures are generated such that each day starts cold, gradually", 0
intro4      BYTE  "     grows warmer until around noon, and then becomes colder until the end", 0
intro5      BYTE  "     of the day. Each day chains from where the previous day ended.", 0
intro6      BYTE  "This program generates a series of temperature readings, X per day for Y days", 0
intro7      BYTE  "(depending on CONSTANTs), and performs basic statistics: daily high and low", 0
intro8      BYTE  "and average high and low temps. Results are printed with descriptive titles.", 0

; -- Array / section title strings --
titleAll    BYTE  "Temperature readings (one column = one day):", 0
titleHighs  BYTE  "Daily high temperatures:", 0
titleLows   BYTE  "Daily low temperatures:", 0
titleAvgH   BYTE  "Truncated average high temperature: ", 0
titleAvgL   BYTE  "Truncated average low temperature:  ", 0

; -- Loop prompt --
promptAgain BYTE  "Run again? (y/n): ", 0
farewell    BYTE  "Thanks for using Chaotic Temperature Statistics. Goodbye!", 0

; -- Arrays --
tempArray   DWORD  ARRAYSIZE DUP(?)
dailyHighs  DWORD  DAYS_MEASURED DUP(?)
dailyLows   DWORD  DAYS_MEASURED DUP(?)

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
; Description: Entry point. Seeds the RNG once, then loops:
;              greeting -> generate -> highs/lows -> averages -> display
;              -> ask user to continue. Exits when user enters 'n'/'N'.
; Receives:   nothing
; Returns:    nothing
; Registers changed: EAX, EDX
; =======================================================================
main PROC
    call  Randomize

    ; --- printGreeting ---
    push  OFFSET intro8
    push  OFFSET intro7
    push  OFFSET intro6
    push  OFFSET intro5
    push  OFFSET intro4
    push  OFFSET intro3
    push  OFFSET intro2
    push  OFFSET intro1
    call  printGreeting

mainLoop:
    ; --- generateTemperatures (diurnal EC2) ---
    push  OFFSET tempArray
    call  generateTemperatures

    ; --- findDailyHighs ---
    push  OFFSET dailyHighs
    push  OFFSET tempArray
    call  findDailyHighs

    ; --- findDailyLows ---
    push  OFFSET dailyLows
    push  OFFSET tempArray
    call  findDailyLows

    ; --- calcAverageLowHighTemps ---
    push  OFFSET averageLow
    push  OFFSET averageHigh
    push  OFFSET dailyLows
    push  OFFSET dailyHighs
    call  calcAverageLowHighTemps

    ; --- displayTempArray: full grid (EC1 transposed) ---
    push  DAYS_MEASURED
    push  TEMPS_PER_DAY
    push  OFFSET tempArray
    push  OFFSET titleAll
    call  displayTempArray

    ; --- displayTempArray: daily highs ---
    push  DAYS_MEASURED
    push  1
    push  OFFSET dailyHighs
    push  OFFSET titleHighs
    call  displayTempArray

    ; --- displayTempArray: daily lows ---
    push  DAYS_MEASURED
    push  1
    push  OFFSET dailyLows
    push  OFFSET titleLows
    call  displayTempArray

    ; --- displayTempWithString: averages ---
    call  CrLf
    mov   eax, averageHigh
    push  eax
    push  OFFSET titleAvgH
    call  displayTempWithString

    call  CrLf
    mov   eax, averageLow
    push  eax
    push  OFFSET titleAvgL
    call  displayTempWithString

    ; --- Ask user to run again ---
    call  CrLf
    mov   edx, OFFSET promptAgain
    call  WriteString
    call  ReadChar               ; reads one char into AL, echoes it
    call  CrLf

    ; If 'y' or 'Y', loop again
    cmp   al, 'y'
    je    mainLoop
    cmp   al, 'Y'
    je    mainLoop

    ; --- Farewell ---
    call  CrLf
    mov   edx, OFFSET farewell
    call  WriteString
    call  CrLf

    Invoke ExitProcess, 0
main ENDP

; =======================================================================
; Procedure: printGreeting
; Description: Displays program title, EC notices, and functionality desc.
;              Format matches required EC output spec:
;                Title
;                **EC: notice 1
;                **EC: notice 2 (continued lines)
;                (blank line)
;                Description lines
; Receives:   [EBP+8]  = intro1 (title)
;             [EBP+12] = intro2 (EC1 notice)
;             [EBP+16] = intro3 (EC2 notice line 1)
;             [EBP+20] = intro4 (EC2 notice line 2)
;             [EBP+24] = intro5 (EC2 notice line 3)
;             [EBP+28] = intro6 (description line 1)
;             [EBP+32] = intro7 (description line 2)
;             [EBP+36] = intro8 (description line 3)
; Returns:    nothing
; Registers changed: EDX (saved/restored)
; =======================================================================
printGreeting PROC
    push  ebp
    mov   ebp, esp
    push  edx

    ; Title
    call  CrLf
    mov   edx, [ebp+8]
    call  WriteString
    call  CrLf

    ; EC notices (immediately after title, no blank line between)
    mov   edx, [ebp+12]
    call  WriteString
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

    ; Blank line between EC notices and description
    call  CrLf

    ; Description
    mov   edx, [ebp+28]
    call  WriteString
    call  CrLf

    mov   edx, [ebp+32]
    call  WriteString
    call  CrLf

    mov   edx, [ebp+36]
    call  WriteString
    call  CrLf
    call  CrLf

    pop   edx
    pop   ebp
    ret   32                         ; 8 DWORD params = 32 bytes
printGreeting ENDP

; =======================================================================
; Procedure: generateTemperatures
; Description: **EC2** Fills tempArray using a diurnal cycle. Each day the
;              temperature rises from the start toward midday (slot MID_SLOT)
;              then falls toward end of day. A random delta [1, MAX_DELTA] is
;              added or subtracted each slot (direction determined by phase).
;              Values are clamped to [MIN_TEMP, MAX_TEMP]. Days chain: the
;              first reading of day N+1 equals the last reading of day N.
;
;              Algorithm per slot:
;                phase = rising  if slot < MID_SLOT
;                phase = falling if slot >= MID_SLOT
;                delta = RandomRange(MAX_DELTA) + 1   ; [1, MAX_DELTA]
;                rising:  new = prev + delta; if > MAX_TEMP -> new = MAX_TEMP
;                falling: new = prev - delta; if < MIN_TEMP -> new = MIN_TEMP
;
; Receives:   [EBP+8] = reference to tempArray (output)
; Returns:    tempArray populated with diurnal-cycle readings.
; Pre-conditions:  Randomize called. Array >= ARRAYSIZE DWORDs.
; Post-conditions: Every element in [MIN_TEMP, MAX_TEMP].
; Registers changed: EAX, EBX, ECX, EDX, ESI (saved/restored)
; Uses globals: MIN_TEMP, MAX_TEMP, DAYS_MEASURED, TEMPS_PER_DAY,
;               MID_SLOT, MAX_DELTA
; =======================================================================
generateTemperatures PROC
    push  ebp
    mov   ebp, esp
    push  eax
    push  ebx
    push  ecx
    push  edx
    push  esi

    mov   esi, [ebp+8]               ; ESI -> tempArray

    ; Seed the very first temperature near the low end of the range
    ; Use RandomRange(TEMP_RANGE/3)+MIN_TEMP so day 1 starts cool
    mov   eax, (TEMP_RANGE / 3 + 1)
    call  RandomRange
    add   eax, MIN_TEMP              ; starting temp in lower third
    mov   ebx, eax                  ; EBX = "current temperature" across all days

    mov   edx, DAYS_MEASURED        ; EDX = day counter (outer loop)

dayLoop:
    ; ECX = slot index within day (0 .. TEMPS_PER_DAY-1)
    xor   ecx, ecx

slotLoop:
    ; Store current temperature
    mov   [esi], ebx
    add   esi, 4

    ; Determine if this is the last slot of the day
    mov   eax, ecx
    inc   eax
    cmp   eax, TEMPS_PER_DAY
    je    nextSlotDone              ; don't compute next temp on last slot of day

    ; Generate random delta [1, MAX_DELTA]
    mov   eax, MAX_DELTA
    call  RandomRange               ; EAX in [0, MAX_DELTA-1]
    inc   eax                       ; EAX in [1, MAX_DELTA]

    ; Determine phase: rising if ecx < MID_SLOT, else falling
    cmp   ecx, MID_SLOT
    jge   fallingPhase

risingPhase:
    add   ebx, eax                  ; temp rises
    cmp   ebx, MAX_TEMP
    jle   phaseDone
    mov   ebx, MAX_TEMP             ; clamp to ceiling
    jmp   phaseDone

fallingPhase:
    sub   ebx, eax                  ; temp falls
    cmp   ebx, MIN_TEMP
    jge   phaseDone
    mov   ebx, MIN_TEMP             ; clamp to floor

phaseDone:
nextSlotDone:
    inc   ecx
    cmp   ecx, TEMPS_PER_DAY
    jl    slotLoop
    ; EBX already holds end-of-day temp; next day chains from it

    dec   edx
    jnz   dayLoop

    pop   esi
    pop   edx
    pop   ecx
    pop   ebx
    pop   eax
    pop   ebp
    ret   4
generateTemperatures ENDP

; =======================================================================
; Procedure: findDailyHighs
; Description: Iterates over each day's TEMPS_PER_DAY readings and writes
;              the daily maximum to dailyHighs.
; Receives:   [EBP+8]  = reference to tempArray  (input)
;             [EBP+12] = reference to dailyHighs (output)
; Returns:    dailyHighs[i] = max of tempArray row i.
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

    mov   esi, [ebp+8]
    mov   edi, [ebp+12]
    mov   edx, DAYS_MEASURED

outerHighLoop:
    mov   ecx, TEMPS_PER_DAY
    mov   eax, [esi]
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

    mov   [edi], eax
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
; Description: Iterates over each day's TEMPS_PER_DAY readings and writes
;              the daily minimum to dailyLows.
; Receives:   [EBP+8]  = reference to tempArray  (input)
;             [EBP+12] = reference to dailyLows  (output)
; Returns:    dailyLows[i] = min of tempArray row i.
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

    mov   esi, [ebp+8]
    mov   edi, [ebp+12]
    mov   edx, DAYS_MEASURED

outerLowLoop:
    mov   ecx, TEMPS_PER_DAY
    mov   eax, [esi]
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

    mov   [edi], eax
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
; Description: Computes truncated average of dailyHighs and dailyLows.
; Receives:   [EBP+8]  = reference to dailyHighs  (input)
;             [EBP+12] = reference to dailyLows   (input)
;             [EBP+16] = reference to averageHigh (output)
;             [EBP+20] = reference to averageLow  (output)
; Returns:    *averageHigh and *averageLow updated.
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
    mov   esi, [ebp+8]
    mov   ecx, DAYS_MEASURED
    xor   eax, eax

sumHighLoop:
    add   eax, [esi]
    add   esi, 4
    loop  sumHighLoop

    xor   edx, edx
    mov   ebx, DAYS_MEASURED
    div   ebx
    mov   edi, [ebp+16]
    mov   [edi], eax

    ; -- Average low --
    mov   esi, [ebp+12]
    mov   ecx, DAYS_MEASURED
    xor   eax, eax

sumLowLoop:
    add   eax, [esi]
    add   esi, 4
    loop  sumLowLoop

    xor   edx, edx
    mov   ebx, DAYS_MEASURED
    div   ebx
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
; Description: Prints a title then a 2-D array someRows x someColumns.
;              EC1: when called with rows=TEMPS_PER_DAY, cols=DAYS_MEASURED
;              the array is transposed on-the-fly so each column = one day.
; Receives:   [EBP+8]  = reference to someTitle
;             [EBP+12] = reference to someArray
;             [EBP+16] = someRows    (value)
;             [EBP+20] = someColumns (value)
; Returns:    nothing
; Registers changed: EAX, EBX, ECX, EDX, ESI, EDI (saved/restored)
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

    call  CrLf
    mov   edx, [ebp+8]
    call  WriteString
    call  CrLf

    mov   eax, [ebp+16]              ; someRows
    mov   ebx, [ebp+20]              ; someColumns
    cmp   eax, TEMPS_PER_DAY
    jne   normalPrint
    cmp   ebx, DAYS_MEASURED
    jne   normalPrint

    ; ---- TRANSPOSED PRINT (EC1) ----
    mov   esi, [ebp+12]
    mov   ebx, TEMPS_PER_DAY

transRowLoop:
    mov   ecx, DAYS_MEASURED
    mov   eax, TEMPS_PER_DAY
    sub   eax, ebx                   ; row index r
    push  eax

transColLoop:
    mov   eax, DAYS_MEASURED
    sub   eax, ecx                   ; col index c
    imul  eax, TEMPS_PER_DAY         ; c * TEMPS_PER_DAY
    mov   edi, [esp]                 ; r
    add   eax, edi                   ; index = c*TEMPS_PER_DAY + r
    shl   eax, 2
    add   eax, esi
    mov   eax, [eax]
    call  WriteDec

    dec   ecx
    jz    transEndCol
    mov   edx, OFFSET twoSpaces
    call  WriteString
    jmp   transColLoop

transEndCol:
    pop   eax
    call  CrLf
    dec   ebx
    jnz   transRowLoop
    jmp   doneDisplay

    ; ---- NORMAL SEQUENTIAL PRINT ----
normalPrint:
    mov   esi, [ebp+12]
    mov   ebx, [ebp+16]

normalRowLoop:
    mov   ecx, [ebp+20]

normalColLoop:
    mov   eax, [esi]
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
; Description: Prints a title string immediately followed by a decimal value.
; Receives:   [EBP+8]  = reference to someTitle
;             [EBP+12] = someValue (by value)
; Returns:    nothing
; Registers changed: EAX, EDX (saved/restored)
; =======================================================================
displayTempWithString PROC
    push  ebp
    mov   ebp, esp
    push  eax
    push  edx

    mov   edx, [ebp+8]
    call  WriteString
    mov   eax, [ebp+12]
    call  WriteDec
    call  CrLf

    pop   edx
    pop   eax
    pop   ebp
    ret   8
displayTempWithString ENDP

END main
