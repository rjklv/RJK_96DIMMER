CON
        _clkmode = xtal1 + pll16x                                     'Standard clock mode * crystal frequency = 80 MHz
        _xinfreq = 5_000_000

        CLK_FREQ = ((_clkmode - xtal1) >> 6) * _xinfreq
        MS_001   = CLK_FREQ / 1_000
  
        txpin=30
        rxpin=31     
CON
        sctDispCLK = 9
        sctDispSDI = 10
        sctDispLA = 11
        
        sctEsc = 12
        sctUp = 13
        sctDown = 14
        sctEnter = 15
var
    long dispBuff
    byte charBuff[4]
    
OBJ
        serial    : "my_PBnJ_serial"     
        
PUB main|i
    serial.start(rxpin,txpin,115_200)
    
    dira[sctDispCLK]~~
    dira[sctDispSDI]~~
    dira[sctDispLA]~~
    
    'bytemove(@charbuff,string("    "),4)
    bytefill(@charbuff,$24,4)
    
    repeat
      repeat i from 0 to 38
        'serial.tx(serial.rx)
        'bytemove(@charbuff,string("    "),4)
        charbuff[0]:=i
        'bytemove(@charbuff,string("test"),4)
        doSCT
        waitcnt(clkfreq/5+cnt)
        if INA[sctEsc] == 0
            serial.str(string("Esc",13))
        if INA[sctUp] == 0
            serial.str(string("Up",13))
        if INA[sctDown] == 0
            serial.str(string("Down",13))
        if INA[sctEnter] == 0
            serial.str(string("Ent",13))

PUB doSCT|i,j,k        
    xlat
    dispBuff:=0    
    repeat j from 0 to 3
        repeat i from 0 to 7            
            k:=|<i
            if  (charGen[CharBuff[3-j]] & k)
                dispBuff|=|<displayPins[j*8+i]
                dispBuff|=|<displayPins[j*8+i]
                dispBuff|=|<displayPins[j*8+i]
                dispBuff|=|<displayPins[j*8+i]    
    setsct

PUB xlat | i
    repeat i from 0 to 3
        case CharBuff[i]
            $30..$39:
                CharBuff[i]:=CharBuff[i]-$30
            $41..$5A:
                CharBuff[i]:=CharBuff[i]-$37
            $61..$7A:
                CharBuff[i]:=CharBuff[i]-$57
            $20:
                CharBuff[i]:=CharBuff[i]+$4 '37 $25
            $2D:
                CharBuff[i]:=CharBuff[i]-$8 '38 $26
            $5F:
                CharBuff[i]:=CharBuff[i]-$39 '39 $27

PUB setSCT             
    repeat 32
      outa[sctDispCLK]~
      if dispBuff & |< 31
        outa[sctDispSDI]~~
      else
        outa[sctDispSDI]~                
      dispBuff <<= 1
      outa[sctDispCLK]~~
    outa[sctDispLA]~~
    outa[sctDispLA]~

DAT
    chargen byte
    '     0   1    2    3   4    5    6    7   8    9
    byte $3F, $6, $5B, $4F,$66, $6D, $7D, $7, $7F, $6F 
    '     A    B    C    D    E    F    G    H    I    J
    byte $77, $7C, $39, $5E, $79, $71, $3D, $74, $30, $1E
    '     K   L    M    N    O    P    Q    R    S    T
    byte $8, $38, $36, $54, $5C, $73, $67, $50, $6D, $31
    '      U   V    W   X    Y    Z
    byte $3E, $1C, $8, $76, $6E, $5B
    '   [sp] -   _
    byte $0, $40, $8


    displayPins
    displayPins0
    byte seg0a,seg0b,seg0c,seg0d,seg0e,seg0f,seg0g,seg0h
    displayPins1
    byte seg1a,seg1b,seg1c,seg1d,seg1e,seg1f,seg1g,seg1h
    displayPins2
    byte seg2a,seg2b,seg2c,seg2d,seg2e,seg2f,seg2g,seg2h
    displayPins3
    byte seg3a,seg3b,seg3c,seg3d,seg3e,seg3f,seg3g,seg3h
    
CON
    seg0a = 14
    seg0b = 15
    seg0c = 1
    seg0d = 3
    seg0e = 4
    seg0f = 13
    seg0g = 2
    seg0h = 0

    seg1a = 11
    seg1b = 12
    seg1c = 6
    seg1d = 7
    seg1e = 8
    seg1f = 9
    seg1g = 10
    seg1h = 5

    seg2a = 21
    seg2b = 22
    seg2c = 24
    seg2d = 26
    seg2e = 27
    seg2f = 20
    seg2g = 25
    seg2h = 23

    seg3a = 18
    seg3b = 19
    seg3c = 29
    seg3d = 30
    seg3e = 31
    seg3f = 16
    seg3g = 17
    seg3h = 28

