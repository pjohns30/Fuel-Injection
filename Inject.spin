VAR

  long Cog
  long Stack[32] 'recheck after adjustments to code
  long LocPin
  long LocCount
  long LocCycPerInj
  long LocCycPerDiv
  long Time
  long LocTempPin
  long LocTempCount
  long LocTempCycPerInj
  long LocTempCycPerDiv

OBJ

'  pst : "ParallaxSerialTerminal"
 ' Stk : "StackLength"
        
PUB Start(PinAddr, CountAddr, cycPerDivAddr, cycPerInjAddr)

  Stop  
  'Stk.Init(@Stack, 32)
  Cog := cognew(inject(PinAddr, CountAddr, cycPerDivAddr, cycPerInjAddr), @Stack) + 1
  'waitcnt(clkfreq * 4 + cnt)
  'Stk.GetLength(30, 115200)
  
PRI Stop
                                                   
  if(Cog)
    cogstop(Cog~ - 1)

PRI inject(PinAddr, CountAddr, cycPerDivAddr, cycPerInjAddr)

  LocTempPin := 0
  LocTempCount := 0
  LocTempCycPerInj := 0
  LocTempCycPerDiv := 0

  dira[12]~~        'this is suppose to se the pins to output
  outa[12] := FALSE 'this makes sure its in the low state even though I don't think its needed
  dira[13]~~
  outa[13] := FALSE
  dira[14]~~
  outa[14] := FALSE
  dira[15]~~
  outa[15] := FALSE

  repeat(TRUE)

    LocPin := LONG[PinAddr]     'prevents another cog from updating the variables in the middle of an injection
    LocCount := LONG[CountAddr] 'injections per revolutionbut it looks like thats too fast for the injectors
    LocCycPerInj := LONG[cycPerInjAddr]*4 'the *4 accounts for the clkfreqReduced in main
    LocCycPerDiv := LONG[cycPerDivAddr]*4
  
    if(LocPin > 0)
      if(LocPin == 1)
        Time := cnt
        repeat(LocCount)
          outa[14] := TRUE
          waitcnt((Time += LocCycPerInj))
          outa[14] := FALSE
          waitcnt((Time += (LocCycPerDiv - LocCycPerInj)))
      elseif(LocPin == 2)
        Time := cnt
        repeat(LocCount)
          outa[14] := TRUE
          outa[15] := TRUE
          waitcnt((Time += LocCycPerInj))
          outa[14] := FALSE
          outa[15] := FALSE
          waitcnt((Time += (LocCycPerDiv - LocCycPerInj)))
      elseif(LocPin == 3)
        Time := cnt
        repeat(LocCount)
          outa[15] := TRUE
          outa[13] := TRUE
          outa[14] := TRUE
          waitcnt((Time += LocCycPerInj))
          outa[15] := FALSE
          outa[13] := FALSE
          outa[14] := FALSE
          waitcnt((Time += (LocCycPerDiv - LocCycPerInj)))
      elseif(LocPin == 4)
        Time := cnt
        repeat(LocCount)
          outa[12] := TRUE
          outa[13] := TRUE
          outa[14] := TRUE
          outa[15] := TRUE
          waitcnt((Time += LocCycPerInj))
          outa[12] := FALSE
          outa[13] := FALSE
          outa[14] := FALSE
          outa[15] := FALSE
          waitcnt((Time += (LocCycPerDiv - LocCycPerInj)))
                    
PUB setEverything(tempPin, tempCount, tempInj, tempDiv) 'set everything but its a hair slower than using memory addresses but I was using it for debugging because I don't like pointers

  LocTempPin := tempPin
  LocTempCount := tempCount
  LocTempCycPerInj := tempInj
  LocTempCycPerDiv := tempDiv

{{

┌──────────────────────────────────────────────────────────────────────────────────────┐
│                           TERMS OF USE: MIT License                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this  │
│software and associated documentation files (the "Software"), to deal in the Software │ 
│without restriction, including without limitation the rights to use, copy, modify,    │
│merge, publish, distribute, sublicense, and/or sell copies of the Software, and to    │
│permit persons to whom the Software is furnished to do so, subject to the following   │
│conditions:                                                                           │                                            │
│                                                                                      │                                               │
│The above copyright notice and this permission notice shall be included in all copies │
│or substantial portions of the Software.                                              │
│                                                                                      │                                                │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,   │
│INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A         │
│PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT    │
│HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION     │
│OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE        │
│SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                │
└──────────────────────────────────────────────────────────────────────────────────────┘
}}  