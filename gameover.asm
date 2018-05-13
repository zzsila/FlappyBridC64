GameOver                        lda             GameModeCounterLo               ;Last game mode counter used to skip                                                                                 
                                lsr                                             ;every second frame
                                cmp             LastGameModeCounter             ;Is it the second?
                                beq             GameOverNoFlappyMove            ;Yes, jump
                                sta             LastGameModeCounter             
                                jsr             MoveFlappyBirdGameOver          ;Bring that bird to the floor!
GameOverNoFlappyMove            lda             GameModeCounterHi               ;Create a fade for 'Game Over' title's colors
                                bne             GameOverNoFade                  
                                lda             GameModeCounterLo               
                                cmp             #16                             
                                bcs             GameOverNoFade                  
                                lsr
                                tax
                                lda             FadeLightBlueToGray,x           
                                sta             IRQTitleSpriteColor             
                                lda             FadeLightBlueToOrange,x         
                                sta             IRQTitleSpriteMCol0             
                                lda             FadeLightBlueToYellow,x         
                                sta             IRQTitleSpriteMCol1             
                                jmp             GameOverNoFireCheck             ;In fade mode, no jump to nect game mode
                                
GameOverNoFade                  lda             GameOverIsTableDrawn            ;Is the game over table already drawn?
                                bne             GameOverTableDrawn              ;Yes, jump
                                lda             #$d9                            ;White foreground colors for points
                                sta             ZPIndex2Hi                      
                                ldx             #0                              
                                stx             ZPIndex2Lo                      
                                lda             #9                              
GameOverNextWhiteChar           ldy             GameOverTableWhiteChars,x
                                sta             (ZPIndex2Lo),y                  
                                inx
                                cpx             #16                             
                                bne             GameOverNextWhiteChar           
                                lda             ZPScreenHi                      ;Draw the game over table                                                                                 
                                and             #%11111100                      ;to the center of the screen (almost)
                                sta             ZPIndex0Hi                      
                                lda             #252                            
                                sta             ZPIndex0Lo                      
                                ldx             #0                              
GameOverTableRow                ldy             #0
GameOverTableColumn             lda             GameOverTable,x
                                sta             (ZPIndex0Lo),y                  
                                inx
                                iny
                                cpy             #16                             
                                bne             GameOverTableColumn             
                                lda             #40                             
                                clc
                                adc             ZPIndex0Lo                      
                                sta             ZPIndex0Lo                      
                                bcc             NoCarryOnTableDraw              
                                inc             ZPIndex0Hi                      
NoCarryOnTableDraw              cpx             #128
                                bne             GameOverTableRow   
             
                                lda             PointsHi                        ;Set medal for points
                                bne             GOPlatinumMedal                 ;0-9: None
                                lda             PointsLo                        ;10-19 Bronze
                                cmp             #$10                            ;20-29 Silver
                                bcs             GOBronzeMedal                   ;30-39 Gold
                                lda             #0                              ;40- Platinum
                                beq             GOSetMedal                      
GOBronzeMedal                   cmp             #$20
                                bcs             GOSilverMedal                   
                                lda             #3                              
                                bne             GOSetmedal                      
GOSilverMedal                   cmp             #$30
                                bcs             GOGoldMedal                     
                                lda             #6                              
                                bne             GOSetMedal                      
GOGoldMedal                     cmp             #$40
                                bcs             GOPlatinumMedal                 
                                lda             #9                              
                                bne             GOSetMedal                      
GOPlatinumMedal                 lda             #12
GOSetMedal                      sta             IRQMedalPointer
                                lda             #1                              
                                sta             GameOverIsTableDrawn            
                                jmp             GameOverNoFireCheck             ;No fire check on table draw frame
                                
GameOverTableDrawn              lda             GameOverPointsHi                ;Write current points...
                                ldy             GameOverPointsLo                
                                ldx             #86                             
                                jsr             GameOverWriteNumber             
                                lda             BestPointsHi                    ;...and current best points...
                                ldy             BestPointsLo                    
                                ldx             #206                            
                                jsr             GameOverWriteNumber             ;...to the screen
                                lda             GameModeCounterLo 
                                lsr
                                cmp             LastGameOverModeCounter         ;One point increment / frame
                                bne             GameOverHandlePoints            
                                lda             PointsLo                        ;If there are still points to count...
                                cmp             GameOverPointsLo                
                                bne             GameOverNoFireCheck             ;...then no fire check
                                lda             PointsHi                        
                                cmp             GameOverPointshi                
                                bne             GameOverNoFireCheck             
                                jmp             GameOverFireCheck               ;Otherwise check if fire pressed
                                
GameOverHandlePoints            sta             LastGameOverModeCounter         
                                lda             GameOverPointsHi                ;If points > counter (GameOverPoints)...
                                cmp             PointsHi                        
                                bcc             GameOverIncrementGOP            ;...then increment it
                                lda             GameOverPointsLo                
                                cmp             PointsLo                        
                                bcs             GameOverFireCheck               ;Otherwise we can check if fire pressed
GameOverIncrementGOP            sed
                                lda             GameOverPointsLo                
                                clc
                                adc             #01                             
                                sta             GameOverPointsLo                
                                bcc             GameOverNoCarryOnPoints          
                                lda             GameOverPointsHi                
                                adc             #0                              
                                sta             GameOverPointsHi                
GameOverNoCarryOnPoints         cld
                                jsr             PointSound                      ;Play point sound
                                lda             GameOverPointsHi                ;Check if counter is greater than the current
                                cmp             BestPointsHi                    ;Best score
                                bcc             GameOverNoFireCheck             
                                bne             GameOverIncrementBest           
                                lda             BestPointsLo                    
                                cmp             GameOverPointsLo                
                                bcs             GameOverNoFireCheck             
GameOverIncrementBest           lda             GameOverPointsLo                ;If so, Best score = counter
                                sta             BestPointsLo                    
                                lda             GameOverPointsHi                
                                sta             BestPointsHi                    
                                lda             #01                             ;Set new record falg to true
                                sta             IRQIsNewRecord
                                bne             GameOverNoFireCheck             ;No fire check at the end
GameOverFireCheck
                                jsr             CheckJoyFire                    ;Is fire pressed?
                                bcc             GameOverNoFireCheck             ;No, jump
                                jmp             NextGameMode                    ;Yes, go to next game mode
GameOverNoFireCheck             rts

GameOverWriteNumber             pha                                             ;Write 4 digits
                                lda             ZPScreenHi                      ;Set address 
                                and             #%11111100                      ;Index0 upper half character
                                sta             ZPIndex0Hi                      ;Index1 lower half character (below with one row)
                                sta             ZPIndex1Hi                      
                                inc             ZPIndex0Hi                      
                                inc             ZPIndex1Hi                      
                                stx             ZPIndex0Lo                      
                                txa
                                clc
                                adc             #40                             
                                sta             ZPIndex1Lo                      
                                ldx             #0                              
                                sty             TempPoints                      ;Store lower 2 digits to temp variable
                                ldy             #0                              
                                pla
                                cmp             #0                              
                                beq             GOWriteNum2Digits               ;If upper two digits are zero, we skip them
                                inx
                                cmp             #$10                            ;If the upper digit is yero, we skip it
                                bcc             GOWriteNum3Digits               
                                pha
                                lsr                                             ;Get the upper digit
                                lsr
                                lsr
                                lsr
                                asl
                                clc
                                adc             #56                             ;Get the screen codes for a digit
                                sta             (ZPIndex0Lo),y                  ;And store the upper...
                                clc
                                adc             #1                              ;...and the lower half
                                sta             (ZPIndex1Lo),y                  
                                pla
GOWriteNum3Digits               iny                                             ;Get the lower digit
                                and             #$0f                            
                                asl
                                clc
                                adc             #56                             
                                sta             (ZPIndex0Lo),y                  ;and sotre it the same way
                                clc
                                adc             #1                              
                                sta             (ZPIndex1Lo),y                  
GOWriteNum2Digits               ldy             #2
                                lda             TempPoints                      ;Get the lower 2 digits
                                cpx             #1                              
                                beq             GOWriteNum2DigitsSure           
                                cmp             #$10                            ;If the lower half is less than 10...
                                bcc             GOWriteNum1Digits               ;And the upper byte is zero, then there is only
                                                                                ;1 digit to draw
GOWriteNum2DigitsSure           pha                                             ;Upper half of lower byte...
                                lsr
                                lsr
                                lsr
                                lsr
                                asl
                                clc
                                adc             #56                             
                                sta             (ZPIndex0Lo),y                  
                                clc
                                adc             #1                              
                                sta             (ZPIndex1Lo),y                  
                                pla                                             ;...and the lower one
GOWriteNum1Digits               iny
                                and             #$0f                            
                                asl
                                clc
                                adc             #56                             
                                sta             (ZPIndex0Lo),y                  
                                clc
                                adc             #1                              
                                sta             (ZPIndex1Lo),y                  
                                rts
