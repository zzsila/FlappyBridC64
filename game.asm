Game                            jsr             FlapThatBird                    ;Make a flap
                                lda             PipePosition                    ;Did the bird reach a new pipe
                                bne             GameNoNewPoint                  ;No, no new pint :-(
                                sed
                                lda             PointsLo                        ;Yes, give it to me!!!
                                clc
                                adc             #1                              
                                sta             PointsLo                        
                                lda             PointsHi                        
                                adc             #0                              
                                sta             PointsHi                        
                                cld
                                lda             #PipeDifference                 ;Counter set to the new pipe's distance
                                sta             PipePosition                    
                                jsr             ScoreSound1                     ;Play score sound
GameNoNewPoint                  lda             GameModeCounterLo               ;The bird only moves in every second frame
                                lsr
                                cmp             LastGameModeCounter             
                                beq             GameNoFlappyMove                
                                sta             LastGameModeCounter             
                                jsr             MoveFlappyBird                  ;Move the bird
GameNoFlappyMove                lda             GameModeFinishLimit             ;Are we in a finish state? (= flappy died)
                                beq             GameNoFinishState               ;No, jump
                                lda             GameModefinishCounter           ;Create a flash on the background
                                pha
                                lsr
                                tax
                                lda             FadeWhiteToLightBlue,x          
                                sta             IRQBackgroundColor              
                                pla
                                cmp             GameModeFinishLimit             ;Finish state is about to end?
                                bne             GameNoNextGameMode              ;No, jump
                                jsr             NextGameMode                    ;Next game mode, jump to the end
GameNoNextGameMode              jmp             GameNoDeath
GameNoFinishState               lda             SpriteDataCollision             ;Is flappy touched a pipe?
                                and             #01                             
                                beq             GameNoDeath                     ;No, jump
                                sta             IsFlappyDead                    ;Yes, this is the beginning of the end        
                                lda             #16         
                                jsr             PrepareToFinishGameMode         ;16 frames to game over mode
                                jsr             HitSound                        ;Play hit sound
GameNoDeath                     rts

