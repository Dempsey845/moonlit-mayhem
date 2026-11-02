shader_type sky;

uniform vec4 zenith_color : source_color = vec4(0.012, 0.018, 0.055, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.14, 0.085, 0.22, 1.0);
uniform vec4 ground_color : source_color = vec4(0.018, 0.015, 0.035, 1.0);
uniform vec4 star_color : source_color = vec4(0.79, 0.85, 1.0, 1.0);
uniform float star_brightness : hint_range(0.0, 4.0) = 1.1;
uniform float star_density : hint_range(0.0, 1.0) = 0.22;
uniform float star_scale : hint_range(20.0, 160.0) = 75.0;
uniform float star_size : hint_range(0.015, 0.15) = 0.055;
uniform vec4 moon_color : source_color = vec4(0.83, 0.89, 0.75, 1.0);
uniform vec4 halo_color : source_color = vec4(0.35, 0.44, 0.65, 1.0);
uniform float moon_azimuth : hint_range(-180.0, 180.0) = -35.0;
uniform float moon_elevation : hint_range(5.0, 85.0) = 32.0;
uniform float moon_radius_degrees : hint_range(0.5, 12.0) = 4.0;
uniform float moon_brightness : hint_range(0.0, 4.0) = 1.25;
uniform float halo_strength : hint_range(0.0, 1.0) = 0.22;
uniform float crater_strength : hint_range(0.0, 0.6) = 0.18;

vec3 hash3(vec3 p) {
    return fract(sin(vec3(dot(p, vec3(127.1, 311.7, 74.7)),
        dot(p, vec3(269.5, 183.3, 246.1)),
        dot(p, vec3(113.5, 271.9, 124.6)))) * 43758.5453);
}

float crater(vec2 p, vec2 center, float radius) {
    return 1.0 - smoothstep(radius * 0.78, radius, length(p - center));
}

void sky() {
    vec3 direction = normalize(EYEDIR);
    float altitude = max(direction.y, 0.0);
    vec3 result = mix(horizon_color.rgb, zenith_color.rgb, pow(altitude, 0.45));
    result = mix(ground_color.rgb, result, smoothstep(-0.12, 0.02, direction.y));

    vec3 point = direction * star_scale;
    vec3 cell = floor(point);
    float stars = 0.0;
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            for (int z = -1; z <= 1; z++) {
                vec3 offset = vec3(float(x), float(y), float(z));
                vec3 random = hash3(cell + offset);
                vec3 seed_point = cell + offset + random;
                vec3 star_direction = normalize(seed_point);
                float distance_to_star = length(direction - star_direction) * star_scale;
                float radius = star_size * mix(0.65, 1.6, random.y);
                float visible = step(1.0 - star_density, random.x);
                visible *= 1.0 - step(0.5, abs(length(seed_point) - star_scale));
                stars += (1.0 - smoothstep(radius * 0.3, radius, distance_to_star))
                    * visible * mix(0.4, 1.0, random.z);
            }
        }
    }
    stars *= smoothstep(0.02, 0.22, direction.y);

    float azimuth = radians(moon_azimuth);
    float elevation = radians(moon_elevation);
    vec3 moon_direction = vec3(sin(azimuth) * cos(elevation), sin(elevation), -cos(azimuth) * cos(elevation));
    vec3 moon_right = normalize(cross(moon_direction, vec3(0.0, 1.0, 0.0)));
    vec3 moon_up = cross(moon_right, moon_direction);
    float angular_radius = radians(moon_radius_degrees);
    vec2 moon_uv = vec2(dot(direction, moon_right), dot(direction, moon_up)) / sin(angular_radius);
    float disc_distance = length(moon_uv);
    float front = step(0.0, dot(direction, moon_direction));
    float disc = (1.0 - smoothstep(0.985, 1.015, disc_distance)) * front;
    float angle_from_moon = acos(clamp(dot(direction, moon_direction), -1.0, 1.0));
    float halo = exp(-angle_from_moon / (angular_radius * 2.2));
    result += halo_color.rgb * halo * halo_strength;
    result += star_color.rgb * stars * star_brightness * (1.0 - disc) * (1.0 - halo * 0.7);

    float craters = crater(moon_uv, vec2(-0.31, 0.28), 0.27);
    craters += crater(moon_uv, vec2(0.30, -0.15), 0.34) * 0.8;
    craters += crater(moon_uv, vec2(-0.20, -0.46), 0.16) * 0.7;
    craters += crater(moon_uv, vec2(0.40, 0.46), 0.12) * 0.6;
    float shading = 1.0 - crater_strength * clamp(craters, 0.0, 1.5);
    shading *= mix(0.86, 1.0, clamp(0.5 + moon_uv.y * 0.5, 0.0, 1.0));
    result = mix(result, moon_color.rgb * moon_brightness * shading, disc);
    COLOR = result;
}
