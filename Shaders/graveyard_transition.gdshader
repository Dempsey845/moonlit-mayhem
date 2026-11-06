shader_type canvas_item;
render_mode unshaded;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float edge_softness : hint_range(0.001, 0.1) = 0.015;

float box_distance(vec2 point, vec2 half_size) {
	vec2 edge = abs(point) - half_size;
	return length(max(edge, vec2(0.0))) + min(max(edge.x, edge.y), 0.0);
}

void fragment() {
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 point = (UV - vec2(0.5)) * vec2(aspect, 1.0);

	// Raise the crossbar to give the cross a longer lower stem.
	float stem = box_distance(point, vec2(0.075, 0.30));
	float crossbar = box_distance(point - vec2(0.0, -0.10), vec2(0.21, 0.06));
	float cross_distance = min(stem, crossbar);

	// Grow the silhouette far enough to cover any screen aspect ratio.
	float cover_distance = length(vec2(aspect, 1.0)) * 0.5;
	float edge = mix(-0.075 - edge_softness, cover_distance + edge_softness, progress);
	float alpha = smoothstep(
		edge - edge_softness,
		edge + edge_softness,
		cross_distance
	);

	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}