// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2023 MizunagiKB <mizukb@live.jp>
// GDCubism shader: Mask + Add
shader_type canvas_item;
render_mode blend_premul_alpha, unshaded;

uniform vec4 color_base : source_color;
uniform vec4 color_screen : source_color;
uniform vec4 color_multiply : source_color;
uniform vec4 channel : source_color;
uniform sampler2D tex_main : filter_nearest_mipmap;
uniform sampler2D tex_mask : filter_nearest_mipmap;

uniform float mask_scale;
uniform vec2 canvas_size;
uniform vec2 mesh_offset;

varying vec2 MASK_UV;

void vertex() {
    vec2 mask_size = vec2(textureSize(tex_mask, 0)) / mask_scale;
    vec2 mask_vtx = VERTEX - mesh_offset;
    MASK_UV = mask_vtx / mask_size;
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
    color_for_mask.rgb = color_for_mask.rgb * mask_val;
    COLOR = vec4(color_for_mask.rgb, 0.0);
}
