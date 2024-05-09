#[compute]
#version 450

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(set = 0, binding = 0, rgba32f) uniform image2D OUTPUT_TEXTURE;
layout(set = 1, binding = 1, std430) buffer MySizeBuffer
{
  int data;
}
size;

layout(set = 2, binding = 2, std430) buffer MyTriangleBuffer
{
  vec2 data[];
}
points;

bool contains_point(vec2 p0, vec2 p1, vec2 p2, vec2 p)
{
  float area = 0.5*(-p1.y*p2.x + p0.y*(-p1.x+p2.x) + p0.x*(p1.y-p2.y) + p1.x*p2.y);

  float s = 1/(2*area) * (p0.y*p2.x - p0.x*p2.y + (p2.y-p0.y)*p.x + (p0.x-p2.x)*p.y);
  float t = 1/(2*area) * (p0.x*p1.y - p0.y*p1.x + (p0.y-p1.y)*p.x + (p1.x-p0.x)*p.y);

  return s>0 && t>0 && s+t<1;
}

void main()
{
  bool contained = false;
  for (int i = 0; i < size.data; i++)
  {
    contained = contained || contains_point(points.data[3*i+0], points.data[3*i+1], points.data[3*i+2], gl_GlobalInvocationID.xy);
  }

  vec4 color = vec4(0.0f,0.0f,1.0f,1.0f);

  if (contained)
  {
    color = vec4(1.0f,0.0f,0.0f,1.0f);
  }
  else
  {
    color = vec4(0.0f,1.0f,0.0f,1.0f);
  }
  ivec2 texel = ivec2(gl_GlobalInvocationID.xy);
  imageStore(OUTPUT_TEXTURE, texel, color);
}

