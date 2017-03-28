.global pause_menu

.section .text
pause_menu:
	push {r5, r8, lr}
	PREV_BUTTONS .req r8
	bl draw_pause_menu
	mov r5, #0			//r5 will hold the selection the user has made
						// 0 == resume, 1 == restart, 2 == exit
	ldr PREV_BUTTONS, =0xFFFF	//initially no buttons are pressed
menu_select_loop:
	mov r0, r5
	bl draw_menu_selector

	bl ReadSNES				//return in r0 the buttons that are pressed
	cmp r0, PREV_BUTTONS	//if same buttons are held then don't update
	beq menu_select_loop	//position of the selector
	mov PREV_BUTTONS, r0	//else update previous buttons
	
	tst r0, #0x10			//0001 0000b D-PAD UP pressed?
	subeq r5, #1			//move selector up
	
	tst r0, #0x20			//0010 000b D-PAD DOWN pressed?
	addeq r5, #1			//move selector down
	
	//clamp the value in r5 so that 0 <= r5 <= 2
	cmp r5, #0
	movlt r5, #0			//clamp to 0
	cmp r5, #2
	movhi r5, #2			//clamp to 2
	
	tst r0, #0x100			//check if A was pressed
	beq check_resume		//start checking which option the user selected
	b menu_select_loop		//else loop again
	
check_resume:
	cmp r5, #0			//if current selection is resume
	bne check_restart
	bl drawBackground		//redraw the background
	b exit_pause_menu		//exit the game
	
check_restart:
	cmp r5, #1				//if current selection is restart
	bne check_exit			//if not then skip
	bl restart_game			//else restart game in restart.s
	bl drawBackground
	b exit_pause_menu		//return to game with reset values
	
check_exit:
	cmp r5, #2				//if current selection is exit
	bne menu_select_loop	//branch if not exit
	bl restart_game			//else restart the game
	b start_screen			//then go to start screen
	
	
exit_pause_menu:
	.unreq PREV_BUTTONS
	pop {r5, r8, pc}		//return back to the game
	
	
draw_pause_menu:
	push {lr}
	
	// draw pause menu in middle of screen
	ldr r0, =311		//x location
	ldr r1, =183		//y location
	ldr r2, =pause_menu_pic	//data structure for menu pic
	bl drawPicture
	
	pop {pc}
	
//==================
//Paramters:
//		r0 - the selection on the pause menu the user has made
//			0 == resumre, 1 == restart, 2 == exit			
//==================
draw_menu_selector:
	push {r4, lr}
	ldr r2, =pause_menu_selector_pic		//the data structure for the menu slecector pic
	
	cmp r0, #0
	beq draw_on_resume
	
	cmp r0, #1
	beq draw_on_restart
	
	cmp r0, #2
	beq draw_on_exit
	b end_draw_menu_selector
	
draw_on_resume:
	ldr r3, =resume_option
	ldr r0, [r3]			//x coor
	ldr r1, [r3, #4]		//y coor
	bl drawPicture
	
	//Draw background color over other 2 selectors
	ldr r4, =restart_option
	bl cover_selector
	ldr r4, =exit_option 
	bl cover_selector
	
	b end_draw_menu_selector
	
	
draw_on_restart:
	ldr r3, =restart_option
	ldr r0, [r3]			//x coor
	ldr r1, [r3, #4]		//y coor
	bl drawPicture
	
	//Draw background color over other 2 selectors
	ldr r4, =resume_option
	bl cover_selector
	ldr r4, =exit_option 
	bl cover_selector
	
	b end_draw_menu_selector
	
draw_on_exit:
	ldr r3, =exit_option
	ldr r0, [r3]			//x coor
	ldr r1, [r3, #4]		//y coor
	bl drawPicture
	
	//Draw background color over other 2 selectors
	ldr r4, =resume_option
	bl cover_selector
	ldr r4, =restart_option 
	bl cover_selector
	
end_draw_menu_selector:
	pop {r4, pc}
	
	
//====================
//Paramters:
//	r4 - the selector to cover with the background color
//=====================
cover_selector:
	push {lr}
	
	//Draw background over the selector in r4
	ldr r0, [r4]					//x pos
	ldr r1, [r4, #4]				//y pos
	ldr r2, =bg_color
	ldrh r2, [r2]					//background colour
	ldr r3, =27						//width
	ldr r4, =26						//height
	bl drawRectangle
	
	pop {pc}
	
//===========================================
//Draws the background before resuming the game
//==========================================
drawBackground:
	push {lr}
	mov r0, #0						//x pos
	mov r1, #0						//y pos
	ldr r2, =background_1			//data structure for background
	bl drawPicture
	
	//redraw the score too
	ldr r0, =score_changed			//changed score changed to true
	mov r1, #1
	str r1, [r0]
	pop {pc}
	
.section .data
resume_option:	.int 385, 268			//x and y of where to draw menu selector
restart_option:	.int 385, 373
exit_option:	.int 385, 485
bg_color:		.ascii "\4\323"
	
	
	
	
