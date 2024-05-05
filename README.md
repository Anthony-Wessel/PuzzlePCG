# Procedurally Generated Jigsaw Puzzle

### Made using the Godot game engine

![PCG Gif](/.git_resources/PuzzleGenerator_Gif.gif)

## Process
- Create a grid of vertices, connected together by edges
- Every piece is made up of 4 edges
- Used a random number generator to move vertices around just enough to make the shapes more interesting
- Every non-border edge generates a connector
- Full pieces are drawn by drawing the 4 edges that make them up

When I have time I plan to create a compute shader that builds mask textures for each piece, allowing for a full image to be split properly among all the pieces
