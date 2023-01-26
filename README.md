<h1 align='center'>🏀 Basketball Assembly project 💾</h1>
Basketball game using TASM for x86 architecture.

> This is a personal game assignment for my university. it uses Borland's Turbo Assembler, this can be executed using DOSBox intel 8086 emulator.
> The executable is already uploaded.
> You may encounter certain bugs like cursor erasing part of the map, this was done in a week so I didn't have time to polish or add a scoring system.
> The comments are in spanish but I will consider translating it to english in my free time. 

if you want to compile and link it yourself you need to install TASM properly and execute the next commands.
```
TASM MAIN
TASM LIB
TASM BRAIN
TLINK MAIN LIB BRAIN
```
<h2>Features ⭐</h2>

<ul>
<li>Random level generator</li>
There is an internal logic for generating random levels on a desired difficulty (currently two supported). This will change ball size, floor height, hoop distante, hoop's frame height and width.
<li>Hoop collision</li>
Ball will collide with the hoop from every direction; uses basic linear interpolation.
<li>Reset</li>
The game will automatically reset after a miss, returning to the default DOS text mode.
<li>Trail modes</li>
On MAIN.ASM line 18, you can switch the display trail mode if you change GAME_MODE data byte value on the data segment. Support up to three modes in hexadecimal... 00H: Default (no trail), 01H: Debug (draws the trajectory), 02H: Trail (shows the previous position in light blue).
  </ul>
  
 <h2>Gameplay ⭐</h2>
 
 Use `W` `A` `S` `D` to move your cursor which indicates the direction and power relative to the ball current position. Use `Space` to confirm and launch the ball. 
<div align='center'>
 <img src="https://user-images.githubusercontent.com/97124374/214930760-dafb5904-ce15-40a6-9bb7-6cf10c8dd0cf.gif" width="440">
  <img src="https://user-images.githubusercontent.com/97124374/214932578-4c5e296f-3d66-42fc-bb71-f05f534f47f1.gif" width="440">
</div>
