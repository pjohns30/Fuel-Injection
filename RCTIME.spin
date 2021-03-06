{{
*****************************************
* RCTIME v1.0                           *
* Author: Beau Schwabe                  *
* Copyright (c) 2007 Parallax           *
* See end of file for terms of use.     *
*****************************************
}}

CON
  
VAR

   long cogon, cog
   long RCStack[64]
   long RCTemp
   long Mode
  
PUB start(Pin1,State1,MATaddy, Pin2,State2, ECTaddy)

'' Start RCTIME - starts a cog
'' returns false if no cog available
''
''   RCTIME_ptr = pointer to RCTIME parameters

  stop
  cogon := (cog := cognew(RCTIME(Pin1,State1,MATaddy, Pin2,State2, ECTaddy),@RCStack)) > 0
  Mode := 1

PUB stop

'' Stop RCTIME - frees a cog

  if cogon~
    cogstop(cog)
    
PUB RCTIME(Pin1,State1,MATaddy, Pin2,State2, ECTaddy)

    repeat
           outa[Pin1] := State1                 'make I/O an output in the State you wish to measure... and then charge cap
           dira[Pin1] := 1                               
           Pause1ms(1)                          'pause for 1mS to charge cap
           dira[Pin1] := 0                      'make I/O an input
           RCTemp := cnt                        'grab clock tick counter value
           WAITPEQ(1-State1,|< Pin1,0)          'wait until pin goes into the opposite state you wish to measure; State: 1=discharge 0=charge
           RCTemp := cnt - RCTemp               'see how many clock cycles passed until desired State changed
           RCTemp := RCTemp - 1600              'offset adjustment (entry and exit clock cycles Note: this can vary slightly with code changes)
           RCTemp := RCTemp >> 4                'scale result (divide by 16) <<-number of clock cycles per itteration loop
           long [MATaddy] := RCTemp             'Write RCTemp to RCValue

           outa[Pin2] := State2               
           dira[Pin2] := 1                               
           Pause1ms(1)                       
           dira[Pin2] := 0                    
           RCTemp := cnt                    
           WAITPEQ(1-State2,|< Pin2,0)      
           RCTemp := cnt - RCTemp          
           RCTemp := RCTemp - 1600        
           RCTemp := RCTemp >> 4              
           long [ECTaddy] := RCTemp        
           
           if Mode == 0                         'Check for forground (0) or background (1) mode of operation; forground = no seperate cog / background = seperate running cog
              quit

PUB Pause1ms(Period)|ClkCycles 
{{Pause execution for Period (in units of 1 ms).}}

  ClkCycles := ((clkfreq / 1000 * Period) - 4296) #> 381     'Calculate 1 ms time unit
  waitcnt(ClkCycles + cnt)                                   'Wait for designated time              

DAT
{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}    