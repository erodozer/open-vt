// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2023 MizunagiKB <mizukb@live.jp>
// GDCubism shader: Mask + MixInv
shader_type canvas_item;
render_mode blend_premul_alpha, unshaded;

uniform vec4 color_base;
uniform vec4 color_screen;
uniform vec4 color_multiply;
uniform vec4 channel;
uniform sampler2D tex_main : filter_nearest;
uniform sampler2D tex_mask : filter_nearest;

uniform bool auto_scale;
uniform vec2 canvas_size;
uniform vec2 mask_size;
uniform float ratio;
uniform vec2 adjust_pos;
uniform float adjust_scale;


void vertex() {
    UV.y = 1.0 - UV.y;
}

vec2 lookup_mask_uv(vec2 screen_uv) {

    if(auto_scale == false) return screen_uv;

    vec2 r_uv = screen_uv - 0.5;
    vec2 calc_pos;

    calc_pos.x = (canvas_size.x * adjust_scale) - canvas_size.x;
    calc_pos.x = calc_pos.x * (adjust_pos.x / canvas_size.x);
    calc_pos.x = calc_pos.x / canvas_size.x;

    calc_pos.y = (canvas_size.y * adjust_scale) - canvas_size.y;
    calc_pos.y = calc_pos.y * (adjust_pos.y / canvas_size.y);
    calc_pos.y = calc_pos.y / canvas_size.y;

    r_uv = r_uv + calc_pos;
    r_uv = r_uv * (1.0 / adjust_scale);

    return r_uv + 0.5;
}

void fragment() {
    vec4 color_tex = texture(tex_main, UV);
    color_tex.rgb = color_tex.rgb * color_multiply.rgb;

    // premul alpha
    color_tex.rgb = color_tex.rgb + color_screen.rgb - (color_tex.rgb * color_screen.rgb);
    vec4 color_for_mask = color_tex * color_base;
    color_for_mask.rgb = color_for_mask.rgb * color_for_mask.a;

    vec4 clip_mask = texture(tex_mask, lookup_mask_uv(SCREEN_UV)) * channel;

    float mask_val = clip_mask.r + clip_mask.g + clip_mask.b + clip_mask.a;
    color_for_mask = color_for_mask * (1.0 - mask_val);
    COLOR = color_for_mask;
}
