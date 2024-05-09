# Procedurally Generated Jigsaw Puzzle

### Made using the Godot game engine

![PCG Gif](/.git_resources/PuzzleGenerator_Gif.gif)

## Process
- Create a grid of vertices, connected together by edges
- Every piece is made up of 4 edges
- Used a random number generator to move vertices around just enough to make the shapes more interesting
- Every non-border edge generates a connector
- The full outline for each piece is compiled from the 4 edges
- The outline polygon is subdivided into triangles
- A compute shader generates a mask texture using those triangles
- The mask texture and piece position are used to render the pieces properly

## Triangulation

I used the ear clipping method for triangulating the concave outlines.
![Triangulation Image](/.git_resources/triangulated_piece.png)