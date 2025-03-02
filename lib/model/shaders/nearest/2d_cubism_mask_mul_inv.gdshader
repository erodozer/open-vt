// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2023 MizunagiKB <mizukb@live.jp>
// GDCubism shader: Mask + MulInv
shader_type canvas_item;
render_mode blend_mul, unshaded;

uniform vec4 color_base;
uniform vec4 color_screen;
uniform vec4 color_multiply;
uniform vec4 channel;
uniform sampler2D tex_main : filter_linear_mipmap;
uniform sampler2D tex_mask : filter_linear_mipmap;

uniform vec2 canvas_size;
uniform vec2 mask_size;

varying vec2 MASK_UV;

void vertex() {
    UV.y = 1.0 - UV.y;
	MASK_UV = VERTEX / canvas_size;
}

void fragment() {
    vec4 color_tex = texture(tex_main, UV);
    color_tex.rgb = color_tex.rgb * color_multiply.rgb;

    // premul alpha
    color_tex.rgb = color_tex.rgb + color_screen.rgb - (color_tex.rgb * color_screen.rgb);
    vec4 color_for_mask = color_tex * color_base;
    color_for_mask.rgb = color_for_mask.rgb * color_for_mask.a;

    vec4 clip_mask = texture(tex_mask, MASK_UV) * channel;

    float mask_val = clip_mask.r + clip_mask.g + clip_mask.b + clip_mask.a;
    color_for_mask = color_for_mask * (1.0 - mask_val);
    COLOR = vec4(
        color_for_mask.r + (1.0 - color_for_mask.a),
        color_for_mask.g + (1.0 - color_for_mask.a),
        color_for_mask.b + (1.0 - color_for_mask.a),
        1.0
    );
}
