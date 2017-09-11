
'' =================================================================================================
''
''   File....... jm_dmxin.spin
''   Purpose.... 
''   Author..... Jon "JonnyMac" McPhalen (aka Jon Williams)
''               Copyright (c) 2009-10 Jon McPhalen
''               -- see below for terms of use
''   E-mail..... teamefx@efx-tek.com
''   Started.... 05 JUL 2009
''   Updated.... 21 JUL 2010   
''
'' =================================================================================================

{{

               +5v           +5v
                              
                │             │
            10k              │                   
            2k2 │ ┌─────────┐ │                   
   dmxrx ────┻─┤1°      8├─┘                   
    txrx ──────┳─┤2       7├────────┳──────┳─────── Pin 2 XLR-F 
                ┣─┤3       6├────────┼─┳────┼─┳───── Pin 3 XLR-F    DMX OUT
   dmxtx ──────┼─┤4       5├─┐      │ │    │ │ ┌─── Pin 1 XLR-F 
                │ └─────────┘ │      │ └ ┐  │ │ │               
            10k    ST485BN   │  120  ┌ ┘  └─┼─┼─── Pin 2 XLR-M
                │             │      │ │      └─┼─── Pin 3 XLR-M    DMX IN
                                   └─┘        ┣─── Pin 1 XLR-M
                                                └ ┐
                                                ┌ ┘
                                                

   ST485BN (Mouser 511-ST485BN) pins

   1  RO   Receive output
   2  /RE  Receive enable  (active low)
   3  DE   Transmit enable (active high)
   4  DI   Transmit input
   5  Vss  ground
   6  A    differential IO
   7  B    differential IO
   8  Vdd  +5v


   Resources

   * http://www.erwinrol.com/index.php?stagecraft/dmx.php
   * http://www.dmx512-online.com/packt.html
   * http://en.wikipedia.org/wiki/DMX512-A
                   
}}


con

  LOS = 100                                                     ' no LED if loss-of-signal > 100ms
  

var

  long  cog

  byte  dmxbuf[513]                                             ' DMX input buffer
 

pub init(rx, led, start, level) : okay

'' Extended Initialization of DMX receiver cog
'' -- rx...... receive pin#
'' -- led..... pin# to indicate dmx activity
'' -- start... initial start byte value for stream
'' -- level... initial value from all frames in buffer

  finalize

  LOS_TIX := (clkfreq / 1_000) * LOS                           ' loss-of-signal timing 

  US_001   := clkfreq / 1_000_000                               ' ticks per 1us
  US_004   := US_001 * 4                                        ' bit timing
  US_006   := US_001 * 6                                        ' 1.5 bits
  BREAK    := US_001 * 88                                       ' rx break timing
  PACKET   := 513                                               ' start + values

  buf0     := @dmxbuf                                           ' pointer to dmxbuf[0]
  rxpin    := rx                                                ' rx pin # (for ctra)
  rxmask   := |< rx                                             ' rx pin mask
  ledmask  := |< led                                            ' led pin mask

  dira[rx]~                                                     ' clear pins in this cog
  dira[led]~
  fillbuf(start, level)                                         ' initialize buffer

  okay := cog := cognew(@dmxin, 0) + 1                          ' start the DMX cog


pub finalize

'' Stops DMX RX driver; frees a cog 

  if cog
    cogstop(cog~ - 1)


pub read(ch)

'' Reads value of channel ch (0 to 512)
'' -- returns 0 if ch# invalid
'' -- ch0 is DMX start byte
'' -- ch1 to chN are channel values

  if (ch => 0) & (ch =< 512)
    return dmxbuf[ch] 
  else
    return 0


pub write(ch, level)

'' Write value to channel
'' -- for manual manipulation of buffer when no DMX signal present

  if (ch => 0) & (ch =< 512)
    dmxbuf[ch] := 0 #> level <= 255 


pub flushbuf

'' Flushes DMX buffer to zeroes

  fillbuf(0, 0)


pub fillbuf(start, level)

'' Fills DMX buffer with start byte and level (all frames)

  dmxbuf[0] := 0 #> start <# 255

  level := 0 #> level <# 255     
  bytefill(@dmxbuf[1], level, 512)


pub address

'' Returns hub address of dmx buffer

  return @dmxbuf 

     
dat

                        org     0

dmxin                   andn    outa, ledmask                   ' led off
                        mov     dira, ledmask                   ' led output, rx input

                        mov     ctra, NEG_DETECT                ' count while rx is 0
                        add     ctra, rxpin                     ' use on rx
                        mov     frqa, #1

                        mov     ctrb, FREE_RUN                  ' set ctrb for LOS timing
                        mov     frqb, #1 
                        mov     phsb, #0

waitbreak1              call    #checkidle                      ' check idle timer
                        test    rxmask, ina             wc
        if_nc           jmp     #waitbreak1                     ' wait for high (idle)

                        mov     phsa, #0                        ' restart break timer

waitbreak0              call    #checkidle
                        test    rxmask, ina             wc
        if_c            jmp     #waitbreak0                     ' wait for low (BREAK)
                        
shortpacket             call    #checkidle 
                        test    rxmask, ina             wc      ' wait for high (MAB)
        if_nc           jmp     #shortpacket 
                        cmp     BREAK, phsa             wc, wz  ' valid break timing?
        if_a            jmp     #waitbreak1
                
getpacket               mov     bufpntr, buf0                   ' bufpntr := @dmxbuf[0]
                        mov     count, PACKET                   ' bytes to rx (start + values)

rxbyte                  mov     phsa, #0                        ' reset break timer
                        mov     rxwork, #0                      ' clear work var
                        mov     rxcount, #8                     ' rx eight bits
                        mov     rxtimer, US_006                 ' set timer to 1.5 bits

waitstart               call    #checkidle
                        test    rxmask, ina             wc
        if_c            jmp     #waitstart                      ' wait for low (BREAK)
                       
                        add     rxtimer, cnt                    ' sync with system counter
                        or      outa, ledmask                   ' activity led on
                        mov     phsb, #0                        ' restart LOS timer 

rxbit                   waitcnt rxtimer, US_004                 ' hold for middle of next bit
                        test    rxmask, ina             wc      ' rx --> C
        if_c            mov     phsa, #0                        ' if rx == 1, restart break timer
                        shr     rxwork, #1                      ' prep rxwork for new bit
                        muxc    rxwork, #%1000_0000             ' C --> rxwork.7
                        djnz    rxcount, #rxbit                 ' update bit count
                        
breakcheck              waitcnt rxtimer, #0                     ' hold to sample 1st stop bit
                        test    rxmask, ina             wz      ' validate stop, Z means break
        if_z            jmp     #shortpacket                    ' new break detected?

                        wrbyte  rxwork, bufpntr                 ' rxwork --> buffer
                        add     bufpntr, #1                     ' update buf pointer
                        djnz    count, #rxbyte                  ' update packet count

                        jmp     #waitbreak1                     ' start again


' Check loss-of-signal timer
' -- if time-out, LED extinguished and C flag set

checkidle               cmp     LOS_TIX, phsb           wc, wz  ' check LOS timer
        if_b            andn    outa, ledmask                   ' led off if time-out   
checkidle_ret           ret                                            

' --------------------------------------------------------------------------------------------------

NEG_DETECT              long    %01100 << 26                    ' ctr neg detector
FREE_RUN                long    %11111 << 26                    ' just runs  

LOS_TIX                 long    0-0                             ' ticks in loss-of-signal duration

US_001                  long    0-0                             ' ticks per us
US_004                  long    0-0                             ' bit timing for 250K (4us)
US_006                  long    0-0                             ' 1.5 bits 
BREAK                   long    0-0                             ' min break timing for test
PACKET                  long    0-0                             ' length of DMX standard packet

buf0                    long    0-0                             ' pointer to dmx buffer[0]
rxpin                   long    0-0                             ' rx pin
rxmask                  long    0-0                             ' mask for rx pin
ledmask                 long    0-0                             ' mask for led pin

rxwork                  res     1                               ' workspace for receive
rxcount                 res     1                               ' bits to receive
rxtimer                 res     1                               ' rx bit timer

bufpntr                 res     1                               ' pointer to current byte
count                   res     1                               ' bytes to rx

tmp1                    res     1

                        fit     492
                                               

dat

{{

  Terms of Use: MIT License

  Permission is hereby granted, free of charge, to any person obtaining a copy of this
  software and associated documentation files (the "Software"), to deal in the Software
  without restriction, including without limitation the rights to use, copy, modify,
  merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to the following
  conditions:

  The above copyright notice and this permission notice shall be included in all copies
  or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
  PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
  OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 

}}

  