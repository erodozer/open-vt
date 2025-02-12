// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: 2023 MizunagiKB <mizukb@live.jp>
// GDCubism shader: Add
shader_type canvas_item;
render_mode blend_premul_alpha, unshaded;

uniform vec4 color_base;
uniform vec4 color_screen;
uniform vec4 color_multiply;
uniform vec4 channel;
uniform sampler2D tex_main : filter_linear_mipmap;

void vertex() {
    UV.y = 1.0 - UV.y;
}

void fragment() {
    vec4 color_tex = texture(tex_main, UV);
    color_tex.rgb = color_tex.rgb * color_multiply.rgb;

    // premul alpha
    color_tex.rgb = (color_tex.rgb + color_screen.rgb) - (color_tex.rgb * color_screen.rgb);
    vec4 color = color_tex * color_base;
    COLOR = vec4(color.rgb * color.a, 0.0);
}
