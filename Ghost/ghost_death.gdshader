shader_type spatial;
render_mode cull_disabled;

instance uniform float death_progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 body_color : source_color = vec4(0.82, 0.95, 1.0, 1.0);
uniform bool use_albedo_texture = false;
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap;
uniform float normal_strength : hint_range(0.0, 2.0) = 1.0;
uniform vec4 edge_color : source_color = vec4(0.25, 0.8, 1.0, 1.0);
uniform float edge_width : hint_range(0.001, 0.25) = 0.07;
uniform float edge_energy : hint_range(0.0, 10.0) = 3.0;
uniform float noise_scale : hint_range(0.1, 30.0) = 6.0;

varying vec3 local_position;

float hash_3d(vec3 p) {
    return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float value_noise(vec3 p) {
    vec3 cell = floor(p);
    vec3 f = fract(p);
    vec3 u = f * f * (3.0 - 2.0 * f);
    float lower = mix(
        mix(hash_3d(cell), hash_3d(cell + vec3(1.0, 0.0, 0.0)), u.x),
        mix(hash_3d(cell + vec3(0.0, 1.0, 0.0)),
            hash_3d(cell + vec3(1.0, 1.0, 0.0)), u.x), u.y);
    float upper = mix(
        mix(hash_3d(cell + vec3(0.0, 0.0, 1.0)),
            hash_3d(cell + vec3(1.0, 0.0, 1.0)), u.x),
        mix(hash_3d(cell + vec3(0.0, 1.0, 1.0)),
            hash_3d(cell + vec3(1.0, 1.0, 1.0)), u.x), u.y);
    return mix(lower, upper, u.z);
}

void vertex() {
    local_position = VERTEX;
}

void fragment() {
    float progress = clamp(death_progress, 0.0, 1.0);
    vec3 p = local_position * noise_scale;
    float noise_value = value_noise(p) * 0.7
        + value_noise(p * 2.0 + vec3(17.0)) * 0.3;

    if (progress >= 1.0) {
        discard;
    }
    if (progress > 0.0 && noise_value < progress) {
        discard;
    }

    vec3 base_color = body_color.rgb;
    if (use_albedo_texture) {
        base_color *= texture(albedo_texture, UV).rgb;
    }

    float edge = 0.0;
    if (progress > 0.0) {
        edge = 1.0 - smoothstep(progress, progress + edge_width, noise_value);
        edge *= smoothstep(0.0, 0.08, progress);
    }
    ALBEDO = mix(base_color, edge_color.rgb, edge);
    EMISSION = edge_color.rgb * edge * edge_energy;
    ROUGHNESS = 1.0;
    NORMAL_MAP = texture(normal_texture, UV).rgb;
    NORMAL_MAP_DEPTH = normal_strength;
}
