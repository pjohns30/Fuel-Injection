CON
        
  _clkmode = xtal1 + pll8x
  _xinfreq = 5_000_000     

OBJ

  'pst : "ParallaxSerialTerminal"
  'Stk : "StackLength"
  inj : "Inject"
  adc : "ADC_INPUT_DRIVER"
  flo : "Float32"
  rct : "RCTIME"

VAR              

  long injPerRev
  long targetAFR
  long exhaustTemp
  long oxygenSensor12bit
  long MAP
  long RPM
  long TPS

  long LocTPS12bit
  long flMAPkPa
  long LocexhaustTempF
  long LocoxygenSensor12bit
  long LocRPM
  long OSch
  long RPMch
  long MAPch
  long EGT1ch
  long EGT2ch
  long TPSch
  long check
  long flRPMconst
  long flMAPconst
  long flMAPconst2

  long TPSHalf
  long flVolOfOneRev
  long constR
  long flowRate1
  long flowRate2
  long flowRate3
  long flowRate4
  long flCycPerkg1
  long flCycPerkg2
  long flCycPerkg3
  long flCycPerkg4
  long flCycPerMin
  long flAFR
  long gloCount
  long gloPIN
  long gloCycPerDiv
  long cycPerDiv
  long gloCycPerInj
  long cycPerInj
  long LocMATK
  long LocECTF
  long Cog
  long Stack[128] 'make bigger for code adjustments and retest
  long gloRPM

  long startT
  long stopT
  long clkfreqReduced
  long LocPin
  long minCycPerInj
  long maxCycPerInj
  long mulFac
  long minfreq
  long maxfreq
  long loop
  long fuelPumpState
  long fuelPumpPin

  long MATPin
  long ECTPin
  long MATDecay
  long ECTDecay
  long MATCapuF
  long ECTCapuF
  long flMATConst
  long flECTConst
  long flMATConst2
  long flECTConst2

PUB Main

  stop
  'Stk.Init(@Stack, 64)
  Cog := cognew(Run, @Stack) + 1
  'waitcnt(clkfreq * 10 + cnt)
  'Stk.GetLength(30, 115200)
  
PRI stop
                                                     
  if(Cog)
    cogstop(Cog~ - 1)

PRI Run

  'pst.Start(115200)
  
  MATPin := 1
  ECTPin := 1
  MATCapuF := 1
  ECTCapuF := 1
  flMATConst := flo.FMul(flo.FDiv(flo.FFloat(693), flo.FFloat(1000)), flo.FFloat(MATCapuF))
  flECTConst := flo.FMul(flo.FDiv(flo.FFloat(693), flo.FFloat(1000)), flo.FFloat(ECTCapuF))
  flMATConst2 := 1
  flECTConst2 := flo.FDiv(flo.FFloat(-39),flo.FFloat(1000))
  
  fuelPumpPin := 16
  dira[fuelPumpPin]~~
  outa[fuelPumpPin] := 1 'fuel pump prime
  fuelPumpState := 1
  flo.start
  adc.start(8, 9, 10, 11, 8, 4, 12, 1)
  rct.start(MATPin, 1, @MATDecay, ECTPin, 1, @ECTDecay)
  clkfreqReduced := (clkfreq/4) 'since spin doesn't have an unsigned long option outside of assembly code a smaller number was needed to calculate cycPer*** to avoid overflow 
  minfreq := clkfreqReduced/200 'its being tested against the reduced frequencies
  maxfreq := clkfreqReduced/10  'found through testing probably different for different injectors and fuel pressures
  mincycPerInj := 200000 'arbitrary used for debugging problems

  injPerRev := 1 'number of injections per revolution plans to be RPM/% of duty cycle dependent
  targetAFR := 13

  check := 0
  OSch := 0
  RPMch := 1
  MAPch := 2
  TPSch := 3
  EGT1ch := 4
  EGT2ch := 5
  TPSHalf := 2000
  flVolOfOneRev := flo.FDiv(flo.FFloat(245), flo.FFloat(100000)) '4.9 liters / 2 and converted to m^3 
  constR := flo.FDiv(flo.FFloat(287), flo.FFloat(1000)) 'kJ/(kg*K)
  flowRate1 := flo.FFloat(65)
  flowRate2 := flo.FFloat(130)
  flowRate3 := flo.FFloat(195)
  flowRate4 := flo.FFloat(260) 'in lbs per hr
  
  flCycPerkg1 := flo.FMul(flo.FFloat(3600), flo.FDiv(flo.FFloat(clkfreqReduced), flo.FMul(flowRate1, flo.FDiv(flo.FFloat(45359237),flo.FFloat(100000000)))))
  flCycPerkg2 := flo.FMul(flo.FFloat(3600), flo.FDiv(flo.FFloat(clkfreqReduced), flo.FMul(flowRate2, flo.FDiv(flo.FFloat(45359237),flo.FFloat(100000000)))))
  flCycPerkg3 := flo.FMul(flo.FFloat(3600), flo.FDiv(flo.FFloat(clkfreqReduced), flo.FMul(flowRate3, flo.FDiv(flo.FFloat(45359237),flo.FFloat(100000000)))))
  flCycPerkg4 := flo.FMul(flo.FFloat(3600), flo.FDiv(flo.FFloat(clkfreqReduced), flo.FMul(flowRate4, flo.FDiv(flo.FFloat(45359237),flo.FFloat(100000000)))))'4.409*10^8

  flCycPerMin := flo.FFloat(clkfreqReduced*60)'6*10^8 'not a true variable name but clkfreq*60 is too big for a 32bit int so it needs multiplied by after you divide it by something
  flAFR := flo.FFloat(targetAFR)

  flRPMconst := flo.FDiv(flo.FFloat(60),flo.FFloat(151))'0.397
  flMAPconst := flo.FDiv(flo.FFloat(1693),flo.FFloat(100000))'0.01693 
  flMAPconst2 := flo.FDiv(flo.FFloat(1635), flo.FFloat(100))'16.35
      
  gloCycPerDiv := 0
  gloCycPerInj := 0
  gloCount := injPerRev
  gloPin := 0
  gloRPM := 0
  
  inj.Start(@gloPin, @gloCount, @gloCycPerDiv, @gloCycPerInj)
  'inj.setEverything(gloPin, gloCount, gloCycPerInj, gloCycPerDiv, gloRPM)
  LocMATK := 273 'in the repeat loop bc they need to be refreshed with an RCtime function when it gets programmed
  LocECTF := 195

  repeat(TRUE)

    LocMATK := flo.FRound(flo.FDiv(flo.FFLoat(MATDecay), flMATConst))
    LocECTF := flo.FRound(flo.FMul(flECTConst2, flo.FDiv(flo.FFLoat(ECTDecay), flECTConst))) + 219
    
    LocTPS12bit := adc.getval(TPSch)

    'startT := cnt
    
    'flMAPkPa := flo.FAdd(flo.FMul(flMAPconst, flo.FFloat(adc.getval(MAPch))), flMAPconst2)'.01693*vol+16.35

    'stopT := cnt
    
    'pst.Str(String("MAP(cyc) = "))
    'pst.dec((stopT-startT))
    'pst.NewLine
    
    'LocexhaustTempF := flo.FRound(flo.FAdd(flo.FFloat(75), flo.FMul(flo.FFloat(43789), flo.FDiv(flo.FDiv(flo.FAdd(flo.FFloat(adc.getval(EGT2ch)), flo.FFloat(adc.getval(EGT1ch))), flo.FFloat(2)), flo.FFloat(1000)))))
                                                                                                   
    'if(check == 1)
    '  LocoxygenSensor12bit := adc.getval(OSch)
    'else
    '  LocoxygenSensor12bit := 500
    '  if(adc.getval(OSch) > 450)'assume its not hot enough to work correctly
    '    check := 1

    'startT := cnt
    adc.setthreshold (0, 1000)
    LocRPM := flo.FRound(flo.FMul(flo.FFloat(adc.getfreq(RPMch, 20, 2, 1)), flRPMconst))
    '(teeth/sec)*(60sec/min)*(rev/151teeth)=(rev/min)
    adc.resetmaxminall

'    stopT := cnt
    'LocRPM := 2000
 '   pst.Str(String("RPM(cyc) = "))
  '  pst.dec((stopT-startT))
   ' pst.NewLine

'    startT := cnt
    if(LocRPM == 0)
      LocPin := 0
      if(fuelPumpState == 1)
        outa[fuelPumpPin] := 0
        fuelPumpState := 0
        
    else
      if(fuelPumpState == 0)
        outa[fuelPumpPin] := 1
        fuelPumpState := 1
        
      cycPerDiv := flo.FRound(flo.FDiv(flo.FDiv(flCycPerMin, flo.FFloat(LocRPM)), flo.FFloat(injPerRev)))
      '(min/Rev)*(60sec/min)*(cyc/sec)
      'cycPerInj := flo.FRound(flo.FMul(flo.FDiv(flo.FMul(flMAPkPa, flVolOfOneRev), flo.FMul(constR, flo.FMul(flo.FFloat(injPerRev), flo.FMul(flAFR, flo.FFloat(LocMATK))))), flCycPerkg))
      if(LocRPM > 2600 | LocTPS12bit > TPSHalf)
        cycPerInj := flo.FRound(flo.FMul(flo.FDiv(flo.FMul(flo.FAdd(flo.FMul(flMAPconst, flo.FFloat(adc.getval(MAPch))), flMAPconst2), flVolOfOneRev), flo.FMul(constR, flo.FMul(flo.FFloat(injPerRev), flo.FMul(flAFR, flo.FFloat(LocMATK))))), flCycPerkg4))
        '2.27*10^-9*cyc = (MAP*vol of half of the cylinders)/(AFR * (.287) * MAT)
        LocPin := 4
      else
        cycPerInj := flo.FRound(flo.FMul(flo.FDiv(flo.FMul(flo.FAdd(flo.FMul(flMAPconst, flo.FFloat(adc.getval(MAPch))), flMAPconst2), flVolOfOneRev), flo.FMul(constR, flo.FMul(flo.FFloat(injPerRev), flo.FMul(flAFR, flo.FFloat(LocMATK))))), flCycPerkg2))
        LocPin := 2

      mulFac := 1
      loop := FALSE
      repeat while(loop == FALSE)
       
        if((mulFac * cycPerInj) < minCycPerInj)
        
          mulFac := mulFac + 1
          
        else
        
          cycPerInj := cycPerInj * mulFac
          cycPerDiv := cycPerDiv * mulFac
          loop := TRUE

'    stopT := cnt

'    pst.Str(String("CalValues(cyc) = "))
 '   pst.dec((stopT-startT))
  '  pst.NewLine
    
    'if(LocRPM == 0)
    '  cycPerDiv := 0
    '  cycPerInj := 0

'    startT := cnt
    
    gloCycPerDiv := cycPerDiv
    gloCycPerInj := cycPerInj
'    gloCount := injPerRev 'right now this doesn't change so it doesn't need updated
    gloPin := LocPin

'    stopT := cnt

'    pst.Str(String("PassingAddys(cyc) = "))
 '   pst.dec((stopT-startT))
  '  pst.NewLine

{    startT := cnt
    inj.setEverything(gloPin, gloCount, gloCycPerInj, gloCycPerDiv, gloRPM)
    stopT := cnt
    pst.Str(String("PassingValues(cyc) = "))
    pst.dec((stopT-startT))
    pst.NewLine}

 {   pst.Str(String("Exhaust Temp(F)= "))
    pst.dec(LocexhaustTempF)
    pst.NewLine

    pst.Str(String("OS(12bit) = "))
    pst.dec(LocoxygenSensor12bit)
    pst.NewLine

    pst.Str(String("MAP(kPa) = "))
    pst.dec(flo.FRound(flMAPkPa))
    pst.NewLine

    pst.Str(String("RPM = "))
    pst.dec(LocRPM)
    pst.NewLine

    pst.Str(String("CycPerDiv = "))
    pst.dec(cycPerDiv)
    pst.NewLine

    pst.Str(String("CycPerInj = "))
    pst.dec(cycPerInj)
    pst.NewLine

    pst.Str(String("TPS(12bit) = "))
    pst.dec(LocTPS12bit)
    pst.NewLine
 }
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