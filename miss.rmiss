#version 460
#extension GL_EXT_ray_tracing : require

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

void main()
{
	// View-independent background gradient to simulate a basic sky background
	// const vec3 gradientStart = vec3(0.5, 0.6, 1.0);
	const vec3 gradientStart = vec3(1.0, 0.5, 0.0);
	const vec3 gradientEnd = vec3(0, 0.5, 1.0);
	vec3 unitDir = normalize(gl_WorldRayDirectionEXT);
	float t = 0.5 * (unitDir.y + 1.0);
	rayPayload.color = vec3(0);//(1.0-t) * gradientStart + t * gradientEnd;
	rayPayload.pure_color = rayPayload.color;
	rayPayload.distance = -1;
	rayPayload.normal = vec3(0.0f);
	rayPayload.reflector = 0.0f;
	rayPayload.opacity = 1.0;
	rayPayload.wro = vec3(0.0);
	rayPayload.wrd = vec3(0.0);
	rayPayload.hitt = 0.0;
}