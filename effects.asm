;===============================================================================
;Flap sound
;===============================================================================
FlapSound                       jsr             ResetFilters                    ;Reset filters for channel 1            
                                lda             #$76                            ;Set ADSR    
                                sta             SIDChannel1AD
                                lda             #$00
                                sta             SIDChannel1SR                   
                                lda             #42                             ;Frequency: E-5
                                sta             SIDChannel1FrequencyHi
                                lda             #62                            
                                sta             SIDChannel1FrequencyLo          
                                lda             #$80
                                sta             SIDChannel1Control              ;Waveform: Noise
                                lda             #$81
                                sta             SIDChannel1Control              
                                rts
                                
;===============================================================================
;Point sound
;===============================================================================
PointSound                      jsr             ResetFilters                    ;Reset filters for channel 1
                                lda             #$30                            ;Set ADSR    
                                sta             SIDChannel1AD
                                lda             #$00
                                sta             SIDChannel1SR                   
                                lda             #$86                            ;Frequency: C-7
                                sta             SIDChannel1FrequencyHi
                                lda             #$1e                            
                                sta             SIDChannel1FrequencyLo          
                                lda             #$20                            ;Waveform: Saw
                                sta             SIDChannel1Control
                                lda             #$21
                                sta             SIDChannel1Control              
                                rts

;===============================================================================
;Hit sound
;===============================================================================
HitSound                        jsr             ResetFilters                    ;Reset filters for channel 1
                                lda             #$08                            ;Set ADSR     
                                sta             SIDChannel1AD
                                lda             #$00
                                sta             SIDChannel1SR                   
                                lda             #$15                            ;Frequency: E-4
                                sta             SIDChannel1FrequencyHi          
                                lda             #$1f                            
                                sta             SIDChannel1FrequencyLo          
                                lda             #$80                            ;Waveform: Noise
                                sta             SIDChannel1Control
                                lda             #$81
                                sta             SIDChannel1Control              
                                rts
                                
;===============================================================================
;Score sound
;===============================================================================
ScoreSound1                     lda             #$17                            ;Set ADSR   
                                sta             SIDChannel2AD
                                lda             #$00
                                sta             SIDChannel2SR                   
                                lda             #$32                            ;Frequency: G-5
                                sta             SIDChannel2FrequencyHi
                                lda             #$4c                            
                                sta             SIDChannel2FrequencyLo          
                                lda             #$10                            ;Waveform: Triangle
                                sta             SIDChannel2Control
                                lda             #$11
                                sta             SIDChannel2Control              
                                lda             #$08                            
                                sta             IRQScoreSoundDelay              ;Set delay (after that delay, ScoreSound2 will be played)
                                rts

;===============================================================================
;Score sound IRQ part
;===============================================================================                                
ScoreSound2                     ldx             IRQScoreSoundDelay              ;Check delay
                                bne             ScoreSound21                    ;If zero, no effect
                                rts                                             
ScoreSound21                    dex                                             ;Decrement delay
                                bne             ScoreSound22                    ;If not zero, no effect            
                                lda             #$17                            ;Otherwise    
                                sta             SIDChannel2AD                   ;Set ADSR
                                lda             #$00                    
                                sta             SIDChannel2SR                   
                                lda             #$3f                            ;Frequency: H-5                 
                                sta             SIDChannel2FrequencyHi
                                lda             #$4b                            
                                sta             SIDChannel2FrequencyLo          
                                lda             #$10                            ;Waveform: Triangle
                                sta             SIDChannel2Control
                                lda             #$11
                                sta             SIDChannel2Control              
ScoreSound22                    stx             IRQScoreSoundDelay              ;Clear delay                  
                                rts
                                
;===============================================================================
;Fade sound
;In:  AC frame number to start
;===============================================================================
FadeSound                       cmp             GameModeCounterLo               ;Is it the right frame?
                                beq             FadeSoundLoOk                   ;Yes (maybe)
                                rts
FadeSoundLoOk                   lda             GameModeCounterHi               ;Counter upper byte should be zero
                                beq             FadeSoundDirect                   
                                rts                                             ;otherwise, exit
FadeSoundDirect                 lda             #$88                            ;Set ADSR   
                                sta             SIDChannel1AD
                                lda             #$00
                                sta             SIDChannel1SR                   
                                lda             #$fd                            ;Frequency: H-7
                                sta             SIDChannel1FrequencyHi
                                lda             #$2e                            
                                sta             SIDChannel1FrequencyLo          
                                lda             #$20                            ;Set fade counter
                                sta             IRQFadeSoundCounter
                                lda             #$00
                                sta             SIDFilterCutHi                  ;Set cuting frequency for filter
                                lda             #$f1
                                sta             SIDFilterControl                                
                                lda             #$80                            ;Waveform: Noise
                                sta             SIDChannel1Control              
                                lda             #$81
                                sta             SIDChannel1Control              
                                rts

;===============================================================================
;Fade sound IRQ part
;===============================================================================                                
FadeSound2                      ldx             IRQFadeSoundCounter             ;If fade counter is 0...
                                bne             FadeSound21                     ;...nothing to do.
                                rts
                                
FadeSound21                     dex                                             ;Decrement fade counter
                                stx             IRQFadeSoundCounter             ;and store
                                beq             FadeSound22                     ;if zero, reset filters
                                txa
                                eor             #%00011111                      ;Otherwise, calculate new filter
                                sta             SIDFilterCutHi                  ;cutting frequency 
                                rts
FadeSound22                     jmp             ResetFilters           
                                
                                
;===============================================================================
;Reset filters
;===============================================================================                                                                
ResetFilters                    lda             #$00                            ;Clear
                                sta             IRQFadeSoundCounter             ; - Filter counter
                                sta             SIDFilterCutHi                  ; - SID Filter cut frequency
                                sta             SIDFilterControl                ; - SID Filter control
                                rts
                                