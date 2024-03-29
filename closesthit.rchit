#version 460
#extension GL_EXT_ray_tracing : require
#extension GL_EXT_nonuniform_qualifier : enable


struct RayPayload {
	vec3 color;
	vec3 pure_color;
	float distance;
	vec3 normal;
	float reflector;
	float opacity;
	vec3 pos;
	vec3 wro;
	vec3 wrd;
	float hitt;
	int recursive;
};

layout(location = 0) rayPayloadInEXT RayPayload rayPayload;
layout(location = 2) rayPayloadEXT bool shadowed;

layout(binding = 0, set = 1) uniform sampler2D baseColorSampler;
layout(binding = 1, set = 1) uniform sampler2D normalSampler;

hitAttributeEXT vec2 attribs;




const int max_lights = 2;

layout(binding = 0, set = 0) uniform accelerationStructureEXT topLevelAS;
layout(binding = 2, set = 0) uniform UBO 
{
	mat4 viewInverse;
	mat4 projInverse;

	mat4 transformation_matrix;

	vec4 light_positions[max_lights];
	vec4 light_colors[max_lights];

	vec3 camera_pos;
	int vertexSize;
} ubo;
layout(binding = 3, set = 0) buffer Vertices { vec4 v[]; } vertices;
layout(binding = 4, set = 0) buffer Indices { uint i[]; } indices;



struct Vertex
{
  vec3 pos;
  vec3 normal;
  vec2 uv;
  vec4 color;
  vec4 _pad0; 
  vec4 _pad1;
};

Vertex unpack(uint index)
{
	// Unpack the vertices from the SSBO using the glTF vertex structure
	// The multiplier is the size of the vertex divided by four float components (=16 bytes)
	const int m = ubo.vertexSize / 16;

	vec4 d0 = vertices.v[m * index + 0];
	vec4 d1 = vertices.v[m * index + 1];
	vec4 d2 = vertices.v[m * index + 2];

	Vertex v;
	v.pos = d0.xyz;
	v.normal = vec3(d0.w, d1.x, d1.y);
	v.uv = vec2(d1.z, d1.w);
	v.color = vec4(d2.x, d2.y, d2.z, 1.0);

	return v;
}






void main()
{
	ivec3 index = ivec3(indices.i[3 * gl_PrimitiveID], indices.i[3 * gl_PrimitiveID + 1], indices.i[3 * gl_PrimitiveID + 2]);

	Vertex v0 = unpack(index.x);
	Vertex v1 = unpack(index.y);
	Vertex v2 = unpack(index.z);

	// Interpolate
	const vec3 barycentricCoords = vec3(1.0f - attribs.x - attribs.y, attribs.x, attribs.y);
	vec3 normal = normalize(v0.normal * barycentricCoords.x + v1.normal * barycentricCoords.y + v2.normal * barycentricCoords.z);
	const vec3 pos = v0.pos * barycentricCoords.x + v1.pos * barycentricCoords.y + v2.pos * barycentricCoords.z;
	const vec2 uv = v0.uv * barycentricCoords.x + v1.uv * barycentricCoords.y + v2.uv * barycentricCoords.z;

	vec4 n = normalize(ubo.transformation_matrix*vec4(normal, 0.0));
	
	rayPayload.reflector = texture(normalSampler, uv).a;
	rayPayload.opacity = texture(baseColorSampler, uv).a;

	// Make the transparent sphere partially reflective
	if(rayPayload.opacity == 0.0)
		rayPayload.reflector = 0.5;

	vec3 color = texture(baseColorSampler, uv).rgb;
	
	rayPayload.pure_color = color;
		
	rayPayload.distance = gl_RayTmaxEXT;
	rayPayload.normal = n.xyz;
	
	rayPayload.wro = gl_WorldRayOriginEXT;
	rayPayload.wrd = gl_WorldRayDirectionEXT;
	rayPayload.hitt = gl_HitTEXT;

	rayPayload.color = color;
}
